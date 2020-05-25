//
//  OutputStream.swift
//
//  Created by Vadim Zharkov on 19/01/2017.
//  Copyright © 2017 Vadim Zharkov. All rights reserved.
//

import Foundation

public final class DataOutputStream {
    private var data: Data
    
    public init(_ data: Data = Data()) {
        self.data = data
    }
    
    public convenience init(capacity: Int) {
        self.init(Data(capacity: capacity))
    }
    
    public func write(_ newElement: UInt8) {
        data.append(newElement)
    }
    
    public func write(_ other: Data) {
        data.append(other)
    }
    
    public func toUTF8String() -> String? {
        return String(data: data, encoding: .utf8)
    }
    
    public func toData() -> Data {
        return data
    }
}
