//
//  MarkValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/29/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Indicated whether the associated note has been marked. 
public class MarkValue: StringValue {
    
    public var isMarked: Bool {
        if value.isEmpty { return false }
        let lower = value.lowercased()
        if lower.hasPrefix("y") {
            return true
        } else if lower.hasPrefix("n") {
            return false
        } else if lower.hasPrefix("t") {
            return true
        } else if lower.hasPrefix("f") {
            return false
        } else if lower.hasPrefix("m") {
            return true
        } else if lower == "on" {
            return true
        } else if lower == "1" {
            return true
        } else {
            return false
        }
    }
    
    public func markStr(collection: NoteCollection) -> String {
        if isMarked {
            return collection.marker
        } else {
            return " "
        }
    }
    
    public func markSuffix(collection: NoteCollection) -> String {
        if isMarked && collection.markerCodes.isEmpty {
            return " (\(collection.marker))"
        } else if isMarked {
            return (" \(collection.marker)")
        } else {
            return ""
        }
    }
    
}
