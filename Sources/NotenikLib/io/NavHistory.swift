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
    
    var previousNotes: [String] = []
    
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
            if startingNote.noteID.commonID == previousNotes[i] {
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
            priorNote = io.getNote(knownAs: previousNotes[i])
            if priorNote == nil {
                i -= 1
            } else {
                verified = true
            }
        }
        
        if priorNote != nil {
            lastHistoryID = priorNote!.noteID.commonID
        }
        
        return priorNote
    }
    
    /// Try to move forwards from the given Note.
    public func forwards(from startingNote: Note) -> Note? {
        
        lastHistoryID = nil
        
        var i = previousNotes.count - 1
        var found = false
        while i >= 0 && !found {
            if startingNote.noteID.commonID == previousNotes[i] {
                found = true
            } else {
                i -= 1
            }
        }
        
        guard found && i < (previousNotes.count - 1) else { return nil }
        
        i += 1
        
        var nextNote: Note? = nil
        
        var verified = false
        while i < previousNotes.count && !verified {
            nextNote = io.getNote(knownAs: previousNotes[i])
            if nextNote == nil {
                i += 1
            } else {
                verified = true
            }
        }
        
        if nextNote != nil {
            lastHistoryID = nextNote!.noteID.commonID
        }
        
        return nextNote
    }
    
    /// Add another note to the history trail.
    public func addToHistory(another: Note) {
        
        /// If we're trying to add something that's already part of the history trail, then skip it.
        if lastHistoryID != nil && another.noteID.commonID == lastHistoryID! {
            return
        }
        
        /// If we're trying to add something already recorded at the top of the list, then skip it.
        if previousNotes.count > 0 {
            if another.noteID.commonID == previousNotes[previousNotes.count - 1] {
                return
            }
        }
        
        if lastHistoryID != nil {
            var i = 0
            var previousID: String? = nil
            while i < previousNotes.count && previousID == nil {
                if lastHistoryID == previousNotes[i] {
                    previousID = previousNotes.remove(at: i)
                } else {
                    i += 1
                }
            }
            if previousID != nil {
                previousNotes.append(previousID!)
            }
        }
        
        var i = 0
        var found = false
        while i < previousNotes.count && !found {
            if another.noteID.commonID == previousNotes[i] {
                found = true
            } else {
                i += 1
            }
        }
        
        if found {
            previousNotes.remove(at: i)
        }
        
        previousNotes.append(another.noteID.commonID)
        
        lastHistoryID = nil
    }
}
