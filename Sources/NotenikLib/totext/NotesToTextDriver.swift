//
//  NotesToTextDriver.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/2/24.
//
//  Copyright © 2024 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class NotesToTextDriver {
    
    var io: NotenikIO!
    
    var notesToText: NotesToText!
    
    var writer: BigStringWriter = BigStringWriter()
    
    let failure = -1
    var exportCount = 0
    
    public var destination: URL?
    
    public init(io: NotenikIO, format: NotesToTextFormat) {
        self.io = io
        switch format {
        case .iCal:
            writer.useCarriageReturns = true
            notesToText = NotesToICal(writer: writer, io: io)
        }
    }
    
    /// Convert a series of Notes to the specified output text format.
    /// - Parameters:
    ///   - startingRow: The first row to be converted.
    ///   - endingRow: The last row to be conveted
    /// - Returns: The number of notes converted, or -1 if we encountered a failure. 
    public func toText(startingRow: Int,
                       endingRow: Int) -> Int {
        
        exportCount = failure
        
        var index = startingRow
        guard let firstNote = io.getNote(at: startingRow) else { return failure }
        
        exportCount = 0
        notesToText.start()
        
        var note: Note? = firstNote
        while note != nil && index <= endingRow {
            let added = notesToText.oneNoteToText(note: note!)
            if added < 0 {
                return failure
            } else {
                exportCount += added
            }
            index += 1
            if index <= endingRow {
                note = io.getNote(at: index)
            }
        }
        
        notesToText.finish()
        
        return exportCount
    }
    
    public func toText(selection: SelectedNotes) -> Int {
        
        exportCount = 0
        notesToText.start()
        
        for sortedNote in selection {
            let added = notesToText.oneNoteToText(note: sortedNote.note)
            if added < 0 {
                return failure
            } else {
                exportCount += added
            }
        }
        
        notesToText.finish()
        
        return exportCount
    }
    
    public func quickExport() -> Bool {
        guard let fileIO = io as? FileIO else { return false }
        guard let collection = fileIO.collection else { return false }
        guard let collectionURL = collection.lib.getURL(type: .collection) else { return false }
        guard let exportFolder = FileUtils.ensureFolder(parentURL: collectionURL, folder: "quick-export") else {
            return false
        }
        return saveToFile(folder: exportFolder, fileName: "export", fileExtension: nil)
    }
    
    public func saveToFile(folder: URL, fileName: String, fileExtension: String?) -> Bool {
        var ext = notesToText.usualFileExtension
        if fileExtension != nil {
            ext = fileExtension!
        }
        destination = folder.appendingPathComponent(fileName).appendingPathExtension(ext)
        guard destination != nil else { return false }
        do {
            try writer.bigString.write(to: destination!, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "NotesToTextDriver",
                              level: .error,
                              message: "Problem writing text file to disk at \(destination!)")
            return false
        }
        return true
    }
    
    public func getDestination() -> URL? {
        return destination
    }
    
    public enum NotesToTextFormat {
        case iCal
    }
}
