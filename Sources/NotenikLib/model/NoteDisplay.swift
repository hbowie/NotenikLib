//
//  NoteDisplay.swift
//  Notenik
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
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
            let tagsField = note.getField(label: LabelConstants.tags)
            code.append(display(tagsField!, collection: collection, io: io))
        }
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                let field = note.getField(def: def!)
                if (field != nil &&
                    field!.value.hasData &&
                    field!.def.fieldLabel.commonForm != LabelConstants.tagsCommon &&
                    field!.def.fieldLabel.commonForm != LabelConstants.dateAddedCommon &&
                    field!.def.fieldLabel.commonForm != LabelConstants.timestampCommon) {
                    code.append(display(field!, collection: collection, io: io))
                }
            }
            i += 1
        }
        if note.hasDateAdded() || note.hasTimestamp() {
            code.horizontalRule()
            let stamp = note.getField(label: LabelConstants.timestamp)
            if stamp != nil {
                code.append(display(stamp!, collection: collection, io: io))
            }
            let dateAdded = note.getField(label: LabelConstants.dateAdded)
            if dateAdded != nil {
                code.append(display(dateAdded!, collection: collection, io: io))
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
        if field.def.fieldLabel.commonForm == LabelConstants.titleCommon {
            if collection.h1Titles {
                code.heading(level: 1, text: field.value.value)
            } else {
                code.startParagraph()
                code.startStrong()
                code.append(field.value.value)
                code.finishStrong()
                code.finishParagraph()
            }
        } else if field.def.fieldLabel.commonForm == LabelConstants.tagsCommon {
            code.startParagraph()
            code.startEmphasis()
            code.append(field.value.value)
            code.finishEmphasis()
            code.finishParagraph()
        } else if field.def.fieldLabel.commonForm == LabelConstants.bodyCommon {
            if collection.bodyLabel {
                code.startParagraph()
                code.append(field.def.fieldLabel.properForm)
                code.append(": ")
                code.finishParagraph()
            }
            let md = MkdownParser(field.value.value)
            md.wikiLinkLookup = io
            md.parse()
            code.append(md.html)
            counts = md.counts
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
        } else if field.def.fieldLabel.commonForm == LabelConstants.codeCommon {
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
            MkdownParser.markdownToMarkedup(markdown: field.value.value, wikiLinkLookup: io, writer: code)
        } else if field.def.fieldType.typeString == LabelConstants.dateType {
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
