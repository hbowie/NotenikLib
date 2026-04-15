//
//  ImageLayoutList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/6/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class ImageLayoutList {
    
    public static let shared = ImageLayoutList()
    
    public static let defaultLayout = ImageLayoutEnum.belowTitleFullWidth.rawValue
    
    public var allLayouts: [String] = []
    
    public var count: Int {
        return allLayouts.count
    }
    
    private init() {
        for layout in ImageLayoutEnum.allCases {
            allLayouts.append(layout.rawValue)
        }
        
        allLayouts.sort()
    }
    
    /// Return the item at the designated index, or nil if the index is out of range.
    public func itemAt(index: Int) -> String? {
        if index >= 0 && index < allLayouts.count {
            return allLayouts[index]
        } else {
            return nil
        }
    }
    
    /// Return the first item in the sorted, complete list that starts with the supplied prefix.
    public func startsWith(prefix: String) -> String? {
        var i = 0
        while i < allLayouts.count {
            if allLayouts[i].hasPrefix(prefix) {
                return allLayouts[i]
            } else if allLayouts[i] > prefix {
                return nil
            }
            i += 1
        }
        return nil
    }
    
    /// Look for a matching value in the complete list of values.
    public func matches(value: String) -> Int {
        var i = 0
        while i < allLayouts.count {
            if allLayouts[i] == value {
                return i
            } else if allLayouts[i] > value {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
    
    /// Look for a matching value in the list of original values, ignoring case.
    public func matchesOriginal(value: String) -> String? {
        let lowerValue = value.lowercased()
        for layout in ImageLayoutEnum.allCases {
            if lowerValue == layout.rawValue.lowercased() {
                return layout.rawValue
            }
        }
        return nil
    }
    
}
