//
//  AliasList.swift
//  
//
//  Created by Herb Bowie on 7/9/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// Keeps track of a list of aliases for Notes within a Collection.
public class AliasList: RowConsumer {
    
    var noteIO: NotenikIO?
    
    var aliasDict = [String: String]()
    
    var rowsLoaded = 0
    var rowsSaved  = 0
    
    var mkdownOptions = MkdownOptions()
    
    init() {
        
    }
    
    init(io: NotenikIO) {
        self.noteIO = io
    }
    
    /// Return the number of alias entries in the list.
    var count: Int {
        return aliasDict.count
    }
    
    
    /// Load the exising alias list from its disk file within the collection.
    func loadFromDisk() {
        guard let io = noteIO as? FileIO else { return }
        guard let collection = io.collection else { return }
        guard collection.hasTimestamp else { return }
        guard let lib = collection.lib else { return }
        rowsLoaded = 0
        var loaded = false
        if lib.hasAvailable(type: .alias) {
            loaded = lib.getDelimited(type: .alias, consumer: self)
        }
        if loaded {
            logInfo("Loaded \(rowsLoaded) alias entries from \(NotenikConstants.aliasFileName)")
        } else {
            initFromExistingNotes()
        }
    }
    
    /// No disk file found -- let's go through the existing list of notes to generate whatever entries are out there now. 
    func initFromExistingNotes() {
        guard AppPrefs.shared.notenikParser else { return }
        var i = 0
        while i < noteIO!.notesCount {
            let nextNote = noteIO!.getNote(at: i)
            i += 1
            guard nextNote != nil else { continue }
            let md = nextNote!.body.value
            guard md.count > 0 else { continue }
            let mkdown = MkdownParser(md, options: mkdownOptions)
            let mkdownContext = NotesMkdownContext(io: noteIO!)
            mkdown.mkdownContext = mkdownContext
            mkdown.parse()
        }
        logInfo("Initialized Wiki Link to Timestamp Alias List with \(count) entries")
    }
    
    /// Import existing entries from another Alias List.
    func importFrom(_ importList: AliasList) {
        for (titleID, timestamp) in importList.aliasDict {
            add(titleID: titleID, timestamp: timestamp)
        }
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    public func consumeField(label: String, value: String) {
        // Don't need to do anything here
    }
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    public func consumeRow(labels: [String], fields: [String]) {
        guard fields.count == 2 else { return }
        add(titleID: fields[0], timestamp: fields[1])
        rowsLoaded += 1
    }
    
    /// Save the list of aliases to disk.
    /// - Returns: True if no problems were encountered; false if problems did occur.
    func saveToDisk() -> Bool {
        guard let io = noteIO as? FileIO else { return true }
        guard let collection = io.collection else { return true }
        guard !collection.readOnly else { return true }
        guard collection.hasTimestamp else { return true }
        guard count > 0 else { return true }
        guard let fileURL = collection.lib.getURL(type: .alias) else { return false }
        let writer = DelimitedWriter(destination: fileURL, format: .tabDelimited)
        writer.open()
        writer.write(value: "Title ID")
        writer.write(value: "Timestamp")
        writer.endLine()
        rowsSaved = 0
        for (titleID, timestamp) in aliasDict {
            writer.write(value: titleID)
            writer.write(value: timestamp)
            writer.endLine()
            rowsSaved += 1
        }
        let ok = writer.close()
        if ok {
            logInfo("Saved \(rowsSaved) alias entries to \(NotenikConstants.aliasFileName)")
        }
        return ok
    }
    
    /// Add another link from a title ID to a timestamp.
    func add(titleID: String, timestamp: String) {
        aliasDict[titleID] = timestamp
    }
    
    /// Get the timestamp for the given title ID, or return nil, if no entry exists.
    /// - Parameter titleID: The Title ID of interest.
    /// - Returns: The timestamp found, if any. 
    func get(titleID: String) -> String? {
        return aliasDict[titleID]
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "AliasList",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "AliasList",
                          level: .error,
                          message: msg)
    }
}
