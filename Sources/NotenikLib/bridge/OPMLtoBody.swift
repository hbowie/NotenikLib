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
    var elementChars = SolidString()
    var title = ""
    var headTitle = ""
    var firstH1 = ""
    var h1Count = 0
    
    var usingHeadings = true
    
    public override init() {
        super.init()
        decoder.addXMLDecode()
    }
    
    /// Import an OPML outline from the given file.
    /// - Parameters:
    ///   - fileURL: The URL pointing to the outline file.
    ///   - defaultTitle: The default title for the Note.
    ///   - usingHeadings: Generate headings? If not, generate list items.
    /// - Returns: The body for the Note, plus the title for the Note.
    public func importFrom(_ fileURL: URL, defaultTitle: String, usingHeadings: Bool = true) -> (String, String) {
        markedUp = Markedup(format: .markdown)
        title = defaultTitle
        self.usingHeadings = usingHeadings
        h1Count = 0
        firstH1 = ""
        if usingHeadings {
            markedUp.writeLine("{:outline-headings}")
        } else {
            markedUp.writeLine("{:outline-bullets}")
            markedUp.startUnorderedList(klass: nil)
        }
        let parser = XMLParser(contentsOf: fileURL)!
        parser.delegate = self
        level = 0
        let success = parser.parse()
        if !success {
            logError("XML Parser ran into problems")
        }
        if !headTitle.isEmpty {
            title = headTitle
        } else if h1Count == 1 {
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
        
        elementChars = SolidString()
        switch elementName {
        case "outline":
            handleOutlineElement(attributes: attributeDict)
        case "title":
            headTitle = ""
        default:
            break
        }
    }
    
    func handleOutlineElement(attributes attributeDict: [String : String] = [:]) {
        
        level += 1
        var indent = ""
        
        guard let rawText = attributeDict["text"] else { return }
        let text = decoder.convert(from: rawText)
        if usingHeadings {
            markedUp.heading(level: level, text: text)
            if level == 1 {
                h1Count += 1
                if h1Count == 1 {
                    firstH1 = text
                }
            }
        } else {
            markedUp.ensureBlankLine()
            markedUp.startListItem(level: level)
            markedUp.append(text)
            markedUp.finishListItem()
            markedUp.ensureNewLine()
            if level > 0 {
                indent = String(repeating: " ", count: ((level) * 4))
            }
        }

        for (label, value) in attributeDict {
            let decoded = decoder.convert(from: value)
            switch label {
            case "text":
                break
            case "_note", "note":
                markedUp.ensureBlankLine()
                markedUp.append(indent)
                markedUp.writeLine(decoded)
                markedUp.ensureBlankLine()
            default:
                markedUp.ensureBlankLine()
                markedUp.append(indent)
                markedUp.writeLine("\(label): \(decoded)")
                markedUp.ensureBlankLine()
            }
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters: String) {
        elementChars.append(foundCharacters)
    }
    
    /// End an element.
    public func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        
        switch elementName {
        case "outline":
            level -= 1
        case "title":
            if !elementChars.isEmpty {
                headTitle = elementChars.str
            }
        default:
            break
        }
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "OPMLImporter",
                          level: .error,
                          message: msg)
    }
        
}
