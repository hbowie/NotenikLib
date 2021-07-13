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
///
/// Used by NoteDisplayViewController to display a Note on the Display tab, but also used by
/// ShareViewController to share a Note in one of a number of different formats.
public class NoteDisplay {
    
    public var parms = DisplayParms()
    
    var mdBodyParser: MkdownParser?
    var bodyHTML:     String?
    
    public var counts = MkdownCounts()
    
    var minutesToRead: MinutesToReadValue?
    
    public init() {
        
    }
    
    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    public func display(_ note: Note, io: NotenikIO, parms: DisplayParms) -> String {
        self.parms = parms
        let mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
        let collection = note.collection
        minutesToRead = nil
        mdBodyParser = nil
        bodyHTML = nil
        
        // Pre-parse the body field if we're generating HTML.
        if parms.formatIsHTML {
            let body = note.body
            mdBodyParser = MkdownParser(body.value)
            mdBodyParser!.setWikiLinkFormatting(prefix: parms.wikiLinkPrefix,
                                                format: parms.wikiLinkFormat,
                                                suffix: parms.wikiLinkSuffix,
                                                context: mkdownContext)
            mdBodyParser!.parse()
            counts = mdBodyParser!.counts
            if collection.minutesToReadDef != nil {
                minutesToRead = MinutesToReadValue(with: counts)
            }
            bodyHTML = mdBodyParser!.html
        }
        
        let position = io.positionOfNote(note)
        let topHTML = formatTopOfPage(note, io: io)
        let bottomHTML = formatBottomOfPage(note, io: io)
        if position.valid {
            _ = io.selectNote(at: position.index)
        }
        
        if parms.displayTemplate.count > 0 {
            return displayWithTemplate(note, io: io)
        } else {
            return displayWithoutTemplate(note, io: io, topOfPage: topHTML, bottomOfPage: bottomHTML)
        }
    }
    
    /// If we have a note level greater than 1, then try to display the preceding Note just higher in
    /// the implied hierarchy.
    func formatTopOfPage(_ note: Note, io: NotenikIO) -> String {
        guard parms.streamlined else { return "" }
        guard note.hasLevel() else { return "" }
        let noteLevel = note.level.level
        guard noteLevel > 1 else { return "" }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle else { return "" }
        var currentPosition = io.positionOfNote(note)
        var parentTitle = ""
        var parentSeq = ""
        
        while currentPosition.valid {
            let (priorNote, priorPosition) = io.priorNote(currentPosition)
            currentPosition = priorPosition
            guard priorPosition.valid && priorNote != nil else { break }
            guard priorNote!.hasLevel() else { continue }
            if priorNote!.level.level < noteLevel {
                parentTitle = priorNote!.title.value
                parentSeq = priorNote!.seq.value
                break
            }
        }
        guard !parentTitle.isEmpty else { return "" }
        let topHTML = Markedup()
        topHTML.startParagraph()
        if parentSeq.count > 0 {
            topHTML.append("\(parentSeq) ")
        }
        topHTML.link(text: parentTitle, path: parms.assembleWikiLink(title: parentTitle))
        topHTML.append("&nbsp;")
        topHTML.append("&#8593;")
        topHTML.finishParagraph()
        return topHTML.code
    }
    
    /// In a sequenced list, show upcoming Notes.
    func formatBottomOfPage(_ note: Note, io: NotenikIO) -> String {
        
        // See if we meet necessary conditions.
        guard parms.streamlined else { return "" }
        guard note.collection.seqFieldDef != nil else { return "" }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle else { return "" }
        let currentPosition = io.positionOfNote(note)
        let (nextNote, nextPosition) = io.nextNote(currentPosition)
        guard nextPosition.valid && nextNote != nil else { return "" }
        
        let bottomHTML = Markedup()
        let nextTitle = nextNote!.title.value
        let nextLevel = nextNote!.level
        let nextSeq = nextNote!.seq
        var tocNotes: [Note] = []
        if nextLevel > note.level && nextSeq > note.seq {
            tocNotes.append(nextNote!)
            let tocLevel = nextLevel
            var (anotherNote, anotherPosition) = io.nextNote(nextPosition)
            while anotherNote != nil && anotherNote!.level >= tocLevel {
                if anotherNote!.level == tocLevel {
                    tocNotes.append(anotherNote!)
                }
                (anotherNote, anotherPosition) = io.nextNote(anotherPosition)
            }
            if tocNotes.count > 1 {
                bottomHTML.heading(level: 4, text: "Contents")
                bottomHTML.startUnorderedList(klass: nil)
                for tocNote in tocNotes {
                    let tocTitle = tocNote.title.value
                    let tocSeq = tocNote.seq
                    bottomHTML.startListItem()
                    bottomHTML.append("\(tocSeq) ")
                    bottomHTML.link(text: tocTitle, path: parms.assembleWikiLink(title: tocTitle))
                    bottomHTML.finishListItem()
                }
                bottomHTML.finishUnorderedList()
                bottomHTML.horizontalRule()
            }
        }
        bottomHTML.startParagraph()
        bottomHTML.append("Next: ")
        bottomHTML.link(text: nextTitle, path: parms.assembleWikiLink(title: nextTitle))
        bottomHTML.finishParagraph()
        return bottomHTML.code
    }
    
