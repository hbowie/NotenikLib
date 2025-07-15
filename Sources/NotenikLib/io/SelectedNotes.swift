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
    
    var notesDict: [String: Note] =  [:]
    var notesList: [Note] = []
    
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
            if let selNote = io.getNote(at: index) {
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
    
    public func append(_ note: Note) {
        notesDict[note.id] = note
        notesList.append(note)
    }
    
    public func contains(element: Note) -> Bool {
        return (notesDict[element.id] != nil)
    }
    
    public func getNote(at: Int) -> Note? {
        guard at >= 0 && at < notesList.count else { return nil }
        return notesList[at]
    }
    
    public func makeIterator() -> Array<Note>.Iterator {
        return notesList.makeIterator()
    }
    
}
