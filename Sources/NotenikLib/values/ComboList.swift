//
//  ComboLists.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/26/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A dynamic list of all values occurring in a given Note field within a given Collection.
public class ComboList {
    
    var lowers: [String] = []
    var values: [String] = []
    
    public var count: Int {
        return values.count
    }
    
    var lastIndex: Int {
        return count - 1
    }
    
    var lastLower: String {
        guard count > 0 else { return "" }
        return lowers[lastIndex]
    }
    
    var lastValue: String {
        guard count > 0 else { return "" }
        return values[lastIndex]
    }
    
    public init() {
        
    }
    
    public func lowerAt(_ i: Int) -> String? {
        guard i >= 0 && i < count else { return nil }
        return lowers[i]
    }
    
    public func valueAt(_ i: Int) -> String? {
        guard i >= 0 && i < count else { return nil }
        return values[i]
    }
    
    /// Register a new value, adding to both lowers and values if not already present,
    /// and keeping everything in sequence according to the lowercase values.
    public func registerValue(_ str: String) {
        
        guard !str.isEmpty else { return }
        
        let strLower = str.lowercased()
        
        if values.isEmpty {
            lowers.append(strLower)
            values.append(str)
            return
        }
        
        if strLower > lastLower {
            lowers.append(strLower)
            values.append(str)
            return
        }
        
        var i = 0
        while i < count {
            if lowers[i] == strLower {
                return
            } else if lowers[i] > strLower {
                lowers.insert(strLower, at: i)
                values.insert(str, at: i)
                return
            }
            i += 1
        }
    }
    
    public func display() {
        print("ComboList.display")
        var i = 0
        while i < count {
            print("  - lower: \(lowerAt(i)!), original: \(valueAt(i)!)")
            i += 1
        }
    }
}
