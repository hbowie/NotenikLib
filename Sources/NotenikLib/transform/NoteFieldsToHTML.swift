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
public class NoteFieldsToHTML {
    
    public var parms = DisplayParms()
    
    var mkdownOptions = MkdownOptions()
    
    var bodyHTML: String?
    
    var minutesToRead: MinutesToReadValue?
    
    public init() {
        
    }

    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    public func fieldsToHTML(_ note: Note,
                             io: NotenikIO?,
                             parms: DisplayParms,
                             topOfPage: String,
                             bodyHTML: String? = nil,
                             minutesToRead: MinutesToReadValue? = nil,
                             bottomOfPage: String = "") -> String {
        
        self.parms = parms
        parms.setMkdownOptions(mkdownOptions)
        self.bodyHTML = bodyHTML
        self.minutesToRead = minutesToRead
        
        let collection = note.collection
        let dict = collection.dict
        let code = Markedup(format: parms.format)
        
        code.startDoc(withTitle: note.title.value,
                      withCSS: parms.cssString,
                      linkToFile: parms.cssLinkToFile,
                      withJS: mkdownOptions.getHtmlScript())
        
        if !topOfPage.isEmpty {
            code.append(topOfPage)
        }
        
        if note.hasTags() && topOfPage.isEmpty && parms.fullDisplay {
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
        
        if parms.fullDisplay && (note.hasDateAdded() || note.hasTimestamp() || note.hasDateModified()) {
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
        
        var mkdownContext: MkdownContext?
        if io != nil {
            mkdownContext = NotesMkdownContext(io: io!, displayParms: parms)
        }
        let code = Markedup(format: parms.format)
        if field.def == collection.titleFieldDef {
            var titleToDisplay = field.value.value
            if parms.streamlined && note.hasSeq() {
                titleToDisplay = note.seq.value + " " + field.value.value
            }
            if collection.h1Titles {
                code.heading(level: 1, text: titleToDisplay)
            } else if parms.concatenated && collection.levelFieldDef != nil {
                var level = note.level.getInt()
                if level < 1 {
                    level = 1
                } else if level > 6 {
                    level = 6
                }
                code.heading(level: level, text: titleToDisplay, addID: true, idText: field.value.value)
            } else {
                code.startParagraph()
                code.startStrong()
                code.append(titleToDisplay)
                code.finishStrong()
                code.finishParagraph()
            }
        } else if field.def == collection.tagsFieldDef && parms.fullDisplay {
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
            if parms.formatIsHTML {
                if bodyHTML != nil {
                    code.append(bodyHTML!)
                } else {
                    markdownToMarkedup(markdown: field.value.value,
                                       context: mkdownContext,
                                       writer: code)
                }
            } else {
                code.append(field.value.value)
                code.newLine()
            }
        } else if parms.streamlined {
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
            if parms.formatIsHTML {
                markdownToMarkedup(markdown: field.value.value,
                                   context: mkdownContext,
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
    
    /// Convert Markdown to HTML.
    func markdownToMarkedup(markdown: String,
                            context: MkdownContext?,
                            writer: Markedup) {
        let md = MkdownParser(markdown, options: mkdownOptions)
        md.setWikiLinkFormatting(prefix: parms.wikiLinkPrefix,
                                 format: parms.wikiLinkFormat,
                                 suffix: parms.wikiLinkSuffix,
                                 context: context)
        md.parse()
        writer.append(md.html)
    }
    
}
