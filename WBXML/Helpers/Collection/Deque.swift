//
//  Deque.swift
//  Shared
//
//  Created by Vadim Zharkov on 16/04/2018.
//  Copyright © 2018 Vadim Zharkov. All rights reserved.
//

import Foundation

public struct Deque<T> {
    private var array: [T?]
    private var head: Int
    private var capacity: Int
    private let originalCapacity: Int
    
    public init(_ capacity: Int = 10) {
        self.capacity = max(capacity, 1)
        self.originalCapacity = self.capacity
        self.array = [T?](repeating: nil, count: capacity)
        self.head = capacity
    }
    
    public var isEmpty: Bool {
        return count == 0
    }
    
    public var count: Int {
        return array.count - head
    }
    
    public mutating func append(_ element: T) {
        array.append(element)
    }
    
    public mutating func appendFirst(_ element: T) {
        if head == 0 {
            capacity *= 2
            let emptySpace = [T?](repeating: nil, count: capacity)
            array.insert(contentsOf: emptySpace, at: 0)
            head = capacity
        }
        
        head -= 1
        array[head] = element
    }
    
    @discardableResult
    public mutating func removeFirst() -> T {
        precondition(count > 0)
        return popFirst()!
    }
    
    @discardableResult
    public mutating func removeLast() -> T {
        precondition(count > 0)
        return popLast()!
    }
    
    @discardableResult
    public mutating func popFirst() -> T? {
        guard head < array.count, let element = array[head] else { return nil }
        
        array[head] = nil
        head += 1
        
        if capacity >= originalCapacity && head >= capacity*2 {
            let amountToRemove = capacity + capacity/2
            array.removeFirst(amountToRemove)
            head -= amountToRemove
            capacity /= 2
        }
        return element
    }
    
    @discardableResult
    public mutating func popLast() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.removeLast()
        }
    }
    
    public func peekFirst() -> T? {
        if isEmpty {
            return nil
        } else {
            return array[head]
        }
    }
    
    public func peekLast() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.last!
        }
    }
}
