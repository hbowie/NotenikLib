//
//  SearchNotes.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/23/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Class to search Notes within a Collection for a specific string.
public class SearchNotes {
    
    public var options = SearchOptions()
    var history:  NavHistory!
    var io:       NotenikIO!
    
    var prevSearchText = ""
    
    var starting = true
    
    var startingNote: Note?
    var startingPosition = NotePosition()
    
    /// Initialize a new instance.
    /// - Parameter io: The I/O module to be used.
    public init(io: NotenikIO) {
        self.io = io
        history = NavHistory(io: io)
    }
    
    /// See if the user has altered the text to be searched for.
    /// - Parameter str: Text input by the user. 
    public func checkUserInput(str: String) {
        if !str.isEmpty && str != searchText {
            searchText = str
        }
    }
    
    /// Get or Set the text to search for.
    public var searchText: String {
        get {
            return options.searchText
        }
        set {
            options.searchText = newValue
        }
    }
    
    /// Do we have any text to search for?
    public var hasText: Bool {
        return !options.searchText.isEmpty
    }
    
    public var scope: SearchOptions.SearchScope {
        get {
            return options.scope
        }
        set {
            options.scope = newValue
        }
    }
    
    /// Find the next matchig note.
    /// - Parameter startNew: Are we definitely starting a new search?
    /// - Returns: The next matching note, if any, plus its position.
    public func nextMatching(startNew: Bool) -> (Note?, NotePosition) {
        
        starting = false
        if startNew || prevSearchText.isEmpty || options.searchText != prevSearchText {
            starting = true
            clearHistory()
        }
        
        prevSearchText = options.searchText
        
        var found = false
        var (note, position) = firstToSearch()
        while !found && note != nil {
            found = searchNoteUsingOptions(note!)
            if !found {
                (note, position) = io.nextNote(position)
            }
        }
        if found && options.scope == .within && !note!.seq.value.starts(with: options.anchorSeq) {
            found = false
        }
        if found {
            history!.addToHistory(another: note!)
            return (note, position)
        } else {
            return (nil, NotePosition())
        } 
    }
    
    /// Clear the search history.
    public func clearHistory() {
        history.clear()
    }
    
    /// Return the note with which we will start our next search.
    /// - Returns: The next note to check, if any available, plus its position.
    func firstToSearch() -> (Note?, NotePosition) {
        var note: Note?
        var position = NotePosition()
        
        if starting {
            options.anchorSeq = ""
            options.anchorSortKey = ""
            if options.scope == .all {
                return io.firstNote()
            }
            (note, position) = io.getSelectedNote()
            if note == nil {
                return io.firstNote()
            } 
            options.anchorSortKey = note!.sortKey
            options.anchorSeq = note!.seq.value
        } else {
            (note, position) = io.getSelectedNote()
            if note != nil {
                startingNote = note
                startingPosition = position
                (note, position) = io.nextNote(position)
            }
        }

        return (note, position)
    }
    
    /// If we couldn't find another Note, then let's return to where we last started looking.
    /// - Returns: The starting note, if one could be found, plus its position. 
    public func backToStart() -> (Note?, NotePosition) {
        if startingNote != nil {
            return (startingNote, startingPosition)
        } else {
            return io.firstNote()
        }
    }
    
    /// Go backwards in the search history.
    /// - Returns: A possible prior Note obtained from the search history. 
    public func searchForPrevious() -> Note? {
        var (note, position) = io.getSelectedNote()
        guard note != nil else { return note }
        startingNote = note!
        startingPosition = position
        note = history.backwards(from: startingNote!)
        return note
    }
    
    /// Search the fields of this Note, using search options, to see if a
    /// selected field contains the search string.
    /// - Parameter note: The note whose fields are to be searched.
    /// - Returns: True if we found a match; false otherwise.
    func searchNoteUsingOptions(_ note: Note) -> Bool {
        var searchFor = options.searchText
        if !options.caseSensitive {
            searchFor = options.searchText.lowercased()
        }
        var matched = false
        
        matched = searchOneFieldUsingOptions(fieldSelected: options.hashTag,
                                             noteField: note.tags.value,
                                             searchFor: searchFor)
        if options.hashTag {
            return matched
        }
        
        matched = searchOneFieldUsingOptions(fieldSelected: options.titleField,
                                             noteField: note.title.value,
                                             searchFor: searchFor)
        if matched { return true }
        
        if note.collection.akaFieldDef != nil {
            matched = searchOneFieldUsingOptions(fieldSelected: options.akaField,
                                                 noteField: note.aka.value,
                                                 searchFor: searchFor)
            if matched { return true }
        }
        
        matched = searchOneFieldUsingOptions(fieldSelected: options.tagsField,
                                             noteField: note.tags.value,
                                             searchFor: searchFor)
        if matched { return true }
        
        matched = searchOneFieldUsingOptions(fieldSelected: options.linkField,
                                             noteField: note.link.value,
                                             searchFor: searchFor)
        if matched { return true }
        
        matched = searchOneFieldUsingOptions(fieldSelected: options.authorField,
                                             noteField: note.author.value,
                                             searchFor: searchFor)
        if matched { return true }
        
        matched = searchOneFieldUsingOptions(fieldSelected: options.bodyField,
                                             noteField: note.body.value,
                                             searchFor: searchFor)

        return matched
    }
    
    /// Check next Note field to see if it meets the search criteria.
    /// - Parameters:
    ///   - fieldSelected: Did the user select this field for comparison purposes?
    ///   - noteField: The String value from the Note field.
    ///   - searchFor: The String value we're looking for (lowercased if case-insensitive)
    /// - Returns: True if a match, false otherwise.
    func searchOneFieldUsingOptions(fieldSelected: Bool,
                                    noteField: String,
                                    searchFor: String) -> Bool {
        
        guard fieldSelected else { return false }
        var noteFieldToCompare = noteField
        if !options.caseSensitive {
            noteFieldToCompare = noteField.lowercased()
        }
        return noteFieldToCompare.contains(searchFor)
    }
    
}
