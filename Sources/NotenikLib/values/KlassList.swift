//
//  KlassList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/20/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class KlassList {
    
    public static let shared = KlassList()
    
    var list: [String] = []
    
    public var count: Int {
        return list.count
    }
    
    public func itemAt(index: Int) -> String? {
        if index < 0 || index >= list.count {
            return nil
        } else {
            return list[index]
        }
    }
    
    private init() {
        list.append("biblio")
        list.append("cover")
        list.append("def")
        list.append("text")
    }
    
    /// Return the first item in the sorted, complete list that starts with the supplied prefix.
    public func startsWith(prefix: String) -> String? {
        let prefixLower = prefix.lowercased()
        var i = 0
        while i < list.count {
            if list[i].hasPrefix(prefixLower) {
                return list[i]
            } else if list[i] > prefixLower {
                return nil
            }
            i += 1
        }
        return nil
    }
    
    /// Look for a matching value in the list of values.
    public func matches(value: String) -> Int {
        let valueLower = value.lowercased()
        var i = 0
        while i < list.count {
            if list[i] == valueLower {
                return i
            } else if list[i] > valueLower {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
    
}
