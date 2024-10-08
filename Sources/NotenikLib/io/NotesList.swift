//
//  NotesList.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A simple list of Notes. 
public class NotesList: Sequence {

    var list = [Note]()
    
    public var count: Int {
        return list.count
    }
    
    public subscript(index: Int) -> Note {
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
    
    /// Search the list to position the index at a matching entry, or the
    /// last entry with a lower key.
    ///
    /// - Parameter sortKey: The sort key we are trying to position.
    /// - Returns: A tuple containing the index position, and a boolean to indicate whether
    ///            an exact match was found. The index will either point at the first
    ///            exact match, or the first row greater than the desired key.
    func searchList(_ note: Note) -> (Int, Bool) {
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
                if note > list[top] {
                    index = top + 1
                } else if note == list[top] {
                    exactMatch = true
                    index = top
                } else if note == list[bottom] {
                    exactMatch = true
                    index = bottom
                } else if note > list[bottom] {
                    index = top
                } else {
                    index = bottom
                }
            } else {
                let middle = bottom + ((top - bottom) / 2)
                if note == list[middle] {
                    exactMatch = true
                    done = true
                    index = middle
                } else if note > list[middle] {
                    bottom = middle + 1
                } else {
                    top = middle
                }
            }
        }
        while exactMatch && index > 0 && note == list[index - 1] && note.noteID != list[index].noteID {
            index -= 1
        }
        while exactMatch && (index + 1) < list.count && note == list[index + 1] && note.noteID != list[index].noteID {
            index += 1
        }
        return (index, exactMatch)
    }
    
    public func append(_ note: Note) {
        list.append(note)
    }
    
    func insert(_ note: Note, at: Int) {
        list.insert(note, at: at)
    }
    
    func remove(at: Int) {
        list.remove(at: at)
    }
    
    func sort() {
        list.sort()
    }
    
    public func makeIterator() -> NotesList.Iterator {
        return Iterator(self)
    }
    
    public class Iterator: IteratorProtocol {
        
        public typealias Element = Note
        
        var list: NotesList!
        var index = 0
        
        init(_ list: NotesList) {
            self.list = list
        }
        
        public func next() -> Note? {
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

