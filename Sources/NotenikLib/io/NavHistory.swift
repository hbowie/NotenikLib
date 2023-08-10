//
//  NavHistory.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/5/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Maintain a navigation history for a Collection, allowing the user to move backwards as desired.
public class NavHistory {
    
    var io: NotenikIO
    
    var previousNotes: [NoteID] = []
    
    var lastHistoryID: String? = nil
    
    public init(io: NotenikIO) {
        self.io = io
    }
    
    public func clear() {
        previousNotes = []
        lastHistoryID = nil
    }
    
    /// Try to move backwards from the given Note.
    public func backwards(from startingNote: Note) -> Note? {
        
        lastHistoryID = nil
        
        var i = previousNotes.count - 1
        var found = false
        while i >= 0 && !found {
            if startingNote.noteID == previousNotes[i] {
                found = true
            } else {
                i -= 1
            }
        }
        
        guard found && i > 0 else { return nil }
        
        i -= 1
        
        var priorNote: Note? = nil
        
        var verified = false
        while i >= 0 && !verified {
            priorNote = io.getNote(knownAs: previousNotes[i].identifier)
            if priorNote == nil {
                i -= 1
            } else {
                verified = true
            }
        }
        
        if priorNote != nil {
            lastHistoryID = priorNote!.noteID.identifier
        }
        
        return priorNote
    }
    
    /// Try to move forwards from the given Note.
    public func forwards(from startingNote: Note) -> Note? {
        
        print("Moving forwards from Note titled \(startingNote.title.value)")
        
        print("  - previous notes count = \(previousNotes.count)")
        lastHistoryID = nil
        
        var i = previousNotes.count - 1
        var found = false
        while i >= 0 && !found {
            if startingNote.noteID == previousNotes[i] {
                found = true
            } else {
                i -= 1
            }
        }
        
        print("  - match found? \(found)")
        if found {
            print("  - match found at index # \(i)")
        }
        
        guard found && i < (previousNotes.count - 1) else { return nil }
        
        i += 1
        
        var nextNote: Note? = nil
        
        var verified = false
        while i < previousNotes.count && !verified {
            nextNote = io.getNote(knownAs: previousNotes[i].identifier)
            if nextNote == nil {
                i += 1
            } else {
                verified = true
            }
        }
        
        print("  - verified? \(verified)")
        
        if nextNote != nil {
            lastHistoryID = nextNote!.noteID.identifier
        }
        
        return nextNote
    }
    
    /// Add another note to the history trail.
    public func addToHistory(another: Note) {
        
        /// If we're trying to add something that's already part of the history trail, then skip it.
        if lastHistoryID != nil && another.noteID.identifier == lastHistoryID! {
            return
        }
        
        lastHistoryID = nil
        
        /// If we're trying to add something already recorded at the top of the list, then skip it.
        if previousNotes.count > 0 {
            if another.noteID == previousNotes[previousNotes.count - 1] {
                return
            }
        }
        
        var i = 0
        var found = false
        while i < previousNotes.count && !found {
            if another.noteID == previousNotes[i] {
                found = true
            } else {
                i += 1
            }
        }
        
        if found {
            previousNotes.remove(at: i)
        }
        
        previousNotes.append(another.noteID)
    }
}
