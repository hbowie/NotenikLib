//
//  WorkTypeValue.swift
//  Notenik
//
//  Created by Herb Bowie on 8/31/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Indicates the type of work produced by a creator. 
public class WorkTypeValue: StringValue {
    
    let types = WorkTypeList.shared
    
    public override func set(_ value: String) {
        let index = types.matchesOriginal(value: value)
        if index == NSNotFound {
            self.value = value
        } else {
            self.value = types.originalTypes[index]
        }
    }
    
    /// Formats a string containing the word "the" followed by the work type
    /// in lowercase.
    /// - Returns: If the work type is blank or "unknown", then the method
    ///   returns an empty string. Otherwise the method returns a string
    ///   starting with " the " and ending with the work type value, in all
    ///   lowercase characters.
    public var theType: String {
        if value.isEmpty {
            return ""
        } else {
            let lowered = value.lowercased()
            if lowered == "unknown" {
                return ""
            } else {
                return (" the \(lowered)")
            }
        }
    }
    
    public var isMajor: Bool {
        switch value.lowercased() {
        case "", "album", "book", "cd", "decision", "film", "major work", "novel", "play", "television show", "unknown", "video", "web page":
            return true
        default:
            return false
        }
    }
    
    public var activity: String {
        switch value.lowercased() {
        case "album", "cd", "song":
            return "listening to"
        case "film", "television show":
            return "watching"
        default:
            return "reading"
        }
    }

}
