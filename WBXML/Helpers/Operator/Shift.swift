//
//  Shift.swift
//
//  Created by Vadim Zharkov on 20/01/2017.
//  Copyright © 2017 Vadim Zharkov. All rights reserved.
//

import Foundation

infix operator >>> : BitwiseShiftPrecedence

public func >>> (lhs: Int, rhs: Int) -> Int {
    return Int(bitPattern: UInt(bitPattern: lhs) >> UInt(rhs))
}
