//
//  LookBackNote.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/2/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// This object contains all the look back references for a Note. 
class LookBackNote {
    
    var noteID = ""
    
    var fields: [String: LookBackField] = [:]
    
    init(noteID: String) {
        self.noteID = noteID
    }
    
    func registerLookup(lkUpCollectionID: String,
                        lkUpNoteTitle:    String,
                        lkUpFieldLabel:   String,
                        lkBkFieldLabel:   String) {
        
        ensureField(lkBkFieldLabel: lkBkFieldLabel)
        fields[lkBkFieldLabel]!.registerLookup(lkUpCollectionID: lkUpCollectionID,
                                               lkUpNoteTitle: lkUpNoteTitle,
                                               lkUpFieldLabel: lkUpFieldLabel)
        
    }
    
    func registerLookBacks(lkUpNote: Note, lkUpField: NoteField, lkBkDef: LookBackFieldDef) {
        ensureField(lkBkFieldLabel: lkBkDef.lkBkFieldLabel)
        fields[lkBkDef.lkBkFieldLabel]!.registerLookBacks(lkUpNote: lkUpNote)
    }
    
    func cancelLookBacks(lkUpNote: Note, lkUpField: NoteField, lkBkDef: LookBackFieldDef) {
        ensureField(lkBkFieldLabel: lkBkDef.lkBkFieldLabel)
        fields[lkBkDef.lkBkFieldLabel]!.cancelLookBacks(lkUpNote: lkUpNote)
    }
    
    func ensureField(lkBkFieldLabel: String) {
        guard !fields.keys.contains(lkBkFieldLabel) else { return }
        fields[lkBkFieldLabel] = LookBackField(commonLabel: lkBkFieldLabel)
    }
    
    func getLookBackLines(lkBkCommonLabel: String) -> [LookBackLine] {
        if fields.keys.contains(lkBkCommonLabel) {
            return fields[lkBkCommonLabel]!.getLookBackLines()
        } else {
            return []
        }
    }
}
