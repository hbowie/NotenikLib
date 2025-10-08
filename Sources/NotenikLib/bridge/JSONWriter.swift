//
//  JSONWriter.swift
//  Notenik
//
//  Created by Herb Bowie on 12/19/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Write notes, or general data content, to a JSON file.
public class JSONWriter {
    
    /// The output writer to use.
    var writer: LineWriter = BigStringWriter()
    
    var indentLevel = 0
    var indent = ""
    var startOfLine = true
    var lineCount = 0
    
    var openElements = OpenElements()
    
    // -----------------------------------------------------------
    //
    // MARK: Init, Open, Close, Save, Output.
    //
    // -----------------------------------------------------------
    
    public init() {
        
    }
    
    /// Open the writer. This must always be performed once, before any writes occur.
    public func open() {
        writer.open()
        indentLevel = 0
        indent = ""
        lineCount = 0
        startOfLine = true
        openElements = OpenElements()
    }
    
    /// Close the writer. This must always be done once, after all writes have occurred.
    public func close() {
        writer.close()
    }
    
    /// Save the output to a file; this should follow the call to the close method.
    public func save(destination: URL) -> Bool {
        do {
            try outputString.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "JSONWriter",
                              level: .error,
                              message: "Problem writing JSON to disk at \(destination)")
            return false
        }
        return true
    }
    
    /// Retrieve the output string after open, writing and close.
    public var outputString: String {
        guard writer is BigStringWriter else { return "" }
        let big = writer as! BigStringWriter
        return big.bigString
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generalized Note handling.
    //
    // -----------------------------------------------------------
    
    /// Format an entire collection of notes as one big JSON object.
    func write(_ io: NotenikIO) {
        guard let collection = io.collection else { return }
        startObject()
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            writeKey(sortedNote!.note.noteID.commonID)
            startObject()
            let defs = collection.dict.list
            for def in defs {
                let value = sortedNote!.note.getFieldAsValue(label: def.fieldLabel.commonForm)
                if value.count > 0 {
                    writeKey(def.fieldLabel.properForm)
                    writeValue(value.value)
                }
            }
            endObject()
            (sortedNote, position) = io.nextNote(position)
        }
        endObject()
    }
    
    /// Write out the given note as a complete JSON object. 
    public func writeNoteAsObject(_ note: Note) {
        let collection = note.collection
        let dict = collection.dict
        startObject()
        for def in dict.list {
            write(key: def.fieldLabel.properForm,
                  value: note.getFieldAsString(label: def.fieldLabel.commonForm))
        }
        endObject()
    }
    
    /// Write out the given note's body as a complete JSON object.
    public func writeBodyAsObject(_ note: Note) {
        startObject()
        write(key: NotenikConstants.body,
              value: note.getFieldAsString(label: NotenikConstants.body))
        endObject()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generalized JSON output.
    //
    // -----------------------------------------------------------
    
    /// Start the specification of an object.
    func startObject(withKey: String? = nil) {

        var label = "startObject"
        if withKey != nil && !withKey!.isEmpty {
            label.append(" with key of \"\(withKey!)\"")
        }
        writeCommaIfNotFirst(label: label)
        if !startOfLine {
            endLine()
        }
        var needSpace = true
        if startOfLine {
            startLine()
            needSpace = false
        }
        if withKey != nil && !withKey!.isEmpty {
            writeKeyOnly(withKey!)
            needSpace = true
        }
        if needSpace {
            write(" ")
        }
        write("{")
        endLine()
        increaseIndent()
        openElements.anotherItem()
        openElements.openNew(compoundType: "{")
    }
    
    /// End the specification of an object.
    func endObject() {
        endLine()
        decreaseIndent()
        startLine()
        write("}")
        openElements.removeLast()
    }
    
    /// Start the specification of an array..
    func startArray(withKey: String? = nil) {
        
        var label = "startArray"
        if withKey != nil && !withKey!.isEmpty {
            label.append(" with key of \"\(withKey!)\"")
        }
        
        writeCommaIfNotFirst(label: label)
        if !startOfLine {
            endLine()
        }
        var needSpace = true
        if startOfLine {
            startLine()
            needSpace = false
        }
        if withKey != nil && !withKey!.isEmpty {
            writeKeyOnly(withKey!)
            needSpace = true
        }
        if needSpace {
            write(" ")
        }
        write("[")
        endLine()
        increaseIndent()
        openElements.anotherItem()
        openElements.openNew(compoundType: "[")
    }
    
    /// End the specification of an Array.
    func endArray() {
        endLine()
        decreaseIndent()
        startLine()
        write("]")
        openElements.removeLast()
    }
    
    /// Write out a key and its associated value.
    func write(key: String, value: String, withComma: Bool = false) {
        writeKey(key)
        writeValue(value)
    }
    
    func write(key: String, value: UInt64, withComma: Bool = false) {
        writeKey(key)
        writeValue(value)
    }
    
    /// Write out a key identifying the field with its label.
    func writeKey(_ key: String) {
        let label = "writeKey with key of \"\(key)\""
        writeCommaIfNotFirst(label: label)
        if !startOfLine {
            endLine()
        }
        startLine()
        let keyCountTarget = 13
        write("\"\(key)\"")
        var keyCount = key.count
        repeat {
            write(" ")
            keyCount += 1
        } while keyCount < keyCountTarget
        write(":")
        anotherItem()
    }
    
    func writeKeyOnly(_ key: String) {
        let keyCountTarget = 13
        write("\"\(key)\"")
        var keyCount = key.count
        repeat {
            write(" ")
            keyCount += 1
        } while keyCount < keyCountTarget
        write(":")
    }
    
    /// Write out the value associated with the preceding key.
    func writeValue(_ value: String) {
        if !startOfLine {
            write(" ")
        }
        write("\"\(encodedString(value))\"")
    }
    
    /// Write out the value associated with the preceding key.
    func writeValue(_ value: UInt64) {
        if !startOfLine {
            write(" ")
        }
        write("\(value)")
    }
    
    /// Replace verboten characters with escaped equivalents.
    func encodedString(_ str: String) -> String {
        var v = str
        var i = v.startIndex
        for c in v {
            if c.isNewline {
                v.remove(at: i)
                v.insert("\\", at: i)
                i = v.index(after: i)
                v.insert("n", at: i)
            } else if c == "\t" {
                v.remove(at: i)
                v.insert("\\", at: i)
                i = v.index(after: i)
                v.insert("t", at: i)
            } else if c == "\"" || c == "\\" {
                v.insert("\\", at: i)
                i = v.index(after: i)
            }
            i = v.index(after: i)
        }
        return v
    }
    
    func writeCommaIfNotFirst(label: String? = nil) {
        if !startOfLine && openElements.notTheFirst {
            writeComma()
        }
    }
    
    func writeComma() {
        write(",")
        endLine()
    }
    
    func anotherItem() {
        openElements.anotherItem()
    }
    
    /// Bump up the indentation by 1 notch.
    func increaseIndent() {
        indentLevel += 1
        indent = String(repeating: " ", count: indentLevel * 2)
    }
    
    /// Bump the indentation back down by 1 notch.
    func decreaseIndent() {
        indentLevel -= 1
        indent = String(repeating: " ", count: indentLevel * 2)
    }
    
    /// Start a line by writing out the appropriate indentation.
    func startLine() {
        guard startOfLine else {
            return
        }
        write(indent)
        startOfLine = false
    }
    
    /// Write some text to the current line.
    func write(_ str: String) {
        writer.write(str)
        startOfLine = false
    }
    
    /// End the current line.
    func endLine() {
        if !startOfLine {
            writer.endLine()
            startOfLine = true
        }
    }
    
    class OpenElements {
        var openElements: [CompoundElement] = []
        
        var notTheFirst: Bool {
            guard !openElements.isEmpty else {
                return false
            }
            return openElements[openElements.count - 1].containedItems > 0
        }
        
        func openNew(compoundType: Character) {
            let newElement = CompoundElement(compoundType: compoundType)
            openElements.append(newElement)
        }
        
        func anotherItem() {
            guard openElements.count > 0 else {
                return
            }
            openElements[openElements.count - 1].containedItems += 1
        }
        
        func removeLast() {
            _ = openElements.removeLast()
        }
        
        func display() {
            print("    JSONWriter.OpenElements.display")

            var count = 0
            for element in openElements {
                count += 1
                print("      - \(count). type = \(element.compoundType), # of items = \(element.containedItems)")
            }
        }
    }
    
    class CompoundElement {
        var compoundType: Character = "{"
        var containedItems = 0
        
        init(compoundType: Character) {
            self.compoundType = compoundType
        }
    }
    
}
