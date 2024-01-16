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
                        lkUpNoteTitle:    String,
                        lkUpFieldLabel:   String) {
        
        let newLine = LookBackLine(noteTitle: lkUpNoteTitle)
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
        let lkUpNoteTitle = lkUpNote.title.value
        let newLine = LookBackLine(noteTitle: lkUpNoteTitle)
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
        let lkUpNoteTitle = lkUpNote.title.value
        var i = 0
        while i < lookBackLines.count {
            if lkUpNoteTitle == lookBackLines[i].noteTitle {
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
