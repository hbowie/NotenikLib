//
//  CollectionSync.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/19/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation
import NotenikUtils

/// Synchronize the data between two Collections.
public class CollectionSync {
    
    var leftIO:          NotenikIO = FileIO()
    var leftCollection:  NoteCollection? = NoteCollection()
    var leftDict =       FieldDictionary()
    var leftDefs:        [FieldDefinition] = []
    
    var rightIO:         NotenikIO = FileIO()
    var rightCollection: NoteCollection? = NoteCollection()
    var rightDict =      FieldDictionary()
    var rightDefs:       [FieldDefinition] = []
    
    var direction: SyncDirection = .leftToRight
    
    var respectBlanks: Bool = false
    
    var syncActions: SyncActions = .logOnly
    
    var syncTotals: SyncTotals = SyncTotals()
    
    
    var processedIDs: [String : String] = [:]

    
    public init() {
        
    }
    
    public func sync(leftURL: URL,
                     rightURL: URL,
                     syncTotals: SyncTotals,
                     direction: SyncDirection,
                     syncActions: SyncActions = .logOnly,
                     respectBlanks: Bool = true) -> Bool {
        
        logInfo("Starting Collection Sync")
        self.syncTotals = syncTotals
        self.direction = direction
        self.respectBlanks = respectBlanks
        self.syncActions = syncActions
        
        // self.syncActions = .debugging
        
        // Prepare the first Collection
        leftIO = FileIO()
        let realm = leftIO.getDefaultRealm()
        realm.path = ""
        let readOnly = !self.syncActions.performUpdates
        leftCollection = leftIO.openCollection(realm: realm,
                                               collectionPath: leftURL.path,
                                               readOnly: readOnly,
                                               multiRequests: nil)
        if leftCollection == nil {
            logError("Problems opening the collection at " + leftURL.path)
            return false
        }
        leftDict = leftCollection!.dict
        
        // Prepare the second Collection
        rightIO = FileIO()
        rightCollection = rightIO.openCollection(realm: realm,
                                           collectionPath: rightURL.path,
                                           readOnly: readOnly,
                                           multiRequests: nil)
        if rightCollection == nil {
            logError("Problems opening the collection at " + rightURL.path)
            return false
        }
        rightDict = rightCollection!.dict
        
        logInfo("  - Left Collection opened from:  \(leftURL.path)")
        logInfo("  - Right Collection opened from: \(rightURL.path)")
        logInfo("  - Sync Direction: \(direction)")
        logInfo("  - Honor Blanks? \(respectBlanks)")
        logInfo("  - Sync Actions: \(syncActions)")
        
        // Get lists of matching fields
        leftDefs = []
        rightDefs = []
        var i = 0
        logInfo("Matching Field Definitions:")
        while i < leftDict.count {
            if let leftDef = leftDict[i] {
                if let rightDef = rightDict.getDef(leftDef.fieldLabel.commonForm) {
                    leftDefs.append(leftDef)
                    rightDefs.append(rightDef)
                    logInfo("  - \(leftDef.fieldLabel.commonForm)")
                }
            }
            i += 1
        }
        
        // Go through notes on the left.
        
        if self.syncActions.debugging {
            logInfo("Starting pass through left-hand notes")
        }
        processedIDs = [:]
        var (leftSortedNote, leftPosition) = leftIO.firstNote()
        while leftSortedNote != nil {
            let (nextSortedNote, nextPosition) = leftIO.nextNote(leftPosition)
            let leftID = leftSortedNote!.note.noteID.commonID
            if syncActions.debugging {
                logInfo("  - Considering note with id of \(leftID)")
            }
            processedIDs[leftID] = leftID
            var matched = false
            var rightNote: Note?
            if let rn = rightIO.getNote(forID: leftID) {
                rightNote = rn
                matched = true
                if syncActions.debugging {
                    logInfo("    - Found right-hand match")
                }
            }
            if matched {
                compareNotes(leftNote: leftSortedNote!.note, rightNote: rightNote!)
            } else {
                if syncActions.debugging {
                    logInfo("    - No right-hand match found")
                }
                if direction.syncRight {
                    syncTotals.rightAdds += 1
                    addMissingNote(noteToAdd: leftSortedNote!.note, ioForAdd: rightIO)
                } else if direction == .rightToLeft {
                    syncTotals.leftDels += 1
                    deleteUnmatchedNote(noteToDelete: leftSortedNote!.note, ioForDelete: leftIO)
                }
            }
            leftSortedNote = nextSortedNote
            leftPosition = nextPosition
        }
        
        // Now go through notes on the right.
        if syncActions.debugging {
            logInfo("Starting pass through right-hand notes")
        }
        var (rightSortedNote, rightPosition) = rightIO.firstNote()
        while rightSortedNote != nil {
            let (nextSortedNote, nextPosition) = rightIO.nextNote(rightPosition)
            if syncActions.debugging {
                logInfo("  - Considering right-hand note with id of \(rightSortedNote!.note.noteID.commonID)")
            }
            let rightID = rightSortedNote!.note.noteID.commonID
            let leftID = processedIDs[rightID]
            if leftID == nil {
                if syncActions.debugging {
                    logInfo("    - No left-hand match found")
                }
                if direction.syncLeft {
                    syncTotals.leftAdds += 1
                    addMissingNote(noteToAdd: rightSortedNote!.note, ioForAdd: leftIO)
                } else if direction == .leftToRight {
                    syncTotals.rightDels += 1
                    deleteUnmatchedNote(noteToDelete: rightSortedNote!.note, ioForDelete: rightIO)
                }
            }
            
            rightSortedNote = nextSortedNote
            rightPosition = nextPosition
        }
        
        logInfo("Sync completed")
        logInfo("Notes added to left:      \(syncTotals.leftAdds)")
        logInfo("Notes modified on left:   \(syncTotals.leftMods)")
        logInfo("Notes deleted from left:  \(syncTotals.leftDels)")
        logInfo("Notes added to right:     \(syncTotals.rightAdds)")
        logInfo("Notes modified on right:  \(syncTotals.rightMods)")
        logInfo("Notes deleted from right: \(syncTotals.rightDels)")
        
        return true
    }
    
