//
//  WBXMLParser.swift
//
//  Created by Vadim Zharkov on 16/01/2017.
//  Copyright © 2017 Vadim Zharkov. All rights reserved.
//
import Foundation

extension Logging {
    public typealias LogWBXMLParser = (WBXMLParser) -> Bool
    
    // Log protocol
    public static var WBXMLParser: LogWBXMLParser =  { _ in
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    public static var WBXMLParserVerbose: LogWBXMLParser =  { _ in
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

open class WBXMLParser {
    static public var log: (String) -> Void = { message in print(message) }
    
    static public let START_DOCUMENT = 0
    static public let END_DOCUMENT = 1

    static public let DONE = 1
    static public let START = 2
    static public let END = 3
    static public let TEXT = 4
    static public let OPAQUE = 5
    static public let NOT_ENDED = Int.min
    static public let EOF_BYTE = -1
    
    struct Element: CustomStringConvertible, CustomDebugStringConvertible {
        let tag: Int
        let name: String
        let noContent: Bool
        
        init(codePage: WBXMLCodePage, page: Int, token: Int) {
            let id = token & WBXML.PAGE_MASK
            let isGlobal = codePage.isGlobalTag(id: id)
            
            self.tag = isGlobal ? id : (page << WBXML.PAGE_SHIFT) | id
            
            if isGlobal {
                self.name = "unsupported-WBXML"
            }
            else if codePage.isValidTag(page: page, id: id) {
                self.name = codePage.nameOfTag(page: page, id: id)
            }
            else {
                self.name = "unknown"
            }
            // If the high bit is set, there is content (a value) to be read
            self.noContent = (token & WBXML.WITH_CONTENT) == 0
        }
        
        var description: String {
            return name
        }
        
        var debugDescription: String {
            return name
        }
    }

    // The current tag. The low order 6 bits contain the tag index and the
    // higher order bits the page number.
    public private(set) var tag = 0
    public let codePage: WBXMLCodePage
    
    private let input: DataInputStream

    // The stack of tags being processed
    private var startArray = Deque<Element>()
    private var start: Element?
    // The type of the last token read (eg, TEXT, OPAQUE, END, etc).
    private var type = 0
    // The current page. As of EAS 14.1, this is a value 0-24.
    private var page = 0
    // Whether the current tag is associated with content (a value)
    private var noContent = false
    // The value read, as a String
    private var text: String?
    // The value read, as bytes
    private var bytes: Data?

    public init(codePage: WBXMLCodePage, input: DataInputStream, initialize: Bool = true) throws {
        self.codePage = codePage
        self.input = input
        
        if initialize {
            // If we fail on the very first byte, report an empty stream
            do { try readByte() } // version
            catch {
                throw WBXMLError.emptyStream
            }
            try readInt()  // public identifier
            try readInt()  // 106 (UTF-8)
            guard try readInt() == 0 else { // string table length
                throw WBXMLError.parserError("WBXML string table unsupported")
            }
        }
    }

    public convenience init(codePage: WBXMLCodePage, data: Data) throws {
        try self.init(codePage: codePage, input: DataInputStream(data: data))
    }
  
    public convenience init(codePage: WBXMLCodePage, parser: WBXMLParser) throws {
        try self.init(codePage: codePage, input: parser.input, initialize: false)
    }

    /**
     * Return the value of the current tag, as a byte array.
     */
    public func valueToBytes() throws -> Data {
        precondition(start != nil)

        try next()
 
        // This means there was no value given, just <Foo/>; we'll return empty array
        guard type != WBXMLParser.END else {
            trace("No value for tag: \(start!.name)")
            return Data()
        }
        guard type == WBXMLParser.OPAQUE || type == WBXMLParser.TEXT else {
            throw WBXMLError.parserError("Expected OPAQUE or TEXT data for tag \(start!.name)")
        }
        
        let data: Data? = type == WBXMLParser.OPAQUE ? bytes : text?.data(using: .utf8)
        guard let value = data else {
            throw WBXMLError.parserError("Can't get bytes for tag \(start!.name)")
        }
       
        // Read the next token; it had better be the end of the current tag
        try next()

        // If not, throw an exception
        guard type == WBXMLParser.END else {
            throw WBXMLError.parserError("No END found for tag \(start!.name)")
        }
        
        return value
    }

    /**
     * Return the value of the current tag, as a String.
     */
    public func value() throws -> String {
        precondition(start != nil)

        try next()
 
        // This means there was no value given, just <Foo/>; we'll return empty string for now
        guard type != WBXMLParser.END else {
            trace("No value for tag: \(start!.name)")
            return ""
        }
        guard type == WBXMLParser.TEXT else {
            throw WBXMLError.parserError("Expected TEXT data for tag \(start!.name)")
        }

        guard let value = text else {
            throw WBXMLError.parserError("Can't get text for tag \(start!.name)")
        }
        
        // Read the next token; it had better be the end of the current tag
        try next()
        
        // If not, throw an exception
        guard type == WBXMLParser.END else {
            throw WBXMLError.parserError("No END found for tag \(start!.name)")
        }
        
        return value
    }

    /**
     * Return the value of the current tag, as an integer.
     */
    public func valueToInt() throws -> Int {
        let string = try value()
        if string.count == 0 {
            return 0
        }
        guard let value = Int(string) else {
            throw WBXMLError.parserError("Tag \(start!): Invalid number")
        }
        return value
    }

    /**
     * Return the next tag found in the stream; special tags END and END_DOCUMENT are used to
     * mark the end of the current tag and end of document.  If we hit end of document without
     * looking for it, generate an EodException.  The tag returned consists of the page number
     * shifted PAGE_SHIFT bits OR'd with the tag retrieved from the stream.  Thus, all tags returned
     * are unique.
     */
    public func nextTag(_ endingTag: Int) throws -> Int {
        while try next() != WBXMLParser.DONE {
            precondition(start != nil)

            // If we're a start, set tag to include the page and return it
            if type == WBXMLParser.START {
                tag = start!.tag
                return tag
            // If we're at the ending tag we're looking for, return the END signal
            }
            else if type == WBXMLParser.END && start!.tag == endingTag {
                return WBXMLParser.END
            }
        }
        // We're at end of document here.  If we're looking for it, return END_DOCUMENT
        if endingTag == WBXMLParser.START_DOCUMENT {
            return WBXMLParser.END_DOCUMENT
        }
        // Otherwise, we've prematurely hit end of document, so exception out
        throw WBXMLError.parserEOD
    }

    /**
     * Skip anything found in the stream until the end of the current tag is reached.  This can be
     * used to ignore stretches of xml that aren't needed by the parser.
     */
    public func skipTag() throws {
        precondition(start != nil)

        let thisTag = start!.tag
        // Just loop until we hit the end of the current tag
        while try next() != WBXMLParser.DONE {
            if type == WBXMLParser.END && start!.tag == thisTag {
                return
            }
        }
        // If we're at end of document, that's bad
        throw WBXMLError.parserEOF
    }

    private func trace(_ string: String) {
        guard Logging.WBXMLParser(self) else {
            return
        }
        let message = string.split { $0 == "\n" || $0 == "\r\n" }.map(String.init)[0]
        let indent = String(repeating: " ", count: startArray.count * 2)
        
        WBXMLParser.log("\(indent)\(message)")
    }

    private func trace(verbose: String) {
        guard Logging.WBXMLParserVerbose(self) else {
            return
        }
        trace(verbose)
    }
    
    private func pop() {
        // Retrieve the now-current startTag from our stack
        start = startArray.removeFirst()
        
        trace("</\(start!)>")
    }

    private func push(_ token: Int) {
        start =  Element(codePage: codePage, page: page, token: token)
        noContent = start!.noContent
        
       trace("<\(start!)\(noContent ? "/" : "")>")
        
        // Save the startTag to our stack
        startArray.appendFirst(start!)
    }

    /**
     * Return the next piece of data from the stream.  The return value indicates the type of data
     * that has been retrieved - START (start of tag), END (end of tag), DONE (end of stream), or
     * TEXT (the value of a tag)
     */
    @discardableResult
    private func next() throws -> Int {
        bytes = nil; text = nil

        if noContent {
            startArray.removeFirst()
            type = WBXMLParser.END
            noContent = false
            
            return type
        }

        var token = read()
        
        while token == WBXML.SWITCH_PAGE {
            // Get the new page number
            page = try readByte()
            // Retrieve the current tag table
            guard codePage.isValid(page: page) else {
                // Unknown code page. These seem to happen mostly because of
                // invalid data from the server so throw an exception here.
                throw WBXMLError.parserError("Unknown code page \(page)")
            }
            trace(verbose: "Page: \(page)")
            token = read()
        }

        switch token {
            case WBXMLParser.EOF_BYTE:
                // End of document
                type = WBXMLParser.DONE
            case WBXML.END:
                type = WBXMLParser.END
                pop()
            case WBXML.STR_I:
                // Inline string
                type = WBXMLParser.TEXT
                text = try readInlineString()
                trace("\(start!) : \(text!)")
            case WBXML.OPAQUE:
                // Integer length + opaque data
                type = WBXMLParser.OPAQUE
                let length = try readInt()
                bytes = Data()
                for _ in (0..<length) {
                    bytes!.append(UInt8(try readByte()))
                }
                trace("\(start!) : (opaque: \(length))")
            default:
                guard !codePage.isGlobalTag(id: token & WBXML.PAGE_MASK) else {
                    throw WBXMLError.parserError("Unhandled WBXML global token \(token)")
                }
                guard (token & WBXML.WITH_ATTRIBUTES) == 0 else {
                    throw WBXMLError.parserError("Attributes unsupported, token \(token)")
                }
                type = WBXMLParser.START
                push(token)
        }
        // Return the type of data we're dealing with
        return type
    }

    /**
     * Read an int from the input stream, and capture it if necessary for debugging.  Seems a small
     * price to pay...
     */
    @discardableResult
    private func read() -> Int {
        let i = input.read()
        trace(verbose: "Byte: \(String(format: "%02hhx", i))")
        return i
    }
    
    @discardableResult
    private func readByte() throws -> Int {
        let i = read()
        if i == WBXMLParser.EOF_BYTE {
            throw WBXMLError.parserEOF
        }
        return i
    }

    /**
     * Throws WBXMLError.parserError if detects integer encoded with more than 5
     * bytes. A uint_32 needs 5 bytes to fully encode 32 bits so if the high
     * bit is set for more than 4 bytes, something is wrong with the data
     * stream.
     */
    @discardableResult
    private func readInt() throws -> Int {
        var result = 0
        var i: Int
        var numBytes = 0

        repeat {
            numBytes += 1
            if numBytes > 5 {
                throw WBXMLError.parserError("Integer encoding, too many bytes")
            }
            i = try readByte()
            result = (result << 7) | (i & 0x7f)
        } while (i & 0x80) != 0

        return result
    }

    /**
     * Read an inline string from the stream
     */
    private func readInlineString() throws -> String {
        let outputStream = DataOutputStream(capacity: 256)
        while true {
            let i = read()
            if i == 0 {
                break
            }
            else if i == WBXMLParser.EOF_BYTE {
                throw WBXMLError.parserEOF
            }
            outputStream.write(i)
        }
        guard let result = outputStream.toUTF8String() else {
            throw WBXMLError.utf8Encoding
        }

        return result
    }
}
