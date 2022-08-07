//
//  ModIfChanged.swift
//  Notenik
//
//  Created by Herb Bowie on 4/5/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// A Bridge between a User Interface and an Input/Output Module
public class ModWhenChanged {
    
    var io: NotenikIO
    
    var parms = DisplayParms()
    var mkdownContext: NotesMkdownContext
    var mkdownOptions = MkdownOptions()
    
    public init(io: NotenikIO) {
        self.io = io
        if io.collection != nil {
            parms.setFrom(collection: io.collection!)
        }
        parms.setMkdownOptions(mkdownOptions)
        mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
    }
    
    /// Analyse the user's input and make appropriate changes to a Note through an
    /// I/O Module.
    ///
    /// - Parameters:
    ///   - newNoteRequested: Are we trying to add a new note, rather than modify an existing one?
    ///   - startingNote: The Note to which we want to compare the user's input.
    ///   - modViews: One user view for each field defined for the collection.
    /// - Returns: The outcome of the analysis and actions performed, plus the relevant Note.
    public func modIfChanged(newNoteRequested: Bool,
                      startingNote: Note,
                      editDefs: [FieldDefinition],
                      modViews: [ModView],
                      statusConfig: StatusValueConfig,
                      levelConfig: IntWithLabelConfig) -> (modIfChangedOutcome, Note?) {
        
        var outcome: modIfChangedOutcome = .notReady
        
        // See if we're ready for this
        guard let collection = io.collection else { return (outcome, nil) }
        guard io.collectionOpen else { return (outcome, nil) }
        
        let defs = editDefs
        
        guard defs.count == modViews.count else {
            logError("Number of Field Definitions does not match number of Edit Values")
            return (outcome, nil)
        }
        
        outcome = .noChange
        
        // Let's get a Note ready for comparison and possible modifications
        var modNote: Note
        if newNoteRequested {
            modNote = startingNote
        } else {
            modNote = startingNote.copy() as! Note
        }
        
        // See if any fields were modified by the user, and update corresponding Note fields
        var modified = false
        var i = 0
        for def in defs {
            let field = modNote.getField(def: def)
            let fieldView = modViews[i]
            var noteValue = ""
            if field != nil {
                if field!.def.fieldType.typeString == NotenikConstants.statusCommon {
                    noteValue = statusConfig.getFullString(fromLabel: field!.value.value)
                } else if field!.def.fieldType.typeString == NotenikConstants.levelCommon {
                    noteValue = levelConfig.intWithLabel(forLabel: field!.value.value)
                } else {
                    noteValue = field!.value.value
                }
            }
            var userValue = fieldView.text
            if def.fieldType is TagsType {
                let userTags = TagsValue(fieldView.text)
                userValue = userTags.value
            }
            if userValue != noteValue {
                let newValue = def.fieldType.createValue(userValue)
                if field == nil {
                    let newField = NoteField(def: def, statusConfig: statusConfig, levelConfig: levelConfig)
                    newField.value = newValue
                    let addOK = modNote.addField(newField)
                    if !addOK {
                        logError("Unable to add field to note")
                    }
                } else {
                    field!.value = newValue
                }
                if def.fieldType.typeString == NotenikConstants.comboType {
                    io.registerComboValue(comboDef: def, value: userValue)
                }
                modified = true
            }
            i += 1
        }
        
        // Make sure the Note has some kind of title.
        if modNote.title.isEmpty {
            if newNoteRequested {
                _ = modNote.setTitle(StringUtils.summarize(modNote.body.value, max: 50))
                if modNote.title.isEmpty {
                    _ = modNote.setTitle("New Note without a title")
                }
            } else {
                _ = modNote.setTitle(startingNote.title.value)
            }
        }
        
        if modNote.hasBody() && AppPrefs.shared.parseUsingNotenik &&
            (collection.minutesToReadDef != nil || collection.wikilinksDef != nil || collection.backlinksDef != nil) {
            
            // Parse the body field.
            let body = modNote.body
            let mdBodyParser = MkdownParser(body.value, options: mkdownOptions)
            mdBodyParser.setWikiLinkFormatting(prefix: parms.wikiLinkPrefix,
                                               format: parms.wikiLinkFormat,
                                               suffix: parms.wikiLinkSuffix,
                                               context: mkdownContext)
            mdBodyParser.parse()
            
            // See if Minutes to Read have changed.
            if collection.minutesToReadDef != nil {
                let newMinutes = MinutesToReadValue(with: mdBodyParser.counts)
                let oldMinutes = modNote.getField(def: collection.minutesToReadDef!)
                if oldMinutes == nil || oldMinutes!.value != newMinutes {
                    let minutesField = NoteField(def: collection.minutesToReadDef!, value: newMinutes)
                    _ = modNote.setField(minutesField)
                    modified = true
                }
            }
            
            // See if extracted Wiki Links have changed.
            if collection.wikilinksDef != nil {
                let newLinks = mdBodyParser.wikiLinkList.links
                let trans = Transmogrifier(io: io)
                let mods = trans.updateLinks(for: modNote, links: newLinks)
                if mods {
                    modified = true
                }
            }
        }
        
        // Were any fields modified?
        if modified || newNoteRequested {
            outcome = .modify
            modNote.setID()
            let modID = modNote.noteID
            
            // If we have a new Note ID, make sure it's unique
            var newID = newNoteRequested
            if newNoteRequested {
                outcome = .add
            }
            if !newNoteRequested {
                newID = (startingNote.noteID != modID)
                if newID {
                    outcome = .modWithKeyChanges
                }
            }
            if newID {
                io.ensureUniqueID(for: modNote)
            }
            if outcome == .modify {
                if startingNote.sortKey != modNote.sortKey {
                    outcome = .modWithKeyChanges
                } else if startingNote.tags != modNote.tags {
                    outcome = .modWithKeyChanges
                } else if collection.akaFieldDef != nil && startingNote.aka != modNote.aka {
                    outcome = .modWithKeyChanges
                }
            }
            if modID.count == 0 {
                outcome = .noChange
            }
        }
        
        // Figure out what we need to do
        switch outcome {
        case .notReady:
            return (outcome, nil)
        case .noChange:
            return (outcome, nil)
        case .idAlreadyExists:
            return (outcome, nil)
        case .tryAgain:
            return (outcome, nil)
        case .discard:
            return (outcome, nil)
        case .add:
            let (addedNote, _) = io.addNote(newNote: modNote)
            if addedNote != nil {
                return (outcome, addedNote)
            } else {
                logError("Problems adding note titled \(modNote.title)")
                return (.tryAgain, nil)
            }
        case .modWithKeyChanges:
            modNote.fileInfo.optRegenFileName()
            let attachmentsOK = io.reattach(from: startingNote, to: modNote)
            if !attachmentsOK {
                logError("Problems renaming attachments for \(modNote.title)")
            }
            let (updatedNote, _) = io.modNote(oldNote: startingNote, newNote: modNote)
            
            // let (_, _) = io.deleteSelectedNote(preserveAttachments: true)
            // let (addedNote, _) = io.addNote(newNote: modNote)
            if updatedNote != nil {
                return (outcome, updatedNote)
            } else {
                logError("Problems updating note titled \(modNote.title)")
                return (.tryAgain, nil)
            }
        case .modify:
            modNote.copyFields(to: startingNote)
            let writeOK = io.writeNote(startingNote)
            if !writeOK {
                logError("Write Note failed!")
            }
            return (outcome, startingNote)
        }
    } // end modIfChanged method
    
    /// Log an error message.
    func logError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ModWhenChanged",
                          level: .error,
                          message: msg)
        
    }
}
