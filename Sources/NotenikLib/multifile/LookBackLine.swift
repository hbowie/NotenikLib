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

import NotenikUtils

/// One line, pointing to one Note, in a list of lookback items. 
class LookBackLine: Comparable {
    
    var noteIdCommon    = ""
    var noteIdText      = ""
    
    init(noteIdCommon: String, noteIdText: String) {
        self.noteIdCommon = noteIdCommon
        self.noteIdText = noteIdText
        if self.noteIdText.isEmpty {
            self.noteIdText = self.noteIdCommon
        } else if self.noteIdCommon.isEmpty {
            self.noteIdCommon = StringUtils.toCommon(self.noteIdText)
        }
    }
    
    static func < (lhs: LookBackLine, rhs: LookBackLine) -> Bool {
        return lhs.noteIdCommon < rhs.noteIdCommon
    }
    
    static func == (lhs: LookBackLine, rhs: LookBackLine) -> Bool {
        return lhs.noteIdCommon == rhs.noteIdCommon
    }
}
