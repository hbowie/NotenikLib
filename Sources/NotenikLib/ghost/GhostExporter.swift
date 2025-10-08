//
//  GhostExporter.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/5/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// Export a JSON file for import into Ghost.
public class GhostExporter {
    
    let appPrefs = AppPrefs.shared
    
    var tagsToSelect:   TagsValue!
    var tagsToSuppress: TagsValue!
    
    var noteIO: NotenikIO!
    var collection: NoteCollection!
    var dict = FieldDictionary()
    var mkdownContext: MkdownContext!
    
    var hasStatus = false
    
    var destination: URL!
    
    var jsonWriter: JSONWriter!
    
    var displayParms = DisplayParms()
    var display = NoteDisplay()
    
    var postID = 0
    
    var exportErrors = 0
    var notesExported = 0
    var tagsWritten = 0
    
    /// Initialize the Exporter.
    public init() {
        tagsToSelect = TagsValue(appPrefs.tagsToSelect)
        tagsToSuppress = TagsValue(appPrefs.tagsToSuppress)
    }
    
    public func export(noteIO: NotenikIO, destination: URL) -> Int {
        
        guard noteIO.collection != nil && noteIO.collectionOpen else { return -1 }
        
        self.noteIO = noteIO
        collection = noteIO.collection!
        mkdownContext = NotesMkdownContext(io: noteIO)
        dict = noteIO.collection!.dict
        hasStatus = dict.contains(NotenikConstants.statusCommon)
        self.destination = destination
        
        displayParms.curlyApostrophes = collection.curlyApostrophes
        displayParms.extLinksOpenInNewWindows = collection.extLinksOpenInNewWindows
        
        exportErrors = 0
        
        // Open the JSON writer for output
        jsonWriter = JSONWriter()
        jsonWriter.writer = BigStringWriter()
        jsonWriter.open()
        jsonWriter.startObject()
        
        // Write out metadata for Ghost import
        jsonWriter.startObject(withKey: "meta")
        let timestamp = UInt64(NSDate().timeIntervalSince1970 * 1000.0)
        jsonWriter.write(key: "exported_on", value: timestamp)
        jsonWriter.write(key: "version", value: "6.0.0")
        jsonWriter.endObject()
        
        // Start data object.
        jsonWriter.startObject(withKey: "data")
        
        // Start posts object.
        jsonWriter.startArray(withKey: "posts")
        
        // Now write out the notes as posts.
        var (sortedNote, position) = noteIO.firstNote()
        while sortedNote != nil {
            let note = sortedNote!.note
            var selected = true
            if hasStatus {
                let statusValue = note.status
                if statusValue.statusInt < 9 {
                    selected = false
                }
            }
            if selected {
                
                // Write post object
                jsonWriter.startObject()
                postID += 1
                jsonWriter.write(key: "id", value: String(format: "%04d", postID))
                jsonWriter.write(key: "title", value: note.title.value)
                jsonWriter.write(key: "slug", value: StringUtils.toCommonFileName(note.title.value))
                jsonWriter.endObject()
                notesExported += 1
            }
            (sortedNote, position) = noteIO.nextNote(position)
        }
        
        // End array of posts. 
        jsonWriter.endArray()
        
        // End data object.
        jsonWriter.endObject()
        
        // Close and save the JSON export file. 
        jsonWriter.endObject()
        jsonWriter.close()
        let ok = jsonWriter.save(destination: destination)
        
        if ok {
            logNormal("\(notesExported) notes exported")
            return notesExported
        } else {
            logError("Problems closing output export file")
            return -1
        }
    }
    
    /// Log a normal message
    func logNormal(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "GhostExporter", level: .info, message: msg)
    }
    
    /// Log a normal message
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "GhostExporter", level: .error, message: msg)
    }
    
}
