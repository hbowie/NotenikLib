//
//  NoteCrumbs.swift
//  Notenik
//
//  Created by Herb Bowie on 12/12/19.
//  Copyright © 2019-2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Keep track of where we've been and how we got here, and allow the user
/// to move forward and backwards in the list of notes s/he's visited.
public class NoteCrumbs {
    
    var io: NotenikIO
    
    var crumbs: [NoteID] = []
    var lastIndex: Int { return crumbs.count - 1 }
    
    var lastIDReturned: NoteID?
    
    public init(io: NotenikIO) {
        self.io = io
    }
    
    /// Indicate the latest note visited by the user.
    public func select(_ selected: Note) {
        
        /// If this note is just the last one returned from this list, then
        /// leave well enough alone.
        if selected.noteID == lastIDReturned && crumbs.count > 0 { return }
        
        /// No? Then see if it's already in the list.
        let index = locate(selected.noteID)
        if index >= 0 {
            lastIDReturned = selected.noteID
            return
        }
        
        append(selected.noteID)
    }
    
    /// Go back to the prior note in the breadcrumbs.
    /// - Parameter from: The Note we're starting from.
    public func backup(from: Note) -> Note {
        
        // See if we can back up within the existing breadcrumb trail.
        var index = locate(from.noteID)
        if index > 0 {
            index -= 1
            if let priorNote = io.getNote(forID: crumbs[index]) {
                lastIDReturned = priorNote.noteID
                return priorNote
            }
        }
        
        // No? Then throw out breadcrumbs and start over.
        let position = io.positionOfNote(from)
        var (priorNote, _) = io.priorNote(position)
        if priorNote == nil {
            (priorNote, _) = io.lastNote()
        }
        refresh(with: priorNote!.noteID)
        return priorNote!
    }
    
    /// Go forward to the next Note in the list.
    /// - Parameter from: The Note we're starting from.
    public func advance(from: Note) -> Note {
        
        // See if we can advance within the existing breadcrumb trail.
        var index = locate(from.noteID)
        if index >= 0 && index < lastIndex {
            index += 1
            if let nextNote = io.getNote(forID: crumbs[index]) {
                lastIDReturned = nextNote.noteID
                return nextNote
            }
        }
        
        // No? Then throw out breadcrumbs and start over.
        let position = io.positionOfNote(from)
        var (nextNote, _) = io.nextNote(position)
        if nextNote == nil {
            (nextNote, _) = io.firstNote()
        }
        refresh(with: nextNote!.noteID)
        return nextNote!
    }
    
    /// Refresh breadcrumbs with an initial entry.
    func refresh(with id: NoteID) {
        refresh()
        append(id)
    }
    
    /// Let's start over.
    public func refresh() {
        crumbs = []
        lastIDReturned = nil
    }
    
    func append(_ id: NoteID) {
        crumbs.append(id)
        lastIDReturned = id
    }
    
    /// Locate the given Note ID within the list of breadcrumbs, returning -1 if not found.
    func locate(_ id: NoteID) -> Int {
        for index in stride(from: lastIndex, through: 0, by: -1) {
            if id == crumbs[index] { return index }
        }
        return -1
    }
}