    /// Add a note that is missing from one collection.
    func addMissingNote(noteToAdd: Note, ioForAdd: NotenikIO) {
        
        if syncActions.reportDetails {
            logInfo("Adding to collection titled \(ioForAdd.collection!.title)")
            logInfo("Adding missing note titled: \(noteToAdd.title.value)")
        }

        let newNote = Note(collection: ioForAdd.collection!)
        var i = 0
        
        while i < leftDefs.count {
            
            let leftDef = leftDefs[i]
            let rightDef = rightDefs[i]
            
            if let leftField = noteToAdd.getField(def: leftDef) {
                _ = newNote.setField(label: rightDef.fieldLabel.commonForm, value: leftField.value.value)
                if syncActions.reportDetails {
                    logInfo("  - \(rightDef.fieldLabel.properForm): \(leftField.value.value)")
                }
            }
            
            i += 1
        }
        if syncActions.performUpdates {
            _ = ioForAdd.addNote(newNote: newNote)
        }
    }
    
    func deleteUnmatchedNote(noteToDelete: Note, ioForDelete: NotenikIO) {
        
        if syncActions.reportDetails {
            logInfo("Adding to collection titled \(ioForDelete.collection!.title)")
            logInfo("Adding missing note titled: \(noteToDelete.title.value)")
        }
        
        if syncActions.performUpdates {
            _ = ioForDelete.deleteNote(noteToDelete, preserveAttachments: false)
        }
    }
    
