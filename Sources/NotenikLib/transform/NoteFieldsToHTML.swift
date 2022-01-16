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
    
    var attribution: NoteField?
    
    var quoted = false
    
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
                             imageWithinPage: String,
                             bodyHTML: String? = nil,
                             minutesToRead: MinutesToReadValue? = nil,
                             bottomOfPage: String = "",
                             lastInList: Bool = false) -> String {
        
        // Save parameters and make key variables easily accessible for later use.
        self.parms = parms
        parms.setMkdownOptions(mkdownOptions)
        self.bodyHTML = bodyHTML
        self.minutesToRead = minutesToRead
        let collection = note.collection
        let dict = collection.dict
        
        // Start the Markedup code generator.
        let code = Markedup(format: parms.format)
        code.startDoc(withTitle: note.title.value,
                      withCSS: parms.cssString,
                      linkToFile: parms.cssLinkToFile,
                      withJS: mkdownOptions.getHtmlScript())
        
        // See if we need to start a list of included children.
        startListOfChildren(code: code)
        
        // Start with top of page code, if we have any.
        if !topOfPage.isEmpty {
            code.append(topOfPage)
        }
        
        // Start an included item, if needed.
        startIncludedItem(code: code)
        
        // Let's put the tags at the top, if it's a normal display.
        if note.hasTags() && topOfPage.isEmpty && parms.fullDisplay {
            let tagsField = note.getTagsAsField()
            code.append(display(tagsField!, note: note, collection: collection, io: io))
        }
        
        // Now let's display each of the fields, in dictionary order.
        var i = 0
        attribution = nil
        quoted = false
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
                        } else if field!.def == collection.backlinksDef {
                            // ignore for now
                        } else if field!.def == collection.wikilinksDef {
                            // ignore for now
                        } else if field!.def == collection.attribFieldDef {
                            attribution = field
                        } else {
                            code.append(display(field!, note: note, collection: collection, io: io))
                            if field!.def == collection.titleFieldDef {
                                if !imageWithinPage.isEmpty {
                                    code.append(imageWithinPage)
                                }
                            }
                        }
                    }
                }
            }
            i += 1
        }
        
        // Put quote attribution after the quote itself.
        // if quoted && attribution != nil {
        if attribution != nil {
            code.append(display(attribution!, note: note, collection: collection, io: io))
        }
        
        // Put system-maintained dates at the bottom, for reference.
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
        
        // Finish up an included item, if needed.
        finishIncludedItem(code: code)
        
        // Add wiki links and backlinks, when present.
        formatWikilinks(note, linksHTML: code)
        formatBacklinks(note, linksHTML: code)
        
        // Now add the bottom of the page, if any.
        if !bottomOfPage.isEmpty {
            code.horizontalRule()
            code.append(bottomOfPage)
        }
        
        // If this is the last included child, and if a list was requested, finish it off.
        if lastInList {
            finishListOfChildren(code: code)
        }
        
        // Finish off the entire document.
        code.finishDoc()
        
        // Return the markup. 
        return String(describing: code)
    }
    
    func startListOfChildren(code: Markedup) {

        guard parms.streamlined else { return }
        guard parms.included.asList else { return }
        guard parms.includedList.isEmpty else { return }

        switch parms.included.value {
        case "dl":
            code.startDefinitionList(klass: nil)
        case "ol":
            code.startOrderedList(klass: nil)
        case "ul":
            code.startUnorderedList(klass: nil)
        default:
            break
        }
        parms.includedList = parms.included.value

    }
    
    func startIncludedItem(code: Markedup) {
        guard parms.streamlined else { return }
        guard parms.included.on else { return }
        if parms.included.value == IncludeChildrenList.orderedList
            || parms.included.value == IncludeChildrenList.unorderedList {
            code.startListItem()
        }
    }
    
    func finishIncludedItem(code: Markedup) {
        guard parms.streamlined else { return }
        guard parms.included.on else { return }
        if parms.included.value == IncludeChildrenList.orderedList
            || parms.included.value == IncludeChildrenList.unorderedList {
            code.finishListItem()
        } else if parms.included.value == IncludeChildrenList.details {
            code.finishDetails()
        }
    }
    
    func finishListOfChildren(code: Markedup) {
        guard parms.streamlined else { return }
        guard parms.included.asList else { return }
        guard !parms.includedList.isEmpty else { return }

        switch parms.includedList {
        case "dl":
            code.finishDefinitionList()
        case "ol":
            code.finishOrderedList()
        case "ul":
            code.finishUnorderedList()
        default:
            break
        }
        
        parms.includedList = ""

    }
    
    func formatWikilinks(_ note: Note, linksHTML: Markedup) {
        
        guard note.collection.wikilinksDef != nil else { return }
        let links = note.wikilinks
        let pointers = links.notePointers
        guard pointers.count > 0 else { return }
        
        linksHTML.startDetails(summary: "Wiki Links")
        linksHTML.startUnorderedList(klass: nil)
        for pointer in pointers {
            linksHTML.startListItem()
            linksHTML.link(text: pointer.title, path: parms.assembleWikiLink(title: pointer.title))
            linksHTML.finishListItem()
        }
        linksHTML.finishUnorderedList()
        linksHTML.finishDetails()
    }
    
    func formatBacklinks(_ note: Note, linksHTML: Markedup) {
        
        guard note.collection.backlinksDef != nil else { return }
        let links = note.backlinks
        let pointers = links.notePointers
        guard pointers.count > 0 else { return }
        
        linksHTML.startDetails(summary: "Back Links")
        linksHTML.startUnorderedList(klass: nil)
        for pointer in pointers {
            linksHTML.startListItem()
            linksHTML.link(text: pointer.title, path: parms.assembleWikiLink(title: pointer.title))
            linksHTML.finishListItem()
        }
        linksHTML.finishUnorderedList()
        linksHTML.finishDetails()
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
        
        // Format the Note's Title Line
        if field.def == collection.titleFieldDef {
            displayTitle(note: note, markedup: code)
        // Format the tags field
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
                if note.klass.quote {
                    code.startBlockQuote()
                    quoted = true
                }
                if bodyHTML != nil {
                    code.append(bodyHTML!)
                } else {
                    markdownToMarkedup(markdown: field.value.value,
                                       context: mkdownContext,
                                       writer: code)
                }
                if note.klass.quote {
                    code.finishBlockQuote()
                }
            } else {
                code.append(field.value.value)
                code.newLine()
            }
        } else if parms.streamlined
                    && collection.klassFieldDef != nil
                    && field.def == collection.klassFieldDef!
                    && note.klass.quote {
            // code.startParagraph()
            // code.startEmphasis()
            // code.append("Quotation:")
            // code.finishEmphasis()
            // code.finishParagraph()
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
        } else if field.def.fieldType is AttribType {
            markdownToMarkedup(markdown: field.value.value,
                               context: mkdownContext,
                               writer: code)
        } else if parms.streamlined {
            switch field.def.fieldType.typeString {
            case NotenikConstants.authorCommon:
                if note.hasAttribution() {
                    break
                } else {
                    displayStraight(field, markedup: code)
                }
            case NotenikConstants.workTitleCommon:
                if note.hasAttribution() {
                    break
                } else {
                    displayStraight(field, markedup: code)
                }
            case NotenikConstants.dateCommon:
                if note.hasAttribution() {
                    break
                } else {
                    displayStraight(field, markedup: code)
                }
            case NotenikConstants.imageNameCommon:
                break
            case NotenikConstants.includeChildrenCommon:
                break
            case NotenikConstants.klassCommon:
                break
            case NotenikConstants.levelCommon:
                break
            case NotenikConstants.tagsCommon:
                break
            case NotenikConstants.seqCommon:
                break
            case NotenikConstants.akaCommon:
                code.startParagraph()
                code.startEmphasis()
                if field.def.fieldLabel.properForm == NotenikConstants.aka {
                    code.append("aka")
                } else {
                    code.append(field.def.fieldLabel.properForm)
                }
                code.append(": ")
                code.append(field.value.value)
                code.finishEmphasis()
                code.finishParagraph()
            default:
                if field.def.fieldLabel.commonForm == NotenikConstants.teaserCommon {
                    break
                } else if field.def.fieldLabel.commonForm == NotenikConstants.imageCaptionCommon {
                    break
                } else if field.def.fieldLabel.commonForm == NotenikConstants.imageAltCommon {
                    break
                } else {
                    displayStraight(field, markedup: code)
                }
            }
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
        } else if field.def.fieldType.typeString == NotenikConstants.lookupType {
            displayLookup(field, note: note, collection: collection, markedup: code, io: io)
        } else {
            displayStraight(field, markedup: code)
        }

        return String(describing: code)
    }
    
    // Display the Title of the Note in one of several possible formats.
    func displayTitle(note: Note, markedup: Markedup) {
        
        var titleToDisplay = note.title.value
        if parms.streamlined && note.hasSeq() {
            if !note.klass.frontOrBack && !note.klass.quote {
                if parms.included.value != IncludeChildrenList.orderedList {
                    titleToDisplay = note.seq.value + " " + note.title.value
                }
            }
        }
        
        if parms.streamlined && parms.included.on && note.klass.quote && note.hasAuthor() {
            let titleMarkup = Markedup(format: parms.format)
            titleMarkup.noDoc()
            titleMarkup.append("\(note.author.firstNameFirst): ")
            titleMarkup.leftDoubleQuote()
            titleMarkup.append(note.title.value)
            titleMarkup.ellipsis()
            titleMarkup.rightDoubleQuote()
            titleToDisplay = titleMarkup.code
        }
        
        if parms.included.on {
            switch parms.included.value {
            case IncludeChildrenList.defList:
                markedup.startDefTerm()
                markedup.append(titleToDisplay)
                markedup.finishDefTerm()
                markedup.newLine()
            case IncludeChildrenList.orderedList, IncludeChildrenList.unorderedList:
                markedup.append(titleToDisplay)
                markedup.lineBreak()
            case IncludeChildrenList.details:
                markedup.startDetails(summary: titleToDisplay)
            case "h1", "h2", "h3", "h4", "h5", "h6":
                markedup.heading(level: parms.included.headingLevel, text: titleToDisplay)
            default:
                markedup.startParagraph()
                markedup.startEmphasis()
                markedup.append(titleToDisplay)
                markedup.finishEmphasis()
                markedup.finishParagraph()
                markedup.newLine()
            }
        } else if note.collection.h1Titles {
            markedup.heading(level: 1, text: titleToDisplay)
        } else if parms.concatenated && note.collection.levelFieldDef != nil {
            var level = note.level.getInt()
            if level < 1 {
                level = 1
            } else if level > 6 {
                level = 6
            }
            markedup.heading(level: level, text: titleToDisplay, addID: true, idText: note.title.value)
        } else {
            markedup.startParagraph()
            markedup.startStrong()
            markedup.append(titleToDisplay)
            markedup.finishStrong()
            markedup.finishParagraph()
        }
    }
    
    /// Display a field without any special formatting.
    func displayStraight(_ field: NoteField, markedup: Markedup) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properForm)
        markedup.append(": ")
        markedup.append(field.value.value)
        markedup.finishParagraph()
    }
    
    /// Display a lookup field.
    func displayLookup(_ field: NoteField,
                       note: Note,
                       collection: NoteCollection,
                       markedup: Markedup,
                       io: NotenikIO?) {
        
        var detailsFound = false
        let shortcut = field.def.lookupFrom
        let lookupNote = MultiFileIO.shared.getNote(shortcut: shortcut, forID: field.value.value)
        if lookupNote == nil {
            markedup.startParagraph()
            markedup.append(field.def.fieldLabel.properForm)
            markedup.append(": ")
            var encodedTitle = field.value.value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            if encodedTitle == nil {
                encodedTitle = field.value.value
            }
            let addLink = "notenik://add?shortcut=\(shortcut)&title=\(encodedTitle!)"
            markedup.link(text: field.value.value, path: addLink)
            markedup.finishParagraph()
        } else {
            let lookupCollection = lookupNote!.collection
            let lookupDict = lookupCollection.dict
            for lookupDef in lookupDict.list {
                if lookupDef != lookupCollection.idFieldDef {
                    let lookupField = lookupNote!.getField(def: lookupDef)
                    if lookupField != nil && lookupField!.value.hasData {
                        if !detailsFound {
                            let openID = StringUtils.toCommon(field.value.value)
                            let openLink = "<a href=\"notenik://open?shortcut=\(shortcut)&id=\(openID)\">\(field.value.value)</a>"
                            markedup.startDetails(summary: field.def.fieldLabel.properForm + ": " + openLink)
                            markedup.startUnorderedList(klass: nil)
                            detailsFound = true
                        }
                        markedup.startListItem()
                        markedup.append(lookupField!.def.fieldLabel.properForm)
                        markedup.append(": ")
                        if lookupDef.fieldType is LinkType {
                            var pathDisplay = lookupField!.value.value.removingPercentEncoding
                            if pathDisplay == nil {
                                pathDisplay = lookupField!.value.value
                            }
                            markedup.link(text: pathDisplay!, path: lookupField!.value.value)
                        } else {
                            markedup.append(lookupField!.value.value)
                        }
                        markedup.finishListItem()
                    }
                }
            }
        }
        if detailsFound {
            markedup.finishUnorderedList()
            markedup.finishDetails()
        } else if lookupNote != nil {
            markedup.startParagraph()
            markedup.append(field.def.fieldLabel.properForm)
            markedup.append(": ")
            let openID = StringUtils.toCommon(field.value.value)
            let openLink = "notenik://open?shortcut=\(shortcut)&id=\(openID)"
            markedup.link(text: field.value.value, path: openLink)
            markedup.finishParagraph()
        }
    }
    
    /// Convert Markdown to HTML.
    func markdownToMarkedup(markdown: String,
                            context: MkdownContext?,
                            writer: Markedup) {
        
        writer.append(Markdown.parse(markdown: markdown, options: mkdownOptions, context: context))
    }
    
}
