//
//  AKAValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/8/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class AKAValue: StringValue, Collection, Sequence {
    
    public typealias Element = String
    
    public var list: [String]
    
    public override var count: Int {
        return value.count
    }
    
    public override var isEmpty: Bool {
        return value.isEmpty
    }
    
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return list.count
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public subscript(position: Int) -> String {
        return list[position]
    }
    
    public override init() {
        list = []
        super.init()
    }
    
    /// Initialize with a String value
    public convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Set a new value for the object
    override func set(_ value: String) {
        self.value = value
        list = []
        append(value)
        setValueFromList()
    }
    
    public func clear() {
        list = []
        value = ""
    }
    
    /// Examine a line of text, identifying aka values separated by commas.
    public func append(_ line: String) {
        var pendingSpaces = 0
        var nextAKA = ""
        for c in line {
            if c == "," || c == ";" {
                if !nextAKA.isEmpty {
                    add(aka: nextAKA)
                    nextAKA = ""
                }
                pendingSpaces = 0
                continue
            }
            if c.isWhitespace {
                if !nextAKA.isEmpty {
                    pendingSpaces += 1
                }
                continue
            }
            if pendingSpaces > 0 {
                nextAKA.append(" ")
                pendingSpaces = 0
            }
            nextAKA.append(c)
        }
        if !nextAKA.isEmpty {
            add(aka: nextAKA)
        }
    }
    
    /// Add another AKA value to the list.
    /// - Parameter aka: An AKA value.
    public func add(aka: String) {
        list.append(aka)
        setValueFromList()
    }
    
    func setValueFromList() {
        value = ""
        for aka in list {
            if !value.isEmpty {
                value.append(", ")
            }
            value.append(aka)
        }
    }
    
    /// Factory method to return an iterator.
    public func makeIterator() -> AKAIterator {
        return AKAIterator(self)
    }
    
    /// The Iterator.
    public class AKAIterator: IteratorProtocol {

        public typealias Element = String
        
        var akaValue: AKAValue
        
        var index = 0
        
        public init(_ akaValue: AKAValue) {
            self.akaValue = akaValue
        }
        
        public func next() -> String? {
            guard index >= 0 && index < akaValue.list.count else { return nil }
            let nextAKA = akaValue.list[index]
            index += 1
            return nextAKA
        }
    }
    
    /// Display values for debugging purposes. 
    public func display(indentLevels: Int = 0) {
        
        StringUtils.display("\(list.count)",
                            label: "count",
                            blankBefore: true,
                            header: "AKAValue",
                            sepLine: false,
                            indentLevels: indentLevels)
        for akaValue in list {
            StringUtils.display(akaValue,
                                label: "AKA",
                                blankBefore: false,
                                header: nil,
                                sepLine: false,
                                indentLevels: indentLevels + 1)
        }
    }
}
