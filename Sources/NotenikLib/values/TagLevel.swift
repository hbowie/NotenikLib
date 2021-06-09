//
//  TagLevel.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/9/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class TagLevel: Comparable {

    public var text = ""
    
    var _number = 0
    var _numberStr = "0"
    var _padded = "00000000"
    public var number: Int {
        get {
            return _number
        }
        set {
            _number = newValue
            _numberStr = String(number)
            _padded = StringUtils.truncateOrPad(_numberStr, toLength: 8, keepOnRight: false)
        }
    }
    
    /// Designated initializer.
    public init() {
        
    }
    
    public convenience init(_ text: String) {
        self.init()
        self.set(text)
    }
    
    public func set(_ str: String) {
        var index = str.startIndex
        var char: Character = "0"
        var digits = ""
        while index < str.endIndex {
            char = str[index]
            if char.isWhitespace {
                let textStart = str.index(after: index)
                if digits.count > 0 && textStart < str.endIndex {
                    let leadingNumber = Int(digits)
                    if leadingNumber == nil {
                        break
                    } else {
                        number = leadingNumber!
                        text = String(str[textStart..<str.endIndex])
                        return
                    }
                }
            } else if char.isNumber {
                digits.append(char)
            } else {
                break
            }
            index = str.index(after: index)
        }
        number = 0
        text = str
    }
    
    public var paddedNumber: String {
        return _padded
    }
    
    public var sortKey: String {
        return _padded + text
    }
    
    public var forDisplay: String {
        if _number == 0 {
            return text
        } else {
            return _numberStr + " " + text
        }
    }
    
    public func lowercased() -> String {
        return text.lowercased()
    }
    
    public static func < (lhs: TagLevel, rhs: TagLevel) -> Bool {
        return lhs.sortKey < rhs.sortKey
    }
    
    public static func == (lhs: TagLevel, rhs: TagLevel) -> Bool {
        return lhs.sortKey == rhs.sortKey
    }
}
