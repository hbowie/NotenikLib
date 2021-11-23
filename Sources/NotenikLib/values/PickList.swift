//
//  PickList.swift
//  Notenik
//
//  Created by Herb Bowie on 7/11/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A list of values to choose from.
public class PickList {
    
    public static let pickFromLiteral = "pick-from: "
    
    public var forceLowercase = false
    
    public var values: [StringValue] = []
    
    public var count: Int {
        return values.count
    }
    
    /// Register a new value. Add it if not already present in the list.
    
    /// Initialize with no values.
    public init() {
        
    }
    
    /// Initialize with a list of values separated by commas or semi-colons.
    /// Ignore  leading less than symbol, and treat greater than sign as another delimiter.
    public init(values: String, forceLowercase: Bool = false) {
        self.forceLowercase = forceLowercase
        var i = values.startIndex
        if values.hasPrefix(PickList.pickFromLiteral) {
            i = values.index(i, offsetBy: PickList.pickFromLiteral.count)
        } else if values.hasPrefix("<" + PickList.pickFromLiteral) {
            i = values.index(i, offsetBy: PickList.pickFromLiteral.count + 1)
        }
        var nextValue = ""
        while i < values.endIndex {
            let c = values[i]
            if c == "," || c == ";" || c == ">" {
                if nextValue.count > 0 {
                    registerValue(nextValue)
                    nextValue = ""
                }
            } else if c.isWhitespace {
                if nextValue.count > 0 {
                    nextValue.append(c)
                }
            } else {
                nextValue.append(c)
            }
            i = values.index(after: i)
        }
        if nextValue.count > 0 {
            registerValue(nextValue)
        }
    }
    
    /// Register a new value with an ordinary String. 
    func registerValue(_ value: String) {
        let strVal = StringValue(value)
        _ = registerValue(strVal)
    }
    
    func registerValueFromTop(_ value: StringValue) -> StringValue {
        value.cleanup(forceLowercase: forceLowercase)
        var index = values.count - 1
        while index >= 0 && value < values[index] {
            index -= 1
        }
        if index < 0 {
            values.insert(value, at: 0)
            return value
        } else if value == values[index] {
            return values[index]
        } else {
            let insertionPoint = index + 1
            if insertionPoint >= values.count {
                values.append(value)
            } else {
                values.insert(value, at: insertionPoint)
            }
            return value
        }
    }
    
    /// Register a new value. Add if not already present in the list.
    /// - Parameter value: Return the matching StringValue found or added.
    func registerValue(_ value: StringValue) -> StringValue {
        value.cleanup(forceLowercase: forceLowercase)
        var index = 0
        var bottom = 0
        var top = values.count - 1
        var done = false
        while !done {
            if bottom > top {
                done = true
                index = bottom
            } else if value == values[top] {
                return values[top]
            } else if value == values[bottom] {
                return values[bottom]
            } else if value > values[top] {
                done = true
                index = top + 1
            } else if value < values[bottom] {
                done = true
                index = bottom
            } else if top == bottom || top == (bottom + 1) {
                done = true
                if value > values[bottom] {
                    index = top
                } else {
                    index = bottom
                }
            } else {
                let middle = bottom + ((top - bottom) / 2)
                if value == values[middle] {
                    return values[middle]
                } else if value > values[middle] {
                    bottom = middle + 1
                } else {
                    top = middle - 1
                }
            }
        }
        
        if index >= values.count {
            values.append(value)
        } else if index < 0 {
            values.insert(value, at: 0)
        } else {
            values.insert(value, at: index)
        }
        return value
    }
    
    public var valueString: String {
        var str = "pick-from: "
        var valueIndex = 0
        for value in values {
            if valueIndex > 0 {
                str.append(", ")
            }
            str.append(String(describing: value))
            valueIndex += 1
        }
        return str
    }
    
    public func itemAt(index: Int) -> StringValue? {
        if index < 0 || index >= values.count {
            return nil
        } else {
            return values[index]
        }
    }
    
    public func stringAt(index: Int) -> String? {
        if index < 0 || index >= values.count {
            return nil
        } else {
            return values[index].value
        }
    }
    
    /// Return the first item in the sorted, complete list that starts with the supplied prefix.
    public func startsWith(prefix: String) -> StringValue? {
        var searchPrefix = prefix
        if forceLowercase {
            searchPrefix = prefix.lowercased()
        }
        var i = 0
        while i < values.count {
            if values[i].value.hasPrefix(searchPrefix) {
                return values[i]
            } else if values[i].value > searchPrefix {
                return nil
            }
            i += 1
        }
        return nil
    }
    
    /// Look for a matching value in the list of values.
    public func matches(value: String) -> Int {
        var matchValue = value
        if forceLowercase {
            matchValue = value.lowercased()
        }
        var i = 0
        while i < values.count {
            if values[i].value == matchValue {
                return i
            } else if values[i].value > matchValue {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
}