    /// Compare two notes having the same identifiers.
    func compareNotes(leftNote: Note, rightNote: Note) {
        
        let leftMod = leftNote.copy() as! Note
        let rightMod = rightNote.copy() as! Note
        if syncActions.debugging {
            logInfo("  - Comparing notes with ids of \(leftMod.noteID.commonID)")
        }

        var i = 0
        var leftModified = false
        var rightModified = false
        
        while i < leftDefs.count {
            
            let leftDef = leftDefs[i]
            let rightDef = rightDefs[i]
            if syncActions.debugging {
                logInfo("    - comparing fields labeled: \(leftDef.fieldLabel.commonForm)")
            }
            
            let fieldModDirection = compareFields(leftNote: leftMod,
                                                  leftDateMod: leftNote.dateModifiedSortKey,
                                                  leftDef: leftDef,
                                                  leftField: leftMod.getField(def: leftDef),
                                                  rightNote: rightMod,
                                                  rightDateMod: rightNote.dateModifiedSortKey,
                                                  rightDef: rightDef,
                                                  rightField: rightMod.getField(def: rightDef))
            
            if syncActions.debugging {
                logInfo("      - comparison result is \(fieldModDirection)")
            }
            
            if fieldModDirection == .leftToRight {
                rightModified = true
            } else if fieldModDirection == .rightToLeft {
                leftModified = true
            }
            
            i += 1
        }
        
        if leftModified {
            syncTotals.leftMods += 1
            if syncActions.reportDetails {
                logInfo("Modifying note on left titled: \(leftMod.title.value)")
            }
            if syncActions.performUpdates {
                _ = leftIO.modNote(oldNote: leftNote, newNote: leftMod)
            }
        }
        
        if rightModified {
            syncTotals.rightMods += 1
            if syncActions.reportDetails {
                logInfo("Modifying note on right titled: \(rightMod.title.value)")
            }
            if syncActions.performUpdates {
                _ = rightIO.modNote(oldNote: rightNote, newNote: rightMod)
            }
        }

    }
    
    /// Compare field from the left side to field from the right side.
    func compareFields(leftNote: Note,
                       leftDateMod: String,
                       leftDef: FieldDefinition,
                       leftField: NoteField?,
                       rightNote: Note,
                       rightDateMod: String,
                       rightDef: FieldDefinition,
                       rightField: NoteField?) -> ModDirection {
        
        if syncActions.debugging {
            if leftField == nil {
                logInfo("      - left hand field is nil")
            } else {
                logInfo("      - left hand value is \(leftField!.value.value)")
            }
            if rightField == nil {
                logInfo("      - right hand field is nil")
            } else {
                logInfo("      - right hand value is \(rightField!.value.value)")
            }
        }
        
        // If the two fields are equal, then continue to the next field.
        if leftField == nil && rightField == nil {
            return .noMods
        } else if leftField != nil && rightField != nil && leftField!.value == rightField!.value {
            return .noMods
        } else if leftField == nil && rightField!.value.isEmpty {
            return .noMods
        } else if rightField == nil && leftField!.value.isEmpty {
            return .noMods
        }
        
        if syncActions.debugging {
            logInfo("      - fields are unequal")
        }
        
        // Fields are unequal: now what?
        var modDirection: ModDirection = .noMods
        if syncActions.debugging {
            logInfo("      Left  note date modified: \(leftDateMod)")
            logInfo("      Right note date modified: \(rightDateMod)")
        }
        if leftDateMod > rightDateMod {
            if direction.syncRight {
                if leftField == nil || leftField!.value.isEmpty {
                    if respectBlanks {
                        _ = rightNote.setField(label: rightDef.fieldLabel.commonForm, value: "")
                        modDirection = .leftToRight
                    }
                } else {
                    _ = rightNote.setField(label: rightDef.fieldLabel.commonForm, value: leftField!.value.value)
                    modDirection = .leftToRight
                }
            }
        } else if rightDateMod > leftDateMod {
            if direction.syncLeft {
                if rightField == nil || rightField!.value.isEmpty {
                    if respectBlanks {
                        _ = leftNote.setField(label: leftDef.fieldLabel.commonForm, value: "")
                        modDirection = .rightToLeft
                    }
                } else {
                    _ = leftNote.setField(label: leftDef.fieldLabel.commonForm, value: rightField!.value.value)
                    modDirection = .rightToLeft
                }
            }
        }
        
        return modDirection
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "CollectionSync",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "CollectionSync",
                          level: .error,
                          message: msg)
    }
    
    enum ModDirection {
        case leftToRight
        case rightToLeft
        case noMods
    }
    
    
}

