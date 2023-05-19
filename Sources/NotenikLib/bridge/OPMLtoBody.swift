//
//  OPMLtoBody.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/18/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class OPMLtoBody: NSObject, XMLParserDelegate {
        
    var level = 0
    
    let decoder = StringConverter()
    
    var markedUp = Markedup(format: .markdown)
    var title = ""
    var firstH1 = ""
    var h1Count = 0
    
    public override init() {
        super.init()
        decoder.addXMLDecode()
    }
    
    /// Import an OPML outline from the given file.
    /// - Parameters:
    ///   - fileURL: The URL pointing to the outline file.
    ///   - defaultTitle: The default title for the Note.
    /// - Returns: The body for the Note, plus the title for the Note.
    public func importFrom(_ fileURL: URL, defaultTitle: String) -> (String, String) {
        markedUp = Markedup(format: .markdown)
        title = defaultTitle
        h1Count = 0
        firstH1 = ""
        markedUp.writeLine("{:outline}")
        let parser = XMLParser(contentsOf: fileURL)!
        parser.delegate = self
        level = 0
        let success = parser.parse()
        if !success {
            logError("XML Parser ran into problems")
        }
        if h1Count == 1 {
            title = firstH1
        }
        return (markedUp.code, title)
    }
    
    /// Start a new element.
    public func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        
        guard elementName == "outline" else { return }
        
        level += 1
        
        for (label, value) in attributeDict {
            let decoded = decoder.convert(from: value)
            switch label {
            case "text":
                markedUp.heading(level: level, text: decoded)
                if level == 1 {
                    h1Count += 1
                    if h1Count == 1 {
                        firstH1 = decoded
                    }
                }
            case "_note", "note":
                markedUp.writeLine(decoded)
            default:
                markedUp.writeLine("\(label): \(decoded)")
            }
        }
    }
    
    /// End an element.
    public func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        
        guard elementName == "outline" else { return }
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
