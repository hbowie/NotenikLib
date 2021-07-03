//
//  NoteFieldsToHTML.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/15/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// Generate the coding necessary to display a Note in a readable format.
public class NoteFieldsToHTML
    // NSObject - Not sure why I needed this???
    {
    
    public var format: MarkedupFormat = .htmlDoc
    
    var displayPrefs: DisplayPrefs?
    
    var bodyHTML: String?
    
    var streamlined = false
    
    var minutesToRead: MinutesToReadValue?
    
    public init() {
        
    }
    
    public init(displayPrefs: DisplayPrefs) {
        self.displayPrefs = displayPrefs
    }

    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    public func fieldsToHTML(_ note: Note,
                             io: NotenikIO?,
                             format: MarkedupFormat = .htmlDoc,
                             topOfPage: String,
                             bodyHTML: String? = nil,
                             minutesToRead: MinutesToReadValue? = nil,
                             bottomOfPage: String = "") -> String {
        
        self.bodyHTML = bodyHTML
        self.minutesToRead = minutesToRead
        streamlined = note.collection.streamlined
        
        let collection = note.collection
        let dict = collection.dict
        let code = Markedup(format: format)
        var css: String?
        if collection.displayCSS.count > 0 {
            css = collection.displayCSS
        } else if displayPrefs != nil {
            css = displayPrefs!.bodyCSS
        }
        
        code.startDoc(withTitle: note.title.value, withCSS: css)
        
        if !topOfPage.isEmpty {
            code.append(topOfPage)
        }
        
        if note.hasTags() && topOfPage.isEmpty && !streamlined {
            let tagsField = note.getTagsAsField()
            code.append(display(tagsField!, note: note, collection: collection, io: io))
        }
        
        var i = 0
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                if def == collection.minutesToReadDef && minutesToRead != nil {
                    let minutesToReadField = NoteField(def: def!, value: minutesToRead!)
                    code.append(display(minutesToReadField, note: note, collection: collection, io: io))
                } else {
                    let field = note.getField(def: def!)
                    if field != nil && field!.value.hasData {
                        if field!.def == collection.tagsFieldDef {
                            if !topOfPage.isEmpty {
                                code.append(display(field!, note: note, collection: collection, io: io))
                            }
                        } else if field!.def.fieldLabel.commonForm == NotenikConstants.dateAddedCommon {
                            // ignore for now
                        } else if field!.def.fieldLabel.commonForm == NotenikConstants.dateModifiedCommon {
                            // ignore for now
                        } else if field!.def.fieldLabel.commonForm == NotenikConstants.timestampCommon {
                            // ignore for now
                        } else {
                            code.append(display(field!, note: note, collection: collection, io: io))
                        }
                    }
                }
            }
            i += 1
        }
        
        if !streamlined && (note.hasDateAdded() || note.hasTimestamp() || note.hasDateModified()) {
            code.horizontalRule()
            
            let stamp = note.getField(label: NotenikConstants.timestamp)
            if stamp != nil {
                code.append(display(stamp!, note: note, collection: collection, io: io))
            }
            
            let dateAdded = note.getField(label: NotenikConstants.dateAdded)
            if dateAdded != nil {
                code.append(display(dateAdded!, note: note, collection: collection, io: io))
            }
            
            let dateModified = note.getField(label: NotenikConstants.dateModified)
            if dateModified != nil {
                code.append(display(dateModified!, note: note, collection: collection, io: io))
            }
        }
        if !bottomOfPage.isEmpty {
            code.horizontalRule()
            code.append(bottomOfPage)
        }
        code.finishDoc()
        return String(describing: code)
    }
    
    
    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField, note: Note, collection: NoteCollection, io: NotenikIO?) -> String {
        
        let code = Markedup(format: format)
        if field.def == collection.titleFieldDef {
            var titleToDisplay = field.value.value
            if streamlined && note.hasSeq() {
                titleToDisplay = note.seq.value + " " + field.value.value
            }
            if collection.h1Titles {
                code.heading(level: 1, text: titleToDisplay)
            } else {
                code.startParagraph()
                code.startStrong()
                code.append(titleToDisplay)
                code.finishStrong()
                code.finishParagraph()
            }
        } else if field.def == collection.tagsFieldDef && !streamlined {
            code.startParagraph()
            code.startEmphasis()
            code.append(field.value.value)
            code.finishEmphasis()
            code.finishParagraph()
        } else if field.def == collection.bodyFieldDef {
            if collection.bodyLabel {
                code.startParagraph()
                code.append(field.def.fieldLabel.properForm)
                code.append(": ")
                code.finishParagraph()
            }
            if format == .htmlDoc || format == .htmlFragment {
                if bodyHTML != nil {
                    code.append(bodyHTML!)
                } else {
                    MkdownParser.markdownToMarkedup(markdown: field.value.value,
                                                    wikiLinkLookup: io,
                                                    writer: code)
                }
            } else {
                code.append(field.value.value)
                code.newLine()
            }
        } else if streamlined {
            // Skip other fields
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
        } else if field.def.fieldType.typeString == NotenikConstants.codeCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.codeBlock(field.value.value)
        } else if field.def.fieldType.typeString == NotenikConstants.longTextType ||
                    field.def.fieldType.typeString == NotenikConstants.bodyCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            if format == .htmlDoc || format == .htmlFragment {
                MkdownParser.markdownToMarkedup(markdown: field.value.value,
                                                wikiLinkLookup: io,
                                                writer: code)
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
        } else if field.def.fieldType.typeString == NotenikConstants.imageNameCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.append(field.value.value)
            code.finishParagraph()
        } else if field.def == collection.minutesToReadDef {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            if minutesToRead != nil {
                code.append(minutesToRead!.value)
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
