//
//  LookBackField.swift
//  NotenikLib
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 1/5/24.
//

import Foundation

class LookBackField {
    
    var commonLabel = ""
    
    var lookBackLines: [LookBackLine] = []
    
    init(commonLabel: String) {
        self.commonLabel = commonLabel 
    }
    
    func registerLookup(lkUpCollectionID: String,
                        lkUpNoteIdCommon: String,
                        lkUpNoteIdText:   String,
                        lkUpFieldLabel:   String) {
        
        let newLine = LookBackLine(noteIdCommon: lkUpNoteIdCommon, noteIdText: lkUpNoteIdText)
        var i = 0
        while i < lookBackLines.count {
            if newLine == lookBackLines[i] {
                return
            }
            if newLine < lookBackLines[i] {
                lookBackLines.insert(newLine, at: i)
                return
            }
            i += 1
        }
        lookBackLines.append(newLine)
    }
    
    func registerLookBacks(lkUpNote: Note) {
        let newLine = LookBackLine(noteIdCommon: lkUpNote.noteID.commonID, noteIdText: lkUpNote.noteID.text)
        var i = 0
        while i < lookBackLines.count {
            if newLine == lookBackLines[i] {
                return
            }
            if newLine < lookBackLines[i] {
                lookBackLines.insert(newLine, at: i)
                return
            }
            i += 1
        }
        lookBackLines.append(newLine)
    }
    
    func cancelLookBacks(lkUpNote: Note) {
        var i = 0
        while i < lookBackLines.count {
            if lkUpNote.noteID.commonID == lookBackLines[i].noteIdCommon {
                lookBackLines.remove(at: i)
            } else {
                i += 1
            }
        }
    }
    
    func getLookBackLines() -> [LookBackLine] {
        return lookBackLines
    }
}
