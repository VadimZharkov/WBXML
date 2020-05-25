//
//  DataInputStream.swift
//
//  Created by Vadim Zharkov on 19/01/2017.
//  Copyright © 2017 Vadim Zharkov. All rights reserved.
//

import Foundation

public final class DataInputStream {
    private let data: Data
    private var index: Int = 0

    public var count: Int {
        return data.count
    }

    public var hasBytesAvailable: Bool {
        return index < data.count
    }
    
    public init(data: Data) {
        self.data = data
    }

    /**
     * Reads a single byte from the source byte array and returns it as an
     * integer in the range from 0 to 255. Returns -1 if the end of the source
     * array has been reached.
     *
     * @return the byte read or -1 if the end of this stream has been reached.
     */
    public func read() -> Int {
        guard index < data.count else {
            return -1
        }
        let result = Int(data[index]) & 0xFF
        index += 1
        
        return result
    }
}
