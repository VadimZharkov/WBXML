//
//  WBXMLError.swift
//
//  Created by Vadim Zharkov on 16/02/2017.
//  Copyright © 2017 Vadim Zharkov. All rights reserved.
//

import Foundation

public enum WBXMLError: Error {
    case utf8Encoding
    case emptyStream
    case serializerError(String)
    case parserEOF
    case parserEOD
    case parserError(String)
}

extension WBXMLError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .utf8Encoding:
            return "UTF8 encoding failed"
        case .emptyStream:
            return "Stream has no content"
        case let .serializerError(reason):
            return "WBXML format error: \(reason)"
        case .parserEOF:
            return "Parser comes to EOF prematurely"
        case .parserEOD:
            return "Parser comes to end of document prematurely"
        case let .parserError(reason):
            return "WBXML format error: \(reason)"
        }
    }
}

extension WBXMLError: CustomStringConvertible {
    public var description: String {
        return debugDescription
    }
}
