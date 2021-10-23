//
//  NotePointerList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/3/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A list of pointers to Notes.
public class NotePointerList: CustomStringConvertible, Collection, Sequence {

    public typealias Element = NotePointer
    
    public var list: [NotePointer] = []
    
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return list.count
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public subscript(position: Int) -> NotePointer {
        return list[position]
    }
    
    /// Use a pair of semicolons as the separator between titles.
    public var description: String {
        return value
    }
    
    public var value: String {
        var str = ""
        for pointer in list {
            str.append(pointer.title)
            str.append(";; ")
        }
        return str
    }
    
    public init() {
        
    }
    
    public func clear() {
        list = []
    }
    
    /// Examine a line of text, separating it into Note titles, with
    /// paired semicolons serving as the separators. 
    public func append(_ line: String) {
        var pendingSpaces = 0
        var semiStash = ""
        var nextTitle = ""
        for c in line {
            if c == ";" {
                semiStash.append(c)
                if semiStash == ";;" {
                    if !nextTitle.isEmpty {
                        add(title: nextTitle)
                        nextTitle = ""
                    }
                    semiStash = ""
                    pendingSpaces = 0
                }
                continue
            }
            if semiStash == ";" {
                nextTitle.append(semiStash)
                semiStash = ""
            }
            if c.isWhitespace {
                pendingSpaces += 1
                continue
            }
            if pendingSpaces > 0 {
                nextTitle.append(" ")
                pendingSpaces = 0
            }
            nextTitle.append(c)
        }
        if !nextTitle.isEmpty {
            add(title: nextTitle)
        }
    }
    
    /// Add another title, but don't allow duplicate IDs, and keep the list sorted
    /// by the lowest common denominator representation.
    /// - Parameter title: The Title of a Note.
    public func add(title: String) {
        let newPointer = NotePointer(title: title)
        var index = 0
        while index < list.count && newPointer > list[index] {
            index += 1
        }
        if index >= list.count {
            list.append(newPointer)
        } else if newPointer == list[index] {
            return
        } else {
            list.insert(newPointer, at: index)
        }
    }
    
    public func remove(title: String) {
        let pointerToRemove = NotePointer(title: title)
        var index = 0
        while index < list.count && pointerToRemove.common != list[index].common {
            index += 1
        }
        if index < list.count {
            list.remove(at: index)
        }
    }
    
    /// Factory method to return an iterator.
    public func makeIterator() -> NotePointerIterator {
        return NotePointerIterator(self)
    }
    
    /// The Iterator.
    public class NotePointerIterator: IteratorProtocol {

        public typealias Element = NotePointer
        
        var pointers: NotePointerList
        
        var index = 0
        
        public init(_ pointers: NotePointerList) {
            self.pointers = pointers
        }
        
        public func next() -> NotePointer? {
            guard index >= 0 && index < pointers.list.count else { return nil }
            let nextPointer = pointers.list[index]
            index += 1
            return nextPointer
        }
    }
    
    public func display(indentLevels: Int = 0) {
        
        StringUtils.display("\(list.count)",
                            label: "count",
                            blankBefore: true,
                            header: "NotePointerList",
                            sepLine: false,
                            indentLevels: indentLevels)
        for pointer in list {
            pointer.display(indentLevels: indentLevels + 1)
        }
    }
}