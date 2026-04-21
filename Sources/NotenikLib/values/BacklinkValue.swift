//
//  BacklinkValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/2/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// Back links to other Notes with Wiki Links to this Note. 
public class BacklinkValue: StringValue, MultiValues {
    
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
    
    
    /// Set a new value for the tags.
    ///
    /// - Parameter value: The new value for the links, with paired semi-colons separating titles.
    public override func set(_ value: String) {
        notePointers.clear()
        if value.contains(";;") {
            appendLine(value)
        } else {
            append(value)
        }
    }
    
    /// Append another line to the value.
    func appendLine(_ line: String) {
        notePointers.appendLine(line)
    }
    
    func add(noteIdBasis: String) {
        notePointers.add(noteIdBasis: noteIdBasis)
    }
    
    func remove(noteIdBasis: String) {
        notePointers.remove(noteIdBasis: noteIdBasis)
    }
    
    public func display() {
        print("BackLinkValue")
        for pointer in notePointers {
            pointer.display()
        }
    }
    
    //
    // The following constants, variables and functions provide conformance to the MultiValues protocol.
    //
    
    public let multiDelimiter = ";;"
    
    public var multiCount: Int {
        return notePointers.count
    }
    
    /// Return a sub-value at the given index position.
    /// - Returns: The indicated sub-value, for a valid index, otherwise nil.
    public func multiAt(_ index: Int) -> String? {
        guard index >= 0 else { return nil }
        guard index < multiCount else { return nil }
        return notePointers[index].pathSlashID
    }
    
    public func append(_ str: String) {
        notePointers.add(noteIdBasis: str)
    }
    
}
