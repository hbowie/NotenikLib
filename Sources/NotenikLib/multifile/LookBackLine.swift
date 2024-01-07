//
//  LookBackLine.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/30/23.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// One line, pointing to one Note, in a list of lookback items. 
class LookBackLine: Comparable {
    
    var noteTitle    = ""
    
    init(noteTitle: String) {
        self.noteTitle = noteTitle
    }
    
    static func < (lhs: LookBackLine, rhs: LookBackLine) -> Bool {
        return lhs.noteTitle < rhs.noteTitle
    }
    
    static func == (lhs: LookBackLine, rhs: LookBackLine) -> Bool {
        return lhs.noteTitle == rhs.noteTitle
    }
}
