//
//  LevelToClassLink.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/8/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class LevelToKlassLink: Comparable {

    var klass: String
    var count = 0
    
    public init(klass: KlassValue) {
        self.klass = klass.value
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Conformance to Equatable and Comparable
    //
    // -----------------------------------------------------------
    
    public static func < (lhs: LevelToKlassLink, rhs: LevelToKlassLink) -> Bool {
        if lhs.count > rhs.count {
            return true
        } else if lhs.count < rhs.count {
            return false
        } else {
            return lhs.klass < rhs.klass
        }
    }
    
    public static func == (lhs: LevelToKlassLink, rhs: LevelToKlassLink) -> Bool {
        return lhs.count == rhs.count && lhs.klass == rhs.klass
    }
    
}
