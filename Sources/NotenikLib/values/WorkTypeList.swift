//
//  WorkTypeList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/2/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class WorkTypeList {
    
    public static let shared = WorkTypeList()
    
    public let originalTypes = ["unknown", "Album", "Article", "Blog Post", "Book", "CD", "Comment", "Conference", "Essay", "Film", "Interview", "Lecture", "Letter", "Novel", "Obituary", "Paper", "Play", "Podcast", "Poem", "Preface", "Presentation", "Remarks", "Sermon", "Song", "Speech", "Story", "Television Show", "Video"]
    
    public var allTypes: [String] = []
    
    public var count: Int {
        return allTypes.count
    }
    
    private init() {
        for originalType in originalTypes {
            allTypes.append(originalType)
            let lowerCaseType = originalType.lowercased()
            if lowerCaseType != originalType {
                allTypes.append(lowerCaseType)
            }
        }
        allTypes.sort()
    }
    
    /// Return the item at the designated index, or nil if the index is out of range.
    public func itemAt(index: Int) -> String? {
        if index >= 0 && index < allTypes.count {
            return allTypes[index]
        } else {
            return nil
        }
    }
    
    /// Return the first item in the sorted, complete list that starts with the supplied prefix. 
    public func startsWith(prefix: String) -> String? {
        var i = 0
        while i < allTypes.count {
            if allTypes[i].hasPrefix(prefix) {
                return allTypes[i]
            } else if allTypes[i] > prefix {
                return nil
            }
            i += 1
        }
        return nil
    }
    
    /// Look for a matching value in the complete list of values. 
    public func matches(value: String) -> Int {
        var i = 0
        while i < allTypes.count {
            if allTypes[i] == value {
                return i
            } else if allTypes[i] > value {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
    
    /// Look for a matching value in the list of original values, ignoring case.
    public func matchesOriginal(value: String) -> Int {
        var i = 0
        let lowerValue = value.lowercased()
        while i < originalTypes.count {
            if lowerValue == originalTypes[i].lowercased() {
                return i
            }
            i += 1
        }
        return NSNotFound
    }
    
}
