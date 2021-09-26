//
//  Collection.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/23/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class Collection: Identifiable, Comparable, Equatable {
    
    public var path: String
    
    public var ID: String {
        return path
    }
    
    public var key: String {
        return path
    }
    
    public init(path: String) {
        self.path = path
    }
    
    public var shortcut = ""
    
    public static func == (lhs: Collection, rhs: Collection) -> Bool {
        return lhs.key == rhs.key
    }
    
    public static func < (lhs: Collection, rhs: Collection) -> Bool {
        return lhs.key < rhs.key
    }
    
    
}
