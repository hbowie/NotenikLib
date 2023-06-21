//
//  IndexValue.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class IndexValue: StringValue, MultiValues {
    
    var indexList: [String] = []
    
    /// Default initializer
    override init() {
        super.init()
    }
    
    /// Convenience initializer with String value
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    
    /// Set a new value for the tags.
    ///
    /// - Parameter value: The new value for the tags, with commas or semi-colons separating tags,
    ///                    and periods or slashes separating levels within a tag.
    public override func set(_ value: String) {
        self.value = ""
        indexList = []
        append(value)
    }
    
    /// Append another line to the value, ensuring it ends
    /// with a semi-colon followed by a space.
    func append(_ line: String) {
        var pendingSpaces = 0
        var finalSemiColon = false
        var contentCount = 0
        for c in line {
            if c.isWhitespace {
                pendingSpaces += 1
            } else if c == ";" {
                value.append(c)
                pendingSpaces = 1
                finalSemiColon = true
            } else {
                if pendingSpaces > 0 {
                    value.append(" ")
                    pendingSpaces = 0
                }
                finalSemiColon = false
                value.append(c)
                contentCount += 1
            }
        }
        if contentCount > 0 {
            if !finalSemiColon {
                value.append(";")
            }
            value.append(" ")
        }
        parseIndexValue()
    }
    
    func parseIndexValue() {
        indexList = self.value.components(separatedBy: ";")
    }
    
    //
    // The following constants, variables and functions provide conformance to the MultiValues protocol.
    //
    
    public let multiDelimiter = "; "
    
    public var multiCount: Int {
        return indexList.count
    }
    
    /// Return a sub-value at the given index position.
    /// - Returns: The indicated sub-value, for a valid index, otherwise nil.
    public func multiAt(_ index: Int) -> String? {
        guard index >= 0 else { return nil }
        guard index < multiCount else { return nil }
        return StringUtils.trim(indexList[index])
    }
}
