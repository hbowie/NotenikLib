//
//  NoteCrumbs.swift
//  Notenik
//
//  Created by Herb Bowie on 12/12/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
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
    
    var nextOrPriorID: NoteID?
    
    public init(io: NotenikIO) {
        self.io = io
    }
    
    /// Indicate the latest note visited by the user.
    public func select(_ selected: Note) {
        
        /// If this note is just the last one returned from this list, then
        /// leave well enough alone.
        guard crumbs.count == 0 || selected.noteID != crumbs[lastIndex] else { return }
        guard selected.noteID != nextOrPriorID else { return }
        
        let index = locate(selected.noteID)
        if index >= 0 {
            crumbs.remove(at: index)
        }
        crumbs.append(selected.noteID)
        nextOrPriorID = nil
    }
    
    /// Go back to the prior note in the breadcrumbs.
    /// - Parameter from: The Note we're starting from.
    public func backup(from: Note) -> Note {
        
        // See if we can back up within the existing breadcrumb trail.
        var index = locate(from.noteID)
        if index > 0 {
            index -= 1
            if let priorNote = io.getNote(forID: crumbs[index]) {
                nextOrPriorID = crumbs[index]
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
                nextOrPriorID = crumbs[index]
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
        crumbs = []
        nextOrPriorID = nil
        crumbs.append(id)
    }
    
    /// Let's start over.
    public func refresh() {
        crumbs = []
    }
    
    func display() {
        print("-- NoteCrumbs stack")
        for crumb in crumbs {
            print("    - \(crumb)")
        }
    }
    
    
    /// Locate the given Note ID within the list of breadcrumbs, returning -1 if not found.
    private func locate(_ id: NoteID) -> Int {
        for index in stride(from: lastIndex, through: 0, by: -1) {
            if id == crumbs[index] { return index }
        }
        return -1
    }
}
