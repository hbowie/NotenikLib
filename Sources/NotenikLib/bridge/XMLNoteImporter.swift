//
//  XMLNoteImporter.swift
//
//  Created by Herb Bowie on 6/7/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Imports Notes from an XML file.
public class XMLNoteImporter: NSObject, XMLParserDelegate {
    
    let fileManager = FileManager.default
    
    let decoder = StringConverter()
    
    var io: NotenikIO
    
    var note: Note?
    
    var labels: [String] = []

    var currentLabel: String {
        if labels.count < 1 {
            return ""
        } else {
            return labels[labels.count - 1]
        }
    }
    
    var parentLabel: String {
        if labels.count < 2 {
            return ""
        } else {
            return labels[labels.count - 2]
        }
    }
    
    var grandparentLabel: String {
        if labels.count < 3 {
            return ""
        } else {
            return labels[labels.count - 3]
        }
    }
    
    var value = ""
    
    var tagsValue = ""
    
    var bodyValue = ""
    
    var valueBeforeBreak = ""
    
    var followingBreak = false
    
    var notesImported = 0
    
    public init(io: NotenikIO) {
        self.io = io
        super.init()
        decoder.addXMLDecode()
    }
    
    /// Read XML from either a specific file or a folder containing subfolders and files.
    public func importFrom(_ fileURL: URL) -> Int {
        notesImported = 0
        if FileUtils.isDir(fileURL.path) {
            scanFolderForXML(fileURL)
        } else {
            importXMLfromFile(fileURL)
        }
        return notesImported
    }
    
    /// Go through the given folder looking for subfolders and XML files.
    func scanFolderForXML(_ folderURL: URL) {
         do {
             let folderPath = folderURL.path
             let dirContents = try
                 fileManager.contentsOfDirectory(atPath: folderPath)
             for itemPath in dirContents {
                 let itemFullPath = FileUtils.joinPaths(path1: folderPath, path2: itemPath)
                 let itemURL = URL(fileURLWithPath: itemFullPath)
                 if itemPath.hasPrefix(".") {
                     // Skip dot files
                 } else if FileUtils.isDir(itemFullPath) {
                     switch itemPath {
                     case "backups":
                         break
                     case "export":
                         break
                     default:
                         scanFolderForXML(itemURL)
                     }
                 } else if itemPath.hasSuffix(".xml") {
                     if itemPath != "header.xml" {
                         importXMLfromFile(itemURL)
                     }
                 }
             }
         } catch let error {
             logError("Failed reading contents of directory: \(error)")
             return
         }
     }
      
     /// Parse an XML file.
     func importXMLfromFile(_ fileURL: URL) {
         guard let parser = XMLParser(contentsOf: fileURL) else {
             logError("Could not get an XML Parser for file at \(fileURL.path)")
             return
         }
         parser.delegate = self
         let ok = parser.parse()
         if !ok {
             logError("Trouble parsing XML file at: \(fileURL.path)")
         }
     }
    
    /// Starting a new XML doc.
    public func parserDidStartDocument(_ parser: XMLParser) {
        // Nothing to do here.
    }
    
    /// Starting a new XML field (aka element).
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let nameLower = elementName.lowercased()
        labels.append(nameLower)
        switch currentLabel {
        case "br":
            valueBeforeBreak = value
        case "em":
            value.append("*")
        case "item", "note":
            note = Note(collection: io.collection!)
        case "category", "categories", "tags":
            tagsValue = ""
        case "body":
            bodyValue = ""
        default:
            break
        }
        if currentLabel != "em" {
            value = ""
        }
        followingBreak = false
    }
    
    /// Found some characters expected to be part of a value.
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if followingBreak {
            value.append(trim(string))
            followingBreak = false
        } else {
            value.append(string)
        }
    }
    
    /// Ending an XML field/element.
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        value = trim(value)
        value = decoder.convert(from: value)
        guard note != nil else {
            return
        }
        let label = elementName.lowercased()
        switch label {
        case "body":
            if bodyValue.count > 0 {
                _ = note!.setBody(bodyValue)
            }
        case "br":
            value = valueBeforeBreak + "  \n"
            followingBreak = true
        case "category", "categories", "tags":
            if tagsValue.count > 0 {
                _ = note!.setTags(tagsValue)
            } else if value.count > 0 {
                _ = note!.setTags(value)
            }
        case "date":
            if value.count > 0 {
                _ = note!.setDate(value)
            }
        case "em":
            value.append("*")
        case "link":
            if value.count > 0 {
                _ = note!.setLink(value)
            }
        case "item", "note":
            if note!.hasTitle() {
                let (addedNote, _) = io.addNote(newNote: note!)
                if addedNote != nil {
                    notesImported += 1
                }
            }
        case "name":
            if parentLabel == "author" {
                _ = note!.setAuthor(value)
            }
        case "seq":
            if value.count > 0 {
                _ = note!.setSeq(value)
            }
        case "status":
            if value.count > 0 {
                _ = note!.setStatus(value)
            }
        case "p":
            if value.count > 0 {
                if parentLabel == "body" || grandparentLabel == "body" {
                    if bodyValue.count > 0 {
                        bodyValue.append("\n\n")
                    }
                    bodyValue.append(value)
                }
            }
        case NotenikConstants.titleCommon:
            if parentLabel != "source" {
                _ = note!.setTitle(value)
            }
        default:
            if label.hasPrefix("tag") || label.hasPrefix("category") {
                if value.count > 0 {
                    if tagsValue.count > 0 {
                        tagsValue.append("; ")
                    }
                    tagsValue.append(value)
                }
            }
        }
        
        if label != "br" && label != "em" {
            value = ""
        }
        if label == currentLabel {
            labels.remove(at: labels.count - 1)
        }
    }
    
    /// Report an error detected by the XML parser.
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        logError("XML Parser error occurred: \(parseError)")
    }
    
    /// Ending an XML doc.
    public func parserDidEndDocument(_ parser: XMLParser) {
        // Nothing to do here.
    }
    
    func trim(_ str: String) -> String {
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "XMLReader",
                          level: .error,
                          message: msg)
    }
}
