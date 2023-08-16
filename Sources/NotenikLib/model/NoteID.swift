//
//  NoteID.swift
//  Notenik
//
//  Created by Herb Bowie on 3/27/20.
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// The unique identifier for a Note.
public class NoteID: CustomStringConvertible, Equatable, Comparable {

    var source = ""
    var identifier = ""
    var fieldType: AnyType = StringType()
    
    /// Initialize without a starting value, then set the value later.
    init() {
    }
    
    /// Initialize using information from the Note.
    init(_ note: Note) {
        set(from: note)
    }
    
    var count: Int {
        return identifier.count
    }
    
    /// Return the ID. 
    public var description: String {
        return identifier
    }
    
    public func copy() -> NoteID {
        let id2 = NoteID()
        id2.source = self.source
        id2.identifier = self.identifier
        id2.fieldType = self.fieldType
        return id2
    }
    
    /// Set the ID using information from the Note.
    func set(from note: Note) {
        guard let field = note.getField(def: note.collection.idFieldDef) else {
            source = ""
            identifier = ""
            return
        }
        source = field.value.value
        identifier = StringUtils.toCommon(source)
        fieldType = field.def.fieldType
    }
    
    /// If we have a duplicate, then add a number to the end, and increment it,
    /// returning the modified value. 
    func increment() -> String {
        var char: Character = " "
        var number = 0
        var power = 1
        var index = source.endIndex
        var found = false
        if source.count > 0 {
            repeat {
                index = source.index(before: index)
                char = source.charAtOffset(index: index, offsetBy: 0)
                if let digit = char.wholeNumberValue {
                    number = number + (digit * power)
                    power = power * 10
                } else if char.isWhitespace || char.isPunctuation {
                    if number > 0 {
                        found = true
                    }
                }
            } while index > source.startIndex && char.isNumber
        }
        
        if found {
            number += 1
        } else {
            number = 1
        }
        
        var originalEnd = source.endIndex
        if found {
            originalEnd = index
        }
        let original = source[source.startIndex..<originalEnd]
        var modified = ""
        modified = "\(original)\(fieldType.idIncSep)\(number)"
        source = modified
        identifier = StringUtils.toCommon(source)
        return modified
    }
    
    func updateSource(note: Note) {
        guard let field = note.getField(def: note.collection.idFieldDef) else { return }
        field.value.set(source)
    }
    
    func display() {
        print("Source: \(source), ID: \(identifier)")
    }
    
    public static func == (lhs: NoteID, rhs: NoteID) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public static func < (lhs: NoteID, rhs: NoteID) -> Bool {
        return lhs.identifier < rhs.identifier
    }
}
