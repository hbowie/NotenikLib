//
//  MDtoOutlineReader.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/11/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class MDtoOutlineImporter: RowConsumer {
    
    var notesImported = 0
    var notesModified = 0
    var noteToImport: Note?
    var seqParms: SeqParms = SeqParms()
    var latestSeq: SeqSingleValue
    var importParms = ImportParms()
    
    var io: NotenikIO = FileIO()
    var collection = NoteCollection()
    var fileIO: FileIO?
    
    public init() {
        latestSeq = SeqSingleValue("", seqParms: seqParms)
    }
    
    public func importNow(io: NotenikIO, fileURL: URL, importParms: ImportParms) -> (Int, Int) {
        
        self.io = io
        guard io.collection != nil else { return (0, 0) }
        guard io.collectionOpen else { return (0, 0) }
        collection = io.collection!
        fileIO = nil
        if let fio = io as? FileIO {
            fileIO = fio
        }
        
        notesImported = 0
        latestSeq = SeqSingleValue("", seqParms: seqParms)
        noteToImport = Note(collection: io.collection!)
        
        let reader = MDHeadReader()
        reader.setContext(consumer: self)
        reader.read(fileURL: fileURL)
        
        if importParms.addingFields {
            if fileIO != nil {
                _ = fileIO!.saveTemplateFile()
            }
        }
        return (notesImported, notesModified)
    }
    
    public func consumeField(label: String, value: String, rule: FieldUpdateRule) {
        let labelCommon = StringUtils.toCommon(label)
        var v = value
        
        if labelCommon == NotenikConstants.titleCommon || labelCommon == collection.titleFieldDef.fieldLabel.commonForm {
            importParms.titleFieldFound = true
            v = StringUtils.dropLeadingNumber(value)
        }
        
        let ok = noteToImport!.setField(label: label, value: v)
        if ok { return }
        logError("Could not set note field \(label) to value of \(v)")
    }
    
    public func consumeRow(labels: [String], fields: [String]) {
        
        // Maintain a running sequence value
        if notesImported == 0 && noteToImport != nil && noteToImport!.level.getInt() == 1 {
            // Use initial seq value for this note
        } else {
            latestSeq.incAtLevel(level: noteToImport!.level.getInt() - 2, removingDeeperLevels: true)
        }
 
        let ok = noteToImport!.setSeq(latestSeq.value)
        if !ok {
            logError("Failed to set sequence value to \(latestSeq.value)")
        }
        // print("level \(noteToImport!.level.getInt()) - \(noteToImport!.seq.value) \(noteToImport!.title.value)")
        noteToImport!.identify()
        let existingNote = io.getNote(forID: noteToImport!.noteID)
        if existingNote != nil {
            let newNote = existingNote!.copy() as! Note
            for (_, field) in noteToImport!.fields {
                let newValue = field.value.value
                var existingValue = ""
                if let ev = existingNote!.getField(label: field.def.fieldLabel.commonForm)?.value.value {
                    existingValue = ev
                }
                if field.def.fieldLabel.commonForm == collection.bodyFieldDef.fieldLabel.commonForm && existingValue.starts(with: "{:collection-toc") {
                    // Let's not replace the Notenik toc command
                } else if !newValue.isEmpty && newValue != existingValue {
                    _ = newNote.setField(label: field.def.fieldLabel.properForm,
                                                  value: field.value.value)
                }
            }
            (_, _) = io.modNote(oldNote: existingNote!, newNote: newNote)
            notesModified += 1
            noteToImport = Note(collection: collection)
            return
        }
        
        let (newNote, _) = io.addNote(newNote: noteToImport!)
        if newNote != nil {
            notesImported += 1
        } else {
            logError("Could not add note titled \(noteToImport!.title.value)")
        }
        noteToImport = Note(collection: collection)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "MDtoOutlineImporter",
                          level: .error,
                          message: msg)
    }
    
}
