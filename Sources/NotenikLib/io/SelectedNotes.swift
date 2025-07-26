//
//  SelectedNotes.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/11/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class SelectedNotes: Sequence {
    
    var io: NotenikIO?
    var collection: NoteCollection?
    
    var notesDict: [String: SortedNote] =  [:]
    var notesList: [SortedNote] = []
    
    public init() {
        
    }
    
    public init(io: NotenikIO) {
        self.io = io
        self.collection = io.collection
    }
    
    public init(io: NotenikIO, selected: IndexSet) {
        self.io = io
        self.collection = io.collection
        for index in selected {
            if let selNote = io.getSortedNote(at: index) {
                append(selNote)
            }
        }
    }
    
    public var count: Int {
        return notesList.count
    }
    
    public func removeAll() {
        notesDict.removeAll()
        notesList.removeAll()
    }
    
    public func append(_ sortedNote: SortedNote) {
        notesDict[sortedNote.note.id] = sortedNote
        notesList.append(sortedNote)
    }
    
    public func contains(element: SortedNote) -> Bool {
        return (notesDict[element.note.id] != nil)
    }
    
    public func contains(element: Note) -> Bool {
        return (notesDict[element.id] != nil)
    }
    
    public func getNote(at: Int) -> SortedNote? {
        guard at >= 0 && at < notesList.count else { return nil }
        return notesList[at]
    }
    
    public func makeIterator() -> Array<SortedNote>.Iterator {
        return notesList.makeIterator()
    }
    
}
