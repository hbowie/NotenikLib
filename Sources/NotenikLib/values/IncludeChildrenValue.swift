//
//  IncludeChildrenValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/10/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class IncludeChildrenValue: StringValue {
    
    let values = IncludeChildrenList.shared.values
    
    public override init() {
        super.init()
    }
    
    public func reset() {
        set("")
    }
    
    public override func set(_ value: String) {
        let valueToMatch = value.prefix(2).lowercased()
        if valueToMatch.isEmpty || valueToMatch == IncludeChildrenList.no {
            self.value = ""
            return
        }
        for listValue in values {
            if valueToMatch == listValue.prefix(2).lowercased() {
                self.value = listValue
                return
            }
        }
        self.value = ""
    }
    
    public var on: Bool {
        return value != IncludeChildrenList.no && !value.isEmpty
    }
    
    public var char1: Character {
        guard !value.isEmpty else { return " " }
        return StringUtils.charAt(index: 0, str: value)
    }
    
    public var char2: Character {
        guard value.count > 1 else { return " " }
        return StringUtils.charAt(index: 1, str: value)
    }
    
    public var headingLevel: Int {
        guard asHeading else { return 0 }
        let level = Int(String(char2))
        if level == nil {
            return 0
        } else {
            return level!
        }
    }
    
    public var asQuotes: Bool {
        return value == IncludeChildrenList.quotes
    }
    
    public var asDetails: Bool {
        return value == IncludeChildrenList.details
    }
    
    public var asHeading: Bool {
        return char1 == "h"
    }
    
    public var asList: Bool {
        return char2 == "l"
    }
    
    public func copy() -> IncludeChildrenValue {
        let copy = IncludeChildrenValue(value)
        return copy
    }
    
}
