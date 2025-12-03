//
//  IncludedByValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/1/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// Back links to other Notes with Wiki Links to this Note.
public class IncludedByValue: StringValue {
    
    public var notePointers = WikiLinkTargetList()
    
    /// Default initializer
    override init() {
        super.init()
    }
    
    /// Convenience initializer with String value
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    public override var value: String {
        get {
            return notePointers.value
        }
        set {
            set(newValue)
        }
    }
    
    /// Return the length of the string
    public override var count: Int {
        return value.count
    }
    
    /// Return the description, used as the String value for the object
    public override var description: String {
        return notePointers.value
    }
    
    /// Is this value empty?
    public override var isEmpty: Bool {
        return (notePointers.count == 0)
    }
    
    /// Does this value have any data stored in it?
    public override var hasData: Bool {
        return (notePointers.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public override var sortKey: String {
        return notePointers.value
    }
    
    
    /// Set a new value for the field..
    ///
    /// - Parameter value: The new value for the links, with paired semi-colons separating titles.
    public override func set(_ value: String) {
        notePointers.clear()
        append(value)
    }
    
    /// Append another line to the value.
    func append(_ line: String) {
        notePointers.append(line)
    }
    
    func add(noteIdBasis: String) {
        notePointers.add(noteIdBasis: noteIdBasis)
    }
    
    func remove(noteIdBasis: String) {
        notePointers.remove(noteIdBasis: noteIdBasis)
    }
    
    public func display() {
        print("IncludedByValue")
        for pointer in notePointers {
            pointer.display()
        }
    }
}
