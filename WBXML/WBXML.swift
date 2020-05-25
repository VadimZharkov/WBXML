//
//  Wbxml.swift
//
//  Created by Vadim Zharkov on 16/01/2017.
//  Copyright © 2017 Vadim Zharkov. All rights reserved.
//
import Foundation

/** WBXML constants  */
public enum WBXML {
    public static let SWITCH_PAGE = 0
    public static let END = 1
    public static let ENTITY = 2
    public static let STR_I = 3
    public static let LITERAL = 4
    public static let EXT_I_0 = 0x40
    public static let EXT_I_1 = 0x41
    public static let EXT_I_2 = 0x42
    public static let PI = 0x43
    public static let LITERAL_C = 0x44
    public static let EXT_T_0 = 0x80
    public static let EXT_T_1 = 0x81
    public static let EXT_T_2 = 0x82
    public static let STR_T = 0x83
    public static let LITERAL_A = 0x084
    public static let EXT_0 = 0x0c0
    public static let EXT_1 = 0x0c1
    public static let EXT_2 = 0x0c2
    public static let OPAQUE = 0x0c3
    public static let LITERAL_AC = 0x0c4

    public static let WITH_ATTRIBUTES = 0x80
    public static let WITH_CONTENT = 0x40
    
    public static let PAGE_SHIFT = 6
    public static let PAGE_MASK = 0x3F  // 6 bits
    public static let TAG_BASE = 5
}
