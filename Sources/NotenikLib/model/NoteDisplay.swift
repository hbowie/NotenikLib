//
//  NoteDisplay.swift
//  Notenik
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// Generate the coding necessary to display a Note in a readable format.
public class NoteDisplay: NSObject {
    
    public var format: MarkedupFormat = .htmlDoc
    
    let displayPrefs = DisplayPrefs.shared
    
    public var counts = MkdownCounts()

    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    public func display(_ note: Note, io: NotenikIO) -> String {
        let collection = note.collection
        let dict = collection.dict
        let code = Markedup(format: format)
        code.startDoc(withTitle: note.title.value, withCSS: displayPrefs.bodyCSS)
        var i = 0
        if note.hasTags() {
            let tagsField = note.getTagsAsField()
            code.append(display(tagsField!, collection: collection, io: io))
        }
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                let field = note.getField(def: def!)
                if (field != nil &&
                    field!.value.hasData &&
                        field!.def != collection.tagsFieldDef &&
                        field!.def.fieldLabel.commonForm != NotenikConstants.dateAddedCommon &&
                        field!.def.fieldLabel.commonForm != NotenikConstants.dateModifiedCommon &&
                        field!.def.fieldLabel.commonForm != NotenikConstants.timestampCommon) {
                    code.append(display(field!, collection: collection, io: io))
                }
            }
            i += 1
        }
        if note.hasDateAdded() || note.hasTimestamp() || note.hasDateModified() {
            code.horizontalRule()
            
            let stamp = note.getField(label: NotenikConstants.timestamp)
            if stamp != nil {
                code.append(display(stamp!, collection: collection, io: io))
            }
            
            let dateAdded = note.getField(label: NotenikConstants.dateAdded)
            if dateAdded != nil {
                code.append(display(dateAdded!, collection: collection, io: io))
            }
            
            let dateModified = note.getField(label: NotenikConstants.dateModified)
            if dateModified != nil {
                code.append(display(dateModified!, collection: collection, io: io))
            }
        }
        code.finishDoc()
        return String(describing: code)
    }
    
    
    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField, collection: NoteCollection, io: NotenikIO) -> String {
        let code = Markedup(format: format)
        if field.def == collection.titleFieldDef {
            if collection.h1Titles {
                code.heading(level: 1, text: field.value.value)
            } else {
                code.startParagraph()
                code.startStrong()
                code.append(field.value.value)
                code.finishStrong()
                code.finishParagraph()
            }
        } else if field.def == collection.tagsFieldDef {
            code.startParagraph()
            code.startEmphasis()
            code.append(field.value.value)
            code.finishEmphasis()
            code.finishParagraph()
        } else if field.def.fieldType.typeString == NotenikConstants.bodyCommon {
            if collection.bodyLabel {
                code.startParagraph()
                code.append(field.def.fieldLabel.properForm)
                code.append(": ")
                code.finishParagraph()
            }
            if format == .htmlDoc || format == .htmlFragment {
                let md = MkdownParser(field.value.value)
                md.wikiLinkLookup = io
                md.parse()
                code.append(md.html)
                counts = md.counts
            } else {
                code.append(field.value.value)
                code.newLine()
            }
        } else if field.def.fieldType is LinkType {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            var pathDisplay = field.value.value.removingPercentEncoding
            if pathDisplay == nil {
                pathDisplay = field.value.value
            }
            code.link(text: pathDisplay!, path: field.value.value)
            code.finishParagraph()
        } else if field.def.fieldLabel.commonForm == NotenikConstants.codeCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.codeBlock(field.value.value)
        } else if field.def.fieldType.typeString == "longtext" {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            if format == .htmlDoc || format == .htmlFragment {
                MkdownParser.markdownToMarkedup(markdown: field.value.value, wikiLinkLookup: io, writer: code)
            } else {
                code.append(field.value.value)
                code.newLine()
            }
        } else if field.def.fieldType.typeString == NotenikConstants.dateType {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            if let dateValue = field.value as? DateValue {
                code.append(dateValue.dMyWDate)
            } else {
                code.append(field.value.value)
            }
            code.finishParagraph()
        } else {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.append(field.value.value)
            code.finishParagraph()
        }

        return String(describing: code)
    }
    
}
