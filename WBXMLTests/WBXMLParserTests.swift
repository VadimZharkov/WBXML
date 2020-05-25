//
//  WBXMLParserTests.swift
//  WBXMLTests
//
//  Created by Vadim Zharkov on 25.05.2020.
//  Copyright © 2020 Vadim Zharkov. All rights reserved.
//

import XCTest

enum ExpectedData {
    case stringValue(String)
    case intValue(Int)
    case bytesValue(Data)
}

final class TestParser: WBXMLParser {
    private let expectedData: ExpectedData?

    init(data: Data, expectedData: ExpectedData? = nil) throws {
        self.expectedData = expectedData
        
        let codePage = CodePage.shared
        let input = DataInputStream(data: data)
        
        try super.init(codePage: codePage, input: input)
    }
    
    func parse() throws {
        var tag: Int
        
        while true {
            tag = try nextTag(WBXMLParser.START_DOCUMENT)
            if tag == WBXMLParser.END_DOCUMENT { break }
            
            if tag == 0x0B {
                let strVal = try value()
                if let expected = expectedData {
                    if case .stringValue(let expectedStrVal) = expected {
                        XCTAssertEqual(strVal, expectedStrVal)
                    }
                }
            } else if tag == 0x0C {
                let intVal = try valueToInt()
                if let expected = expectedData {
                    if case .intValue(let expectedIntVal) = expected {
                        XCTAssertEqual(intVal, expectedIntVal)
                    }
                }
            } else if tag == 0x0D {
                let bytesVal = try valueToBytes()
                if let expected = expectedData {
                    if case .bytesValue(let expectedBytesVal) = expected {
                        XCTAssertEqual(bytesVal, expectedBytesVal)
                    }
                }
            }
        }
    }
}

class WBXMLParserTests: XCTestCase {
    private func parse(_ wbxml: [UInt8], _ expectedData: ExpectedData? = nil) throws {
        let data = Data(wbxml)
        let parser = try TestParser(data: data, expectedData: expectedData)
        try parser.parse()
    }
    
