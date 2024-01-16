//
//  LookBackTree.swift
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

/// The root of a tree structure enabling access to lookback information. A lookback field
/// shows all the lookup references to that Note.
class LookBackTree {
    
    /// The biggest branches on the tree are the Collections with lookbacks and/or lookups. 
    var collectionDict: [String: LookBackCollection] = [:]
    
    /// Initialize a new Tree to contain lookback information.
    init() {
        
    }
    
    ///
    func requestLookbacks(collectionID: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "LookBackTree",
                          level: .info,
                          message: "Lookbacks requested for collection ID of \(collectionID)")
        ensureCollection(collectionID: collectionID)
        collectionDict[collectionID]!.requestLookbacks()
    }
    
    
    /// Record a request for lookbacks.
    /// - Parameters:
    ///   - lkUpCollectionID: Identifier for the Collection doing the lookups.
    ///   - lkUpFieldLabel:   Common label for the field doing the lookup.
    ///   - lkBkCollectionID: Identifier the the Collection requesting the lookbacks.
    ///   - lkBkFieldLabel:   Common label for the field requesting the lookback.
    func requestLookbacks(lkUpCollectionID: String,
                          lkUpFieldLabel:   String,
                          lkBkCollectionID: String,
                          lkBkFieldLabel:   String) {
        ensureCollection(collectionID: lkUpCollectionID)
        collectionDict[lkUpCollectionID]!.requestLookbacks(lkUpFieldLabel: lkUpFieldLabel,
                                                           lkBkCollectionID: lkBkCollectionID,
                                                           lkBkFieldLabel: lkBkFieldLabel)
    }
    
    /// Register a lookup.
    /// - Parameters:
    ///   - lkUpCollectionID: The identifier for the Collection with the lookups.
    ///   - lkUpNoteTitle:    The title of the Note with the lookup.
    ///   - lkUpFieldLabel:   The common label for the Lookup field.
    ///   - lkBkCollectionID: The identifier for the Collection requesting the lookback(s).
    ///   - lkBkFieldLabel:   The common label for the lookback field.
    ///   - lkUpValue:        The common form of the title of the note being looked up.
    func registerLookup(lkUpCollectionID: String,
                        lkUpNoteTitle:    String,
                        lkUpFieldLabel:   String,
                        lkBkCollectionID: String,
                        lkBkFieldLabel:   String,
                        lkUpValue:        String) {
        
        ensureCollection(collectionID: lkBkCollectionID)
        collectionDict[lkBkCollectionID]!.registerLookup(lkUpCollectionID: lkUpCollectionID,
                                                         lkUpNoteTitle: lkUpNoteTitle,
                                                         lkUpFieldLabel: lkUpFieldLabel,
                                                         lkBkFieldLabel: lkBkFieldLabel,
                                                         lkUpValue: lkUpValue)
    }
    
    func registerLookBacks(lkUpNote: Note) {
        if let lkUpCollection = collectionDict[lkUpNote.collection.collectionID] {
            if lkUpCollection.lookBacksRequested {
                for (_, field) in lkUpNote.fields {
                    if field.def.fieldType.typeString == NotenikConstants.lookupType {
                        if !field.def.lookupFrom.isEmpty {
                            if let lkBkDef = lkUpCollection.identifyLookBackField(lkUpFieldLabel: field.def.fieldLabel.commonForm) {
                                ensureCollection(collectionID: field.def.lookupFrom)
                                collectionDict[field.def.lookupFrom]!.registerLookBacks(lkUpNote: lkUpNote,
                                                                                        lkUpField: field,
                                                                                        lkBkDef: lkBkDef)
                            } else {
                                // print("    - lkBkDef not found!")
                            }
                        } else {
                            // print("    - look up from is empty")
                        }
                    } else {
                        // print("    - not a lookup field type")
                    }
                }
            } else {
                // print("  - No lookbacks requested for this collection")
            }
        } else {
            // print("  - lkUpCollection not found for \(lkUpNote.collection.collectionID)")
        }
    }
    
    func cancelLookBacks(lkUpNote: Note) {
        if let lkUpCollection = collectionDict[lkUpNote.collection.collectionID] {
            if lkUpCollection.lookBacksRequested {
                for (_, field) in lkUpNote.fields {
                    if field.def.fieldType.typeString == NotenikConstants.lookupType {
                        if !field.def.lookupFrom.isEmpty {
                            if let lkBkDef = lkUpCollection.identifyLookBackField(lkUpFieldLabel: field.def.fieldLabel.commonForm) {
                                ensureCollection(collectionID: field.def.lookupFrom)
                                collectionDict[field.def.lookupFrom]!.cancelLookBacks(lkUpNote: lkUpNote,
                                                                                      lkUpField: field,
                                                                                      lkBkDef: lkBkDef)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func ensureCollection(collectionID: String) {
        guard !collectionDict.keys.contains(collectionID) else { return }
        collectionDict[collectionID] = LookBackCollection(collectionID: collectionID)
    }
    
    func getLookBackLines(collectionID: String, noteID: String, lkBkCommonLabel: String) -> [LookBackLine] {
        if collectionDict.keys.contains(collectionID) {
            return collectionDict[collectionID]!.getLookBackLines(noteID: noteID,
                                                                  lkBkCommonLabel: lkBkCommonLabel)
        } else {
            return []
        }
    }
}