    func displayWithTemplate(_ note: Note, io: NotenikIO) -> String {
        let template = Template()
        template.openTemplate(templateContents: parms.displayTemplate)
        let notesList = NotesList()
        notesList.append(note)
        template.supplyData(note,
                            dataSource: note.collection.title,
                            io: io,
                            bodyHTML: bodyHTML,
                            minutesToRead: minutesToRead)
        let ok = template.generateOutput()
        if !ok {
            Logger.shared.log(subsystem: "NotenikLib",
                              category: "NoteDisplay",
                              level: .error,
                              message: "Template generation failed")
        }
        return template.util.linesToOutput
    }
    
    /// Display the Note without use of a template.
    func displayWithoutTemplate(_ note: Note,
                                io: NotenikIO,
                                topOfPage: String,
                                bottomOfPage: String) -> String {
        
        let fieldsToHTML = NoteFieldsToHTML()
        return fieldsToHTML.fieldsToHTML(note,
                                         io: io,
                                         parms: parms,
                                         topOfPage: topOfPage,
                                         bodyHTML: bodyHTML,
                                         minutesToRead: minutesToRead,
                                         bottomOfPage: bottomOfPage)
    }

    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    public func displayOld(_ note: Note, io: NotenikIO) -> String {
        let mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
        let collection = note.collection
        let dict = collection.dict
        let code = Markedup(format: parms.format)
        code.startDoc(withTitle: note.title.value, withCSS: parms.cssString, linkToFile: parms.cssLinkToFile)
        
        if note.hasTags() {
            let tagsField = note.getTagsAsField()
            code.append(display(tagsField!, note: note, collection: collection, io: io))
        }
        
        minutesToRead = nil
        
        // Pre-parse the body field if we're creating HTML.
        if parms.formatIsHTML {
            let body = note.body
            mdBodyParser = MkdownParser(body.value)
            mdBodyParser!.setWikiLinkFormatting(prefix: parms.wikiLinkPrefix,
                                                format: parms.wikiLinkFormat,
                                                suffix: parms.wikiLinkSuffix,
                                                context: mkdownContext)
            mdBodyParser!.parse()
            counts = mdBodyParser!.counts
            if collection.minutesToReadDef != nil {
                minutesToRead = MinutesToReadValue(with: counts)
            }
        }
        
        var i = 0
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
                    code.append(display(field!, note: note, collection: collection, io: io))
                } else if def == collection.minutesToReadDef && minutesToRead != nil {
                    let minutesToReadField = NoteField(def: def!, value: minutesToRead!)
                    code.append(display(minutesToReadField, note: note, collection: collection, io: io))
                }
            }
            i += 1
        }
        if note.hasDateAdded() || note.hasTimestamp() || note.hasDateModified() {
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
        code.finishDoc()
        return String(describing: code)
    }
    
    
    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField, note: Note, collection: NoteCollection, io: NotenikIO) -> String {
        
        let mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
        let code = Markedup(format: parms.format)
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
        } else if field.def == collection.bodyFieldDef {
            if collection.bodyLabel {
                code.startParagraph()
                code.append(field.def.fieldLabel.properForm)
                code.append(": ")
                code.finishParagraph()
            }
            if parms.formatIsHTML {
                code.append(mdBodyParser!.html)
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
                let mdparser = MkdownParser(field.value.value)
                mdparser.setWikiLinkFormatting(prefix: parms.wikiLinkPrefix,
                                               format: parms.wikiLinkFormat,
                                               suffix: parms.wikiLinkSuffix,
                                               context: mkdownContext)
                mdparser.parse()
                code.append(mdparser.html)
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
