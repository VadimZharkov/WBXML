//
//  WBXMLCodePage.swift
//
//  Created by Vadim Zharkov on 10/01/2018.
//  Copyright © 2018 Vadim Zharkov. All rights reserved.
//

import Foundation

public protocol WBXMLCodePage {
    func isGlobalTag(id: Int) -> Bool
    func isValid(page: Int) -> Bool
    func isValid(tag: Int) -> Bool
    func isValidTag(page: Int, id: Int) -> Bool
    func nameOf(tag: Int) -> String
    func nameOfTag(page: Int, id: Int) -> String
}

public extension WBXMLCodePage {
    func isGlobalTag(id: Int) -> Bool {
        return id >= 0 && id < WBXML.TAG_BASE
    }
    
    func isValid(tag: Int) -> Bool {
        let page = tag >> WBXML.PAGE_SHIFT
        let id = tag & WBXML.PAGE_MASK
        
        return isValidTag(page: page, id: id)
    }
    
    func nameOf(tag: Int) -> String {
        let page = tag >> WBXML.PAGE_SHIFT
        let id = tag & WBXML.PAGE_MASK
        
        return nameOfTag(page: page, id: id)
    }
}
