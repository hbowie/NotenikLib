//
//  OPMLImporter.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/4/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class OPMLImporter: NSObject, XMLParserDelegate {
    
    var io: NotenikIO
    
    var notesImported = 0
    
    var depth = 0
    var depthIndent: String {
        return String(repeating: " ", count: depth * 2)
    }
    var level = 0
    var seqs: [Int] = [0]
    
    let decoder = StringConverter()
    
    public init(io: NotenikIO) {
        self.io = io
        super.init()
        decoder.addXMLDecode()
    }
    
    /// Read XML from either a specific file or a folder containing subfolders and files.
    public func importFrom(_ fileURL: URL) -> Int {
        notesImported = 0
        let parser = XMLParser(contentsOf: fileURL)!
        parser.delegate = self
        let success = parser.parse()
        if !success {
            logError("XML Parser ran into problems")
        }
        return notesImported
    }
    
    /// Start a new element.
    public func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        
        depth += 1
        
        guard elementName == "outline" else { return }
        
        level += 1
        
        while seqs.count < level {
            seqs.append(0)
        }
        seqs[level - 1] += 1
        var seqStr = ""
        for i in 0 ..< level {
            if seqStr.count > 0 {
                seqStr.append(".")
            }
            seqStr.append("\(seqs[i])")
        }
        
        let note = Note(collection: io.collection!)
        _ = note.setSeq(seqStr)
        _ = note.setLevel("\(level)")
        
        for (label, value) in attributeDict {
            let decoded = decoder.convert(from: value)
            switch label {
            case "category":
                _ = note.setTags(decoded)
            case "created":
                _ = note.setDateAdded(decoded)
            case "description":
                _ = note.setBody(decoded)
            case "htmlUrl":
                _ = note.setLink(decoded)
            case "url":
                _ = note.setLink(decoded)
            case "text":
                _ = note.setTitle(decoded)
            case "_note":
                _ = note.setBody(decoded)
            default:
                _ = note.setField(label: label, value: decoded)
            }
        }
        
        if note.hasTitle() {
            let (addedNote, _) = io.addNote(newNote: note)
            if addedNote != nil {
                notesImported += 1
            }
        }
    }
    
    /// End an element.
    public func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        depth -= 1
        
        guard elementName == "outline" else { return }
        
        if level < seqs.count {
            seqs[level] = 0
        }
        
        level -= 1
        
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "OPMLImporter",
                          level: .error,
                          message: msg)
    }
}
