//
//  WBXMLTests.swift
//  WBXMLTests
//
//  Created by Vadim Zharkov on 25.05.2020.
//  Copyright © 2020 Vadim Zharkov. All rights reserved.
//

import XCTest
@testable import WBXML

class WBXMLSerializerTests: XCTestCase {
    let expectedBytes: [UInt8] = [
        0x03, 0x01, 0x6A, 0x00, 0x45, 0x5C, 0x4F, 0x4B, 0x03, 0x30, 0x00, 0x01, 0x52, 0x03, 0x32, 0x00,
        0x01, 0x57, 0x00, 0x11, 0x45, 0x46, 0x03, 0x31, 0x00, 0x01, 0x47, 0x03, 0x33, 0x32, 0x37, 0x36,
        0x38, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01]
    var expectedData: Data!

    override func setUpWithError() throws {
         expectedData = Data(expectedBytes)
    }

    func testDataIsEqual() {
        let s = WBXMLSerializer(codePage: CodePage.shared)
        s.start(CodePage.SYNC_SYNC)
            s.start(CodePage.SYNC_COLLECTIONS)
                s.start(CodePage.SYNC_COLLECTION)
                    s.data(CodePage.SYNC_SYNC_KEY, "0")
                    s.data(CodePage.SYNC_COLLECTION_ID, "2")
                    s.start(CodePage.SYNC_OPTIONS)
                        s.start(CodePage.BASE_BODY_PREFERENCE)
                            s.data(CodePage.BASE_TYPE, "1")
                            s.data(CodePage.BASE_TRUNCATION_SIZE, "32768")
                        s.end()
                    s.end()
                s.end()
            s.end()
        s.end()
        
        try! s.done()
        
        let resultData = s.toData()
        
        XCTAssertEqual(resultData, expectedData)
    }
    
    func testDataIsBuilt() {
        let s = WBXMLSerializer(codePage: CodePage.shared)
        try! s.build { s in
            s.start(CodePage.SYNC_SYNC)
                s.start(CodePage.SYNC_COLLECTIONS)
                    s.start(CodePage.SYNC_COLLECTION)
                        s.data(CodePage.SYNC_SYNC_KEY, "0")
                        s.data(CodePage.SYNC_COLLECTION_ID, "2")
                        s.start(CodePage.SYNC_OPTIONS)
                            s.start(CodePage.BASE_BODY_PREFERENCE)
                                s.data(CodePage.BASE_TYPE, "1")
                                s.data(CodePage.BASE_TRUNCATION_SIZE, "32768")
                            s.end()
                        s.end()
                    s.end()
                s.end()
            s.end()
        }
        let resultData = s.toData()
        
        XCTAssertEqual(resultData, expectedData)
    }
}
