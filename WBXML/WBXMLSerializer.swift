//
//  WBXMLSerializer.swift
//
//  Created by Vadim Zharkov on 16/01/2017.
//  Copyright © 2017 Vadim Zharkov. All rights reserved.
//

import Foundation

extension Logging {
    public typealias LogWBXMLSerializer = (WBXMLSerializer) -> Bool
    
    // Log protocol
    public static var WBXMLSerializer: LogWBXMLSerializer =  { _ in
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

open class WBXMLSerializer {
    public static var log: (String) -> Void = { message in print(message) }

    private static let NOT_PENDING = -1

    private var codePage: WBXMLCodePage
    private var output: DataOutputStream
    private var pendingTag = NOT_PENDING
    private var nameStack = Deque<String>()
    private var tagPage = 0

    private var error: Error?
    
    public init(codePage: WBXMLCodePage, output: DataOutputStream, startDocument: Bool) {
        self.codePage = codePage
        self.output = output
        
        guard startDocument else {
            output.write(0)
            return
        }
        self.startDocument()
    }
    
    public convenience init(codePage: WBXMLCodePage, output: DataOutputStream) {
        self.init(codePage: codePage, output: output, startDocument: true)
    }
    
    public convenience init(codePage: WBXMLCodePage, startDocument: Bool = true) {
        self.init(codePage: codePage, output: DataOutputStream(), startDocument: startDocument)
    }
    
    private func trace(_ string: String) {
        guard Logging.WBXMLSerializer(self) else {
            return
        }
        let message = string.split { $0 == "\n" || $0 == "\r\n" }.map(String.init)[0]
        let indent = String(repeating: " ", count: nameStack.count * 2)
        
        WBXMLSerializer.log("\(indent)\(message)")
    }

    public func done() throws {
        if nameStack.count != 0 || pendingTag != WBXMLSerializer.NOT_PENDING {
            error = WBXMLError.serializerError("Done received with unclosed tags")
        }
        guard error == nil else {
            throw error!
        }
    }

    public func build(block: (WBXMLSerializer) -> Void) throws {
        block(self)
        try done()
    }
    
    public func startDocument() {
        output.write(0x03) // version 1.3
        output.write(0x01) // unknown or missing public identifier
        output.write(106)  // UTF-8
        output.write(0)    // 0 length string array
    }

    private func checkPendingTag(degenerated: Bool) {
        guard pendingTag != WBXMLSerializer.NOT_PENDING else {
            return
        }

        let page = pendingTag >> WBXML.PAGE_SHIFT
        let id = pendingTag & WBXML.PAGE_MASK
        
        if page != tagPage {
            tagPage = page
            output.write(WBXML.SWITCH_PAGE)
            output.write(page)
        }

        output.write(degenerated ? id : id | WBXML.WITH_CONTENT)
        
        var name = "unknown"
        
        if !codePage.isValid(page: page) {
            trace("Unrecognized page \(page)")
        }
        else if !codePage.isValidTag(page: page, id: id) {
            trace("Unknown tag \(String(describing: tag)) on page \(page)")
        }
        else {
            name = codePage.nameOfTag(page: page, id: id)
        }
        trace("<" + name + (degenerated ? "/>" : ">"))
        
        if !degenerated {
            nameStack.appendFirst(name)
        }
        
        pendingTag = WBXMLSerializer.NOT_PENDING
    }
 
    @discardableResult
    public func start(_ tag: Int) -> WBXMLSerializer {
        checkPendingTag(degenerated: false)
        pendingTag = tag
        
        return self
    }

    @discardableResult
    public func end() -> WBXMLSerializer {
        if pendingTag >= 0 {
            checkPendingTag(degenerated: true)
        }
        else {
            output.write(WBXML.END);
            
            let tagName = nameStack.removeFirst()
            trace("</" + tagName + ">")
        }
        return self
    }
    
    @discardableResult
    public func tag(_ tag: Int) -> WBXMLSerializer {
        start(tag)
        end()

        return self
    }

    @discardableResult
    public func data(_ tag: Int, _ value: String) -> WBXMLSerializer {
        start(tag)
        text(value)
        end()
        
        return self
    }

    @discardableResult
    public func text(_ text: String) -> WBXMLSerializer {
        checkPendingTag(degenerated: false)
        writeInlineString(text)
        trace(text)
        
        return self
    }

    @discardableResult
    public func opaque(_ data: Data) -> WBXMLSerializer {
        writeOpaqueHeader(length: data.count)
        trace("opaque: \(data.count)")
        output.write(data)

        return self
    }
 
    public func writeStringValue(_ value: String, _ tag: Int) {
        if !value.isEmpty {
            self.data(tag, value)
        }
        else {
            self.tag(tag)
        }
    }
    
    public func writeOpaqueHeader(length: Int) {
        guard length >= 0 else {
            error = WBXMLError.serializerError("Invalid negative opaque data length \(length)")
            return
        }
        if length == 0 {
            return
        }
        checkPendingTag(degenerated: false)
        
        output.write(WBXML.OPAQUE)
        output.writeInteger(length)
    }

    public func writeInlineString(_ value: String) {
        output.write(WBXML.STR_I)
        guard let data = value.data(using: .utf8) else {
            error = WBXMLError.utf8Encoding
            return
        }
        output.write(data)
        output.write(0)
    }
    
    public func toUTF8String() throws -> String {
        guard let result = output.toUTF8String() else {
            throw WBXMLError.utf8Encoding
        }
        return result
    }

    public func toData() -> Data {
        return output.toData()
    }
}

extension DataOutputStream {
    public func write(_ newElement: Int) {
        write(UInt8(newElement))
    }
    
    public func writeInteger(_ value: Int) {
        var i = value
        var buf = Array<UInt8>(repeating: 0, count: 5)
        var idx = 0
        
        repeat {
            buf[idx] = UInt8(i & 0x7f)
            idx += 1
            // Use >>> to shift in 0s so loop terminates
            i = i >>> 7
        } while (i != 0)
        
        while (idx > 1) {
            idx -= 1
            write(buf[idx] | 0x80)
        }
        write(buf[0])
    }
}
