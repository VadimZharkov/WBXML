//
//  WBXMLCodePage.swift
//  WBXMLTests
//
//  Created by Vadim Zharkov on 25.05.2020.
//  Copyright © 2020 Vadim Zharkov. All rights reserved.
//

import Foundation

class CodePage: WBXMLCodePage {
    static let shared = CodePage()
    
    // Wbxml page definitions for EAS
    public static let AIRSYNC = 0x00
    public static let CONTACTS = 0x01
    public static let EMAIL = 0x02
    public static let CALENDAR = 0x04
    public static let MOVE = 0x05
    public static let GIE = 0x06
    public static let FOLDER = 0x07
    public static let MREQ = 0x08
    public static let TASK = 0x09
    public static let RECIPIENTS = 0x0A
    public static let VALIDATE = 0x0B
    public static let CONTACTS2 = 0x0C
    public static let PING = 0x0D
    public static let PROVISION = 0x0E
    public static let SEARCH = 0x0F
    public static let GAL = 0x10
    public static let BASE = 0x11
    public static let SETTINGS = 0x12
    public static let DOCS = 0x13
    public static let ITEMS = 0x14
    // 14.0
    public static let COMPOSE = 0x15
    public static let EMAIL2 = 0x16
    // 14.1
    public static let NOTES = 0x17
    public static let RIGHTS = 0x18
    
    // Shift applied to page numbers to generate tag
    public static let PAGE_SHIFT = 6
    public static let PAGE_MASK = 0x3F  // 6 bits
    public static let TAG_BASE = 5
    
    // AirSync code page 0
    public static let SYNC_PAGE = 0 << PAGE_SHIFT
    public static let SYNC_SYNC = SYNC_PAGE + 5
    public static let SYNC_RESPONSES = SYNC_PAGE + 6
    public static let SYNC_ADD = SYNC_PAGE + 7
    public static let SYNC_CHANGE = SYNC_PAGE + 8
    public static let SYNC_DELETE = SYNC_PAGE + 9
    public static let SYNC_FETCH = SYNC_PAGE + 0xA
    public static let SYNC_SYNC_KEY = SYNC_PAGE + 0xB
    public static let SYNC_CLIENT_ID = SYNC_PAGE + 0xC
    public static let SYNC_SERVER_ID = SYNC_PAGE + 0xD
    public static let SYNC_STATUS = SYNC_PAGE + 0xE
    public static let SYNC_COLLECTION = SYNC_PAGE + 0xF
    public static let SYNC_CLASS = SYNC_PAGE + 0x10
    public static let SYNC_VERSION = SYNC_PAGE + 0x11
    public static let SYNC_COLLECTION_ID = SYNC_PAGE + 0x12
    public static let SYNC_GET_CHANGES = SYNC_PAGE + 0x13
    public static let SYNC_MORE_AVAILABLE = SYNC_PAGE + 0x14
    public static let SYNC_WINDOW_SIZE = SYNC_PAGE + 0x15
    public static let SYNC_COMMANDS = SYNC_PAGE + 0x16
    public static let SYNC_OPTIONS = SYNC_PAGE + 0x17
    public static let SYNC_FILTER_TYPE = SYNC_PAGE + 0x18
    public static let SYNC_TRUNCATION = SYNC_PAGE + 0x19
    public static let SYNC_RTF_TRUNCATION = SYNC_PAGE + 0x1A
    public static let SYNC_CONFLICT = SYNC_PAGE + 0x1B
    public static let SYNC_COLLECTIONS = SYNC_PAGE + 0x1C
    public static let SYNC_APPLICATION_DATA = SYNC_PAGE + 0x1D
    public static let SYNC_DELETES_AS_MOVES = SYNC_PAGE + 0x1E
    public static let SYNC_NOTIFY_GUID = SYNC_PAGE + 0x1F
    public static let SYNC_SUPPORTED = SYNC_PAGE + 0x20
    public static let SYNC_SOFT_DELETE = SYNC_PAGE + 0x21
    public static let SYNC_MIME_SUPPORT = SYNC_PAGE + 0x22
    public static let SYNC_MIME_TRUNCATION = SYNC_PAGE + 0x23
    public static let SYNC_WAIT = SYNC_PAGE + 0x24
    public static let SYNC_LIMIT = SYNC_PAGE + 0x25
    public static let SYNC_PARTIAL = SYNC_PAGE + 0x26
    public static let SYNC_CONVERSATION_MODE = SYNC_PAGE + 0x27
    public static let SYNC_MAX_ITEMS = SYNC_PAGE + 0x28
    public static let SYNC_HEARTBEAT_INTERVAL = SYNC_PAGE + 0x29
    
    // AirSyncBase code page 17
    public static let BASE_PAGE = BASE << PAGE_SHIFT
    public static let BASE_BODY_PREFERENCE = BASE_PAGE + 5
    public static let BASE_TYPE = BASE_PAGE + 6
    public static let BASE_TRUNCATION_SIZE = BASE_PAGE + 7
    public static let BASE_ALL_OR_NONE = BASE_PAGE + 8
    // There is no tag for 0x09 in spec v14.0
    public static let BASE_BODY = BASE_PAGE + 0xA
    public static let BASE_DATA = BASE_PAGE + 0xB
    public static let BASE_ESTIMATED_DATA_SIZE = BASE_PAGE + 0xC
    public static let BASE_TRUNCATED = BASE_PAGE + 0xD
    public static let BASE_ATTACHMENTS = BASE_PAGE + 0xE
    public static let BASE_ATTACHMENT = BASE_PAGE + 0xF
    public static let BASE_DISPLAY_NAME = BASE_PAGE + 0x10
    public static let BASE_FILE_REFERENCE = BASE_PAGE + 0x11
    public static let BASE_METHOD = BASE_PAGE + 0x12
    public static let BASE_CONTENT_ID = BASE_PAGE + 0x13
    public static let BASE_CONTENT_LOCATION = BASE_PAGE + 0x14
    public static let BASE_IS_INLINE = BASE_PAGE + 0x15
    public static let BASE_NATIVE_BODY_TYPE = BASE_PAGE + 0x16
    public static let BASE_CONTENT_TYPE = BASE_PAGE + 0x17
    public static let BASE_PREVIEW = BASE_PAGE + 0x18
    public static let BASE_BODY_PART_PREFERENCE = BASE_PAGE + 0x19
    public static let BASE_BODY_PART = BASE_PAGE + 0x1A
    public static let BASE_STATUS = BASE_PAGE + 0x1B
    
    func isValid(page: Int) -> Bool {
        return page >= 0 && page < 24
    }
    
    func isValidTag(page: Int, id: Int) -> Bool {
        return true
    }
    
    func nameOfTag(page: Int, id: Int) -> String {
        return "Test"
    }
}
