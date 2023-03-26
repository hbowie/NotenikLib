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

/// Back links to other Notes with Wiki Links to this Note. 
public class BacklinkValue: StringValue {
    
    public var notePointers = NotePointerList()
    
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
    override var hasData: Bool {
        return (notePointers.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return notePointers.value
    }
    
    
    /// Set a new value for the tags.
    ///
    /// - Parameter value: The new value for the links, with paired semi-colons separating titles.
    override func set(_ value: String) {
        notePointers.clear()
        append(value)
    }
    
    /// Append another line to the value.
    func append(_ line: String) {
        notePointers.append(line)
    }
    
    func add(title: String) {
        notePointers.add(title: title)
    }
    
    func remove(title: String) {
        notePointers.remove(title: title)
    }
    
    public func display() {
        print("BackLinkValue")
        for pointer in notePointers {
            pointer.display()
        }
    }
}
