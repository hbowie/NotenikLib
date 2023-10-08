//
//  PhoneValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/21/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Holds one phone number.
public class PhoneValue: StringValue {
    
    var telValue = ""
    
    /// Clear out the contents of the value, leaving it blank.
    public override func clear() {
        self.value = ""
        telValue = ""
    }
    
    /// Set a new value for the object
    public override func set(_ value: String) {
        self.value = ""
        telValue = ""
        var calcTelValue = ""
        var parsingStage: ParsingStage = .display
        for c in value {
            switch parsingStage {
            case .display:
                if c == "[" {
                    break
                } else if c == "]" {
                    parsingStage = .transition
                } else {
                    self.value.append(c)
                    if c == "+" || c == "," || c.isNumber {
                        calcTelValue.append(c)
                    }
                }
            case .transition:
                if c == "(" {
                    parsingStage = .link
                }
            case .link:
                if c == "+" || c == "," || c.isNumber {
                    telValue.append(c)
                }
            }
        }
        if telValue.isEmpty {
            telValue = calcTelValue
        }
    }
    
    public override func valueToWrite(mods: String = " ") -> String {
        guard !value.isEmpty else { return "" }
        guard !telValue.isEmpty else { return value }
        return "[\(value)](tel:\(telValue))"
    }
    
    /// Return the phone value as an optional URL
    var url: URL? {
        guard !value.isEmpty else { return nil }
        guard !telValue.isEmpty else { return nil }
        return URL(string: "tel:\(telValue)")
    }
    
    enum ParsingStage {
        case display
        case transition
        case link
    }
}