    func testTagIsUnsupported() {
        // Test parser with unsupported Wbxml tag (EXT_2 = 0xC2)
        let unsupportedWbxmlTag: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x5F, 0xC2, 0x05, 0x11, 0x22, 0x33, 0x44, 0x00, 0x01, 0x01]
        do {
            try parse(unsupportedWbxmlTag)
            XCTFail("Expected EasParserException for unsupported tag 0xC2")
        }
        catch WBXMLError.parserError {
            // expected
        }
        catch {
            XCTFail("Expected EasParserException for unsupported tag 0xC2")
        }
    }
    
    func testCodePageIsUnknown() {
        // Test parser with non existent code page 64 (0x40)
        let unknownCodePage: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x00, 0x40, 0x4A, 0x03, 0x31, 0x00, 0x01, 0x01]
        do {
            try parse(unknownCodePage)
            XCTFail("Expected EasParserException for unknown code page 64")
        }
        catch WBXMLError.parserError {
            // expected
        }
        catch {
            XCTFail("Expected EasParserException for unsupported tag 0xC2")
        }
    }
    
    func testTagIsUnknown() throws {
        // Test parser with valid code page (0x00) but non existent tag (0x3F)
        let unknownTag: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x7F, 0x03, 0x31, 0x00, 0x01, 0x01]
        try parse(unknownTag)
    }
    
    func testTextHasTextData() throws {
        // Expect text has text data "DF"
        let textTagWithTextData: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4B, 0x03, 0x44, 0x46, 0x00, 0x01, 0x01]
        try parse(textTagWithTextData, ExpectedData.stringValue("DF"))
    }
    
    func testTextHasTagWithNoContent() throws {
        // Expect text has tag with no content: <Tag/>
        let textTagNoContent: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x0B, 0x01]
        try parse(textTagNoContent, ExpectedData.stringValue(""))
    }
    
    func testTextHasTagAndEndTagWithNoValue() throws {
        // Expect text has tag and end tag with no value: <Tag></Tag>
        let emptyTextTag: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4B, 0x01, 0x01]
        try parse(emptyTextTag, ExpectedData.stringValue(""))
    }
    
    func testTextHasOpaqueData() throws {
        // Expect text has opaque data {0x11, 0x22, 0x33}
        let textTagWithOpaqueData: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4B, 0xC3, 0x03, 0x11, 0x22, 0x33, 0x01, 0x01]
        do {
            try parse(textTagWithOpaqueData)
            XCTFail("Expected EasParserException for trying to read opaque data as text")
        }
        catch WBXMLError.parserError {
            // expected
        }
        catch {
            XCTFail("Expected EasParserException for trying to read opaque data as text")
        }
    }
    
    func testIntHasInteger() throws {
        // Expect int has text data "1"
        let intTagWithIntData: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4C, 0x03, 0x31, 0x00, 0x01, 0x01]
        try parse(intTagWithIntData, ExpectedData.intValue(1))
    }
    
    func testIntHasTagWithNoContent() throws {
        // Expect int has tag with no content: <Tag/>
        let intTagNoContent: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x0C, 0x01]
        try parse(intTagNoContent, ExpectedData.intValue(0))
    }
    
    func testIntHasTagAndEndTagWithNoValue() throws {
        // Expect int has tag and end tag with no value: <Tag></Tag>
        let emptyIntTag: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4C, 0x01, 0x01]
        try parse(emptyIntTag, ExpectedData.intValue(0))
    }
    
    func testIntHasTextData() throws {
        // Expect int has text data "DF"
        let intTagWithTextData: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4C, 0x03, 0x44, 0x46, 0x00, 0x01, 0x01]
        do {
            try parse(intTagWithTextData)
            XCTFail("Expected EasParserException for nonnumeric char 'D'")
        }
        catch WBXMLError.parserError {
            // expected
        }
        catch {
            XCTFail("Expected EasParserException for nonnumeric char 'D'")
        }
    }
    
    func testOpaqueHasOpaqueData() throws {
        // Expect opaque has opaque data {0x11, 0x22, 0x33}
        let opaqueTagWithOpaqueData: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4D, 0xC3, 0x03, 0x11, 0x22, 0x33, 0x01, 0x01]
        let expected: [UInt8] = [0x11, 0x22, 0x33]
        try parse(opaqueTagWithOpaqueData, ExpectedData.bytesValue(Data(expected)))
    }
    
    func testOpaqueHasTagWithNoContent() throws {
        // Expect opaque has tag with no content: <Tag/>
        let opaqueTagNoContent: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x0D, 0x01]
        try parse(opaqueTagNoContent, ExpectedData.bytesValue(Data()))
    }
    
    func testOpaqueHasTagAndEndTagWithNoValue() throws {
        // Expect opaque has tag and end tag with no value: <Tag></Tag>
        let emptyOpaqueTag: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4D, 0x01, 0x01]
        try parse(emptyOpaqueTag, ExpectedData.bytesValue(Data()))
    }
    
    func testOpaqueHasTextData() throws {
        // Expect opaque has text data "DF"
        let opaqueTagWithTextData: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4D, 0x03, 0x44, 0x46, 0x00, 0x01, 0x01]
        let expected: [UInt8] = [0x44, 0x46]
        try parse(opaqueTagWithTextData, ExpectedData.bytesValue(Data(expected)))
    }
    
    func testMalformedData() {
        let malformedData: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4B, 0x03, 0x11, 0x22, 0x00, 0x00, 0x33, 0x00, 0x01, 0x01]
        do {
            try parse(malformedData)
            XCTFail("Expected EasParserException for improperly escaped text data")
        }
        catch WBXMLError.parserError {
            // expected
        }
        catch {
            XCTFail("Expected EasParserException for improperly escaped text data")
        }
    }
    
    func testRunOnInteger() {
        let runOnIntegerEncoding: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0x4D, 0xC3, 0x81, 0x82, 0x83, 0x84, 0x85, 0x06, 0x11, 0x22, 0x33, 0x01, 0x01]
        do {
            try parse(runOnIntegerEncoding)
            XCTFail("Expected EasParserException for improperly encoded integer")
        }
        catch WBXMLError.parserError {
            // expected
        }
        catch {
            XCTFail("Expected EasParserException for improperly encoded integer")
        }
    }

    func testTagHasAttributes() {
        // Test parser with known tag with attributes
        let tagWithAttributes: [UInt8] = [0x03, 0x01, 0x6A, 0x00, 0x45, 0xDF, 0x06, 0x01, 0x03, 0x31, 0x00, 0x01, 0x01]
        do {
            try parse(tagWithAttributes)
            XCTFail("Expected EasParserException for tag with attributes 0xDF")
        }
        catch WBXMLError.parserError {
            // expected
        }
        catch {
            XCTFail("Expected EasParserException for tag with attributes 0xDF")
        }
    }
}
