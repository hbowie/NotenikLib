//
//  NotenikImporter.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/4/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class NotenikImporter {
    
    var parms: ImportParms
    
    var importIO: NotenikIO
    var importCollection: NoteCollection!
    var importDict: FieldDictionary!
    
    var updateIO: NotenikIO
    var updateCollection: NoteCollection!
    var updateDict: FieldDictionary!
    
    /// Initialize with necessary objects
    /// - Parameters:
    ///   - parms: The Import parameters to be used.
    ///   - importIO: The I/O module for the Notes to be imported, assumed to be already opened.
    ///   - updateIO: The I/O module for the Collection to be updated, assumed to be already opened. .
    public init(parms: ImportParms, importIO: NotenikIO, updateIO: NotenikIO) {
        self.parms = parms
        self.importIO = importIO
        self.updateIO = updateIO
    }
    
    /// Perform the import function now, according to the Impoart Parameters previously passed.
    public func importNotes() {
        
        logMsg("Starting Notenik Import", level: .info)
        logMsg("Additional Fields Parm: \(parms.columnParm)", level: .info)
        logMsg("Rows Parm: \(parms.rowParm)", level: .info)
        logMsg("Consolidate Lookups? \(parms.consolidateLookups)", level: .error)
        
        parms.input = 0
        parms.added = 0
        parms.modified = 0
        parms.ignored = 0
        parms.rejected = 0
        
        guard let importCollection = importIO.collection else { return }
        importDict = importCollection.dict
        
        guard let updateCollection = updateIO.collection else { return }
        updateDict = updateCollection.dict
        
        // If we're adding fields then add them now, to keep them in
        // the desired order. 
        if parms.addingFields {
            let leaveLocked = updateDict.locked
            if updateDict.locked {
                updateDict.unlock()
            }
            for importDef in importDict.list {
                if !updateDict.contains(importDef) {
                    let updateDef = importDef.copy()
                    if parms.consolidateLookups && updateDef.fieldType.typeString == NotenikConstants.lookupType {
                        updateDef.fieldType = updateDef.typeCatalog.assignType(label: updateDef.fieldLabel, type: NotenikConstants.stringType)
                        _ = updateDict.addDef(updateDef)
                        addLookupDefs(importDef)
                    } else {
                        _ = updateDict.addDef(updateDef)
                    }
                }
            }
            if leaveLocked {
                updateDict.lock()
            }
            updateIO.persistCollectionInfo()
        }
        
        // Process each Note in the import Collection.
        var (importNote, importPosition) = importIO.firstNote()
        while importNote != nil && importPosition.valid {
            
            parms.input += 1
            
            // Build a Note containing only the prescribed fields.
            let commonNote = Note(collection: updateCollection)
            
            // Process each field in each Note.
            for (_, importField) in importNote!.fields {
                if importField.value.hasData {
                    
                    // Add field to dictionary if not already present, and allowed.
                    var fieldExistsInDict = updateDict.contains(importField.def)
                    if !fieldExistsInDict && parms.addingFields {
                        let leaveLocked = updateDict.locked
                        if updateDict.locked {
                            updateDict.unlock()
                        }
                        let updateDef = importField.def.copy()
                        let addedDef = updateDict.addDef(updateDef)
                        fieldExistsInDict = (addedDef != nil)
                        if leaveLocked {
                            updateDict.lock()
                        }
                    }
                    
                    if fieldExistsInDict {
                        if let updateDef = updateDict.getDef(importField.def.fieldLabel.commonForm) {
                            let value = updateDef.fieldType.createValue(importField.value.value)
                            let field = NoteField(def: updateDef, value: value)
                            _ =  commonNote.setField(field)
                            if parms.consolidateLookups && importField.def.fieldType.typeString == NotenikConstants.lookupType {
                                addLookupFields(importField, importCollection: importCollection, commonNote: commonNote)
                            }
                        }
                    }
                }
            }
            
            commonNote.identify()
            
            let existingNote = updateIO.getNote(forID: commonNote.noteID)
            
            switch parms.rowParm {
            case .add:
                updateIO.ensureUniqueID(for: commonNote)
                let (added, _) = updateIO.addNote(newNote: commonNote)
                if added == nil {
                    parms.rejected += 1
                } else {
                    parms.added += 1
                }
            case .matchAndAdd:
                if existingNote == nil {
                    let (added, _) = updateIO.addNote(newNote: commonNote)
                    if added == nil {
                        parms.rejected += 1
                    } else {
                        parms.added += 1
                    }
                } else {
                    let (mod, _) = updateIO.modNote(oldNote: existingNote!, newNote: commonNote)
                    if mod == nil {
                        parms.rejected += 1
                    } else {
                        parms.modified += 1
                    }
                }
            case .matchOnly:
                if existingNote == nil {
                    parms.ignored += 1
                } else {
                    let (mod, _) = updateIO.modNote(oldNote: existingNote!, newNote: commonNote)
                    if mod == nil {
                        parms.rejected += 1
                    } else {
                        parms.modified += 1
                    }
                }
            }
            
            (importNote, importPosition) = importIO.nextNote(importPosition)
        } // end for every input note
        
        updateIO.persistCollectionInfo()
    } // end of importNotes function
    
    /// Obtain additional field  definitions for a lookup field.
    func addLookupDefs(_ def: FieldDefinition) {
        
        logMsg("Looking up related defs for field labeled '\(def.fieldLabel.properForm)'", level: .info)
        let shortcut = def.lookupFrom
        let (collection2, _) = MultiFileIO.shared.provision(shortcut: shortcut, inspector: nil, readOnly: false)
        guard let lookupCollection = collection2 else {
            logMsg("Collection shortcut of \(shortcut) could not be provisioned", level: .error)
            return
        }
        let lookupDict = lookupCollection.dict
        for lookupDef in lookupDict.list {
            if lookupDef != lookupCollection.idFieldDef {
                if !updateDict.contains(lookupDef) {
                    let updateDef = lookupDef.copy()
                    _ = updateDict.addDef(updateDef)
                }
            }
        }
    }
    
    /// Add Lookup Fields.
    func addLookupFields(_ field: NoteField, importCollection: NoteCollection, commonNote: Note) {
        
        let shortcut = field.def.lookupFrom
        let path = importCollection.fullPath
        let realm = importCollection.lib.realm
        MultiFileIO.shared.prepareForLookup(shortcut: shortcut, collectionPath: path, realm: realm)
        let lookupNote = MultiFileIO.shared.getNote(shortcut: shortcut, knownAs: field.value.value)
        guard lookupNote != nil else {
            logMsg("Lookup failed for shortcut of '\(shortcut)' with ID of '\(field.value.value)'", level: .error)
            return
        }
        let lookupCollection = lookupNote!.collection
        let lookupDict = lookupCollection.dict
        for lookupDef in lookupDict.list {
            if lookupDef != lookupCollection.idFieldDef {
                let lookupField = lookupNote!.getField(def: lookupDef)
                if lookupField != nil && lookupField!.value.hasData {
                    if let updateDef = updateDict.getDef(lookupField!.def.fieldLabel.commonForm) {
                        let value = updateDef.fieldType.createValue(lookupField!.value.value)
                        let field = NoteField(def: updateDef, value: value)
                        _ =  commonNote.setField(field)
                    }
                }
            }
        }
    }
    
    /// Log an error message and optionally display an alert message.
    func logMsg(_ msg: String, level: LogLevel) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NotenikImporter",
                          level: level,
                          message: msg)
    }
} // end of NotenikImporter class
