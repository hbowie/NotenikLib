//
//  FilePathKey.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/11/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Normalize a file path string so that we can use it as a consistent key.
public class FilePathKey: CustomStringConvertible, Hashable, Equatable {
    
    var key = ""
    
    public var description: String { return key }
    
    public init() {
        
    }
    
    public init(str: String) {
        set(str: str)
    }
    
    public func set(str: String) {
        key = str.replacingOccurrences(of: "%20", with: " ")
        if key.hasPrefix("file:///") {
            key.removeFirst(7)
        }
        if key.hasSuffix("/") {
            key.removeLast()
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    public static func == (lhs: FilePathKey, rhs: FilePathKey) -> Bool {
        return lhs.key == rhs.key
    }
    
}
