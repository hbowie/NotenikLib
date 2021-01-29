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
    
    public var values: [StringValue] = []
    
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
    
    /// Register a new value. Add it if not already present in the list.
    
    /// Initialize with no values.
    public init() {
        
    }
    
    /// Initialize with a list of values separated by commas or semi-colons.
    /// Ignore  leading less than symbol, and treat greater than sign as another delimiter.
    public init(values: String) {
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
    
    public var count: Int {
        return values.count
    }
    
    /// Register a new value with an ordinary String. 
    func registerValue(_ value: String) {
        let strVal = StringValue(value)
        _ = registerValue(strVal)
    }
    
    /// Register a new value. Add if not already present in the list.
    /// - Parameter value: Return the matching StringValue found or added.
    func registerValue(_ value: StringValue) -> StringValue {
        print("PickList.registerValue of \(value.value)")
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
            print("  - appending to end of list")
            values.append(value)
        } else if index < 0 {
            print("  - inserting at start of list")
            values.insert(value, at: 0)
        } else {
            print("  - inserting at position \(index)")
            values.insert(value, at: index)
        }
        return value
    }
}
