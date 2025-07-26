//
//  NotesList.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A (not so) simple list of Notes.
public class NotesList: Sequence {

    var list: [SortedNote] = []
    
    public var count: Int {
        return list.count
    }
    
    public subscript(index: Int) -> SortedNote {
        get {
            return list[index]
        }
        set {
            list[index] = newValue
        }
    }
    
    public init() {
        
    }
    
    public func copy() -> NotesList {
        let list2 = NotesList()
        list2.list = self.list
        return list2
    }
    
    public func add(note: Note) -> (Int, [SortedNote]) {
        var sNotes: [SortedNote] = []
        let sNote = SortedNote(note: note, seqIndex: 0)
        var listIndex = 0
        listIndex = add(sortedNote: sNote)
        sNotes.append(sNote)
        guard note.collection.seqFieldDef != nil else { return (listIndex, sNotes) }
        var j = 1
        while j < note.seq.multiCount {
            let sNote2 = SortedNote(note: note, seqIndex: j)
            _ = add(sortedNote: sNote2)
            sNotes.append(sNote2)
            j += 1
        }
        return (listIndex, sNotes)
    }
    
    public func add(sortedNote: SortedNote) -> Int {
        var listIndex = 0
        let (index, _) = searchList(sortedNote)
        if index < 0 {
            insert(sortedNote, at: 0)
            listIndex = 0
        } else if index >= count {
            listIndex = count
            append(sortedNote)
        } else {
            insert(sortedNote, at: index)
            listIndex = index
        }
        return listIndex
    }
    
    public func delete(note: Note) -> [SortedNote] {
        var sNotes: [SortedNote] = []
        let sNote = SortedNote(note: note, seqIndex: 0)
        
        let (index, found) = searchList(sNote)
        if found {
            sNotes.append(sNote)
            remove(at: index)
        }
        
        guard note.collection.seqFieldDef != nil else { return sNotes }
        var j = 1
        while j < note.seq.multiCount {
            let sNote2 = SortedNote(note: note, seqIndex: j)
            let (index2, found2) = searchList(sNote2)
            if found2 {
                sNotes.append(sNote2)
                remove(at: index2)
            }
            j += 1
        }
        return sNotes
    }
    
    /// Search the list to position the index at a matching entry, or the
    /// last entry with a lower key.
    ///
    /// - Parameter sortKey: The sort key we are trying to position.
    /// - Returns: A tuple containing the index position, and a boolean to indicate whether
    ///            an exact match was found. The index will either point at the first
    ///            exact match, or the first row greater than the desired key.
    func searchList(_ note: Note, seqIndex: Int = 0) -> (Int, Bool) {
        let sNote = SortedNote(note: note, seqIndex: seqIndex)
        return searchList(sNote)
    }
    
    /// Search the list to position the index at a matching entry, or the
    /// last entry with a lower key.
    ///
    /// - Parameter sortKey: The sort key we are trying to position.
    /// - Returns: A tuple containing the index position, and a boolean to indicate whether
    ///            an exact match was found. The index will either point at the first
    ///            exact match, or the first row greater than the desired key.
    func searchList(_ sortedNote: SortedNote) -> (Int, Bool) {
        var index = 0
        var exactMatch = false
        var bottom = 0
        var top = list.count - 1
        var done = false
        while !done {
            if bottom > top {
                done = true
                index = bottom
            } else if top == bottom || top == (bottom + 1) {
                done = true
                if sortedNote > list[top] {
                    index = top + 1
                } else if sortedNote == list[top] {
                    exactMatch = true
                    index = top
                } else if sortedNote == list[bottom] {
                    exactMatch = true
                    index = bottom
                } else if sortedNote > list[bottom] {
                    index = top
                } else {
                    index = bottom
                }
            } else {
                let middle = bottom + ((top - bottom) / 2)
                if sortedNote == list[middle] {
                    exactMatch = true
                    done = true
                    index = middle
                } else if sortedNote > list[middle] {
                    bottom = middle + 1
                } else {
                    top = middle
                }
            }
        }
        while exactMatch && index > 0 && sortedNote == list[index - 1] && sortedNote.noteID != list[index].noteID {
            index -= 1
        }
        while exactMatch && (index + 1) < list.count && sortedNote == list[index + 1] && sortedNote.noteID != list[index].noteID {
            index += 1
        }
        return (index, exactMatch)
    }
    
    public func append(_ note: Note, seqIndex: Int = 0) {
        let sNote = SortedNote(note: note, seqIndex: seqIndex)
        append(sNote)
        appendDupes(note: note)
    }
    
    public func append(_ sortedNote: SortedNote) {
        list.append(sortedNote)
    }
    
    func insert(_ note: Note, at: Int, seqIndex: Int = 0) {
        let sNote = SortedNote(note: note, seqIndex: seqIndex)
        insert(sNote, at: at)
    }
    
    func insert(_ sortedNote: SortedNote, at: Int) {
        list.insert(sortedNote, at: at)
    }
    
    func remove(at: Int) {
        list.remove(at: at)
    }
    
    func sort() {
        preSort()
        list.sort()
    }
    
    func preSort() {
        
        // See if we have prerequisites satisfied.
        guard !list.isEmpty else { return }
        let collection = list[1].note.collection
        
        // First, go through and remove any duplicates, and regen sort keys.
        var i = 0
        while i < list.count {
            if list[i].seqIndex > 0 {
                list.remove(at: i)
            } else {
                list[i].genSortKey()
                i += 1
            }
        }
        
        // Now generate duplicates when appropriate.
        guard collection.seqFieldDef != nil else { return }
        guard collection.sortParm.seqSorting else { return }
        i = 0
        while i < list.count {
            let nextSorted = list[i]
            if nextSorted.seqIndex == 0 && nextSorted.note.seq.multiCount > 1 {
                appendDupes(note: nextSorted.note)
            }
            i += 1
        }
    }
    
    func appendDupes(note: Note) {
        guard note.collection.seqFieldDef != nil else { return }
        let seq = note.seq
        var j = 1
        while j < seq.multiCount {
            let dupe = SortedNote(note: note, seqIndex: j)
            list.append(dupe)
            j += 1
        }
    }
    
    public func makeIterator() -> NotesList.Iterator {
        return Iterator(self)
    }
    
    public class Iterator: IteratorProtocol {
        
        public typealias Element = SortedNote
        
        var list: NotesList!
        var index = 0
        
        init(_ list: NotesList) {
            self.list = list
        }
        
        public func next() -> SortedNote? {
            if index < 0 || index >= list.count {
                return nil
            } else {
                let currIndex = index
                index += 1
                return list[currIndex]
            }
        }
        
    }
}

