//
//  LookBackCollection.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/4/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Lookback/Lookup info for each Collection.
class LookBackCollection {
    
    /// The Collection ID (shortcut or simple folder name) used to identify this Collection.
    var collectionID = ""
    
    /// Has this Collection requested any lookbacks?
    var lookBacksRequested = false
    
    /// Dictionary of lookback field definitions, each identified by the common form
    /// of the corresponding field label doing the lookups.
    var lookBackFieldDefs: [String: LookBackFieldDef] = [:]
    
    var lookBackNotes: [String: LookBackNote] = [ : ]
    
    /// Initialize with the Collection ID.
    init(collectionID: String) {
        self.collectionID = collectionID
    }
    
    /// Indicate that lookbacks have been requested for the lookup fields in this Collection.
    func requestLookbacks() {
        lookBacksRequested = true
    }
    
    /// Record a request for lookbacks.
    /// - Parameters:
    ///   - lkUpFieldLabel:   Common label for the field doing the lookup.
    ///   - lkBkCollectionID: Identifier the the Collection requesting the lookbacks.
    ///   - lkBkFieldLabel:   Common label for the field requesting the lookback.
    func requestLookbacks(lkUpFieldLabel: String,
                          lkBkCollectionID: String,
                          lkBkFieldLabel: String) {
        ensureFieldDef(lkUpFieldLabel: lkUpFieldLabel)
        lookBackFieldDefs[lkUpFieldLabel]!.lkBkCollectionID = lkBkCollectionID
        lookBackFieldDefs[lkUpFieldLabel]!.lkBkFieldLabel = lkBkFieldLabel
    }
    
    func identifyLookBackField(lkUpFieldLabel: String) -> LookBackFieldDef? {
        return lookBackFieldDefs[lkUpFieldLabel]
    }
    
    func registerLookup(lkUpCollectionID: String,
                        lkUpNoteTitle:    String,
                        lkUpFieldLabel:   String,
                        lkBkFieldLabel:   String,
                        lkUpValue:        String) {
        
        ensureNote(lkUpValue: lkUpValue)
        lookBackNotes[lkUpValue]!.registerLookup(lkUpCollectionID: lkUpCollectionID,
                                                 lkUpNoteTitle: lkUpNoteTitle,
                                                 lkUpFieldLabel: lkUpFieldLabel,
                                                 lkBkFieldLabel: lkBkFieldLabel)
    }
    
    func ensureFieldDef(lkUpFieldLabel: String) {
        guard !lookBackFieldDefs.keys.contains(lkUpFieldLabel) else { return }
        lookBackFieldDefs[lkUpFieldLabel] = LookBackFieldDef(lkUpFieldLabel: lkUpFieldLabel)
    }
    
    func registerLookBacks(lkUpNote: Note, lkUpField: NoteField, lkBkDef: LookBackFieldDef) {
        let lkUpTargetNoteID = StringUtils.toCommon(lkUpField.value.value)
        ensureNote(lkUpValue: lkUpTargetNoteID)
        lookBackNotes[lkUpTargetNoteID]!.registerLookBacks(lkUpNote: lkUpNote, lkUpField: lkUpField, lkBkDef: lkBkDef)
    }
    
    func cancelLookBacks(lkUpNote: Note, lkUpField: NoteField, lkBkDef: LookBackFieldDef) {
        let lkUpTargetNoteID = StringUtils.toCommon(lkUpField.value.value)
        ensureNote(lkUpValue: lkUpTargetNoteID)
        lookBackNotes[lkUpTargetNoteID]!.cancelLookBacks(lkUpNote: lkUpNote, lkUpField: lkUpField, lkBkDef: lkBkDef)
    }
    
    func ensureNote(lkUpValue: String) {
        guard !lookBackNotes.keys.contains(lkUpValue) else { return }
        lookBackNotes[lkUpValue] = LookBackNote(noteID: lkUpValue)
    }
    
    func getLookBackLines(noteID: String, lkBkCommonLabel: String) -> [LookBackLine] {
        if lookBackNotes.keys.contains(noteID) {
            return lookBackNotes[noteID]!.getLookBackLines(lkBkCommonLabel: lkBkCommonLabel)
        } else {
            return []
        }
    }
}
