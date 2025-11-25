//
//  NoteFieldsToHTML.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/15/21.
//
//  Copyright © 2021 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// Generate the coding necessary to display a Note in a readable format.
public class NoteFieldsToHTML {
    
    let pop = PopConverter.shared
    
    public var parms = DisplayParms()
    
    var mkdownOptions = MkdownOptions()
    
    var bodyHTML: String?
    
    var minutesToRead: MinutesToReadValue?
    
    var io: NotenikIO?
    
    var mkdownContext: MkdownContext?
    
    var results = TransformMdResults()
    
    var expandedMarkdown: String? = nil
    
    var topOfPage: String = ""
    
    var attribution: NoteField?
    
    var quoted = false
    
    let attribBalancer = LineBalancer(maxChars: 50, sep: " <br />")
    
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
                             results: TransformMdResults,
                             bottomOfPage: String = "",
                             lastInList: Bool = false,
                             expandedMarkdown: String? = nil,
                             continuousPosition: ContinuousPosition = .middle) -> String {
        
        // Save parameters and make key variables easily accessible for later use.
        self.io = io
        self.results = results
        self.parms = parms
        self.expandedMarkdown = expandedMarkdown
        self.topOfPage = topOfPage
        
        
        
        if io != nil {
            mkdownContext = NotesMkdownContext(io: io!, displayParms: parms)
        }
        parms.setMkdownOptions(mkdownOptions)
        if note.hasShortID() {
            mkdownOptions.shortID = note.shortID.value
        } else {
            mkdownOptions.shortID = ""
        }
        self.bodyHTML = results.bodyHTML
        self.minutesToRead = results.minutesToRead
        
        var tagsDisplayed = false
        
        // Use separate logic if in quotes mode
        if parms.displayMode == .quotations && !parms.epub3 {
            return quoteFieldsToHTML(note, topOfPage: topOfPage, imageWithinPage: imageWithinPage, bottomOfPage: bottomOfPage, lastInList: lastInList)
        }
        
        let collection = note.collection
        let dict = collection.dict
        
        // Start the Markedup code generator.
        let code = Markedup(format: parms.format)
        let noteTitle = pop.toXML(note.title.value)
        if parms.displayMode != .continuous && parms.displayMode !=  .continuousPartial {
            code.startDoc(withTitle: noteTitle,
                          withCSS: note.getCombinedCSS(cssString: parms.cssString),
                          linkToFile: parms.cssLinkToFile,
                          withJS: mkdownOptions.getHtmlScript(),
                          epub3: parms.epub3,
                          addins: parms.addins)
        }
        
        // See if we need to start a list of included children.
        startListOfChildren(code: code)
        
        var headerContents = ""
        if note.treatAsTitlePage {
            headerContents = parms.header
        } else {
            headerContents = parms.header + collection.mkdownCommandList.getCodeFor(MkdownConstants.headerCmd)
        }
        
        var headerAndNav = true
        if parms.epub3 {
            headerAndNav = false
        } else if parms.displayMode == .continuous || parms.displayMode == .continuousPartial {
            if continuousPosition != .first {
                headerAndNav = false
            }
        }
        if headerAndNav {
            if note.mkdownCommandList.contentPage && !parms.included.hasData {
                if !headerContents.isEmpty {
                    code.header(headerContents, klass: "nnk-header")
                }
                let navCode = collection.mkdownCommandList.getCodeFor(MkdownConstants.navCmd)
                if !navCode.isEmpty && note.klass.value != NotenikConstants.titleKlass {
                    code.nav(navCode, klass: "nnk-nav")
                }
            }
        }
        
        code.startMain()
        
        if topOfPage.isEmpty && note.hasTags() && collection.tagsDisplayOption == .replNavUp {
            let tagsField = note.getTagsAsField()
            let topHTML = Markedup()
            topHTML.append(display(tagsField!, noteTitle: noteTitle, note: note, collection: collection, io: io))
            self.topOfPage = topHTML.code
            tagsDisplayed = true
        }
        
        // Start with top of page code, if we have any.
        if !self.topOfPage.isEmpty {
            code.append(self.topOfPage)
        }
        
        // Start an included item, if needed.
        startIncludedItem(code: code)
        
        // Let's put the tags at the top, if it's a normal display.
        if !tagsDisplayed && note.hasTags() && collection.tagsDisplayOption == .aboveTitle {
            // topOfPage.isEmpty && parms.displayTags {
            let tagsField = note.getTagsAsField()
            code.append(display(tagsField!, noteTitle: noteTitle, note: note, collection: collection, io: io))
            tagsDisplayed = true
        }
        
        // Now the Index Term if applicable
        if collection.indexFieldDef != nil && collection.indexOfCollection != nil
            && note.noteID.id == collection.lastIndexedPageID {
            code.startParagraph(klass: "indexed-by")
            code.append("Indexed by ")
            code.spanConditional(value: collection.lastIndexTermKey, klass: "index-term", prefix: "", suffix: "")
            code.append(" (\(collection.lastIndexTermPageIx + 1) of \(collection.lastIndexTermPageCount))")
            code.finishParagraph()
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
                    code.append(display(minutesToReadField, noteTitle: noteTitle, note: note, collection: collection, io: io))
                } else if def!.fieldType.typeString == NotenikConstants.lookBackType {
                    displayLookBack(def: def!, note: note, markedup: code)
                } else {
                    let field = note.getField(def: def!)
                    if field != nil && field!.value.hasData {
                        if field!.def == collection.tagsFieldDef {
                            if !tagsDisplayed && collection.tagsDisplayOption == .belowTitle {
                                code.append(display(field!, noteTitle: noteTitle, note: note, collection: collection, io: io))
                                tagsDisplayed = true
                            }
                        } else if field!.def.fieldLabel.commonForm == NotenikConstants.dateAddedCommon {
                            // ignore for now
                        } else if field!.def.fieldLabel.commonForm == NotenikConstants.dateModifiedCommon {
                            // ignore for now
                        } else if field!.def.fieldLabel.commonForm == NotenikConstants.datePickedCommon {
                            // ignore for now
                        } else if field!.def.fieldLabel.commonForm == NotenikConstants.timestampCommon {
                            // ignore for now
                        } else if field!.def == collection.backlinksDef {
                            // ignore for now
                        } else if field!.def == collection.wikilinksDef {
                            // ignore for now
                        } else if parms.displayMode == .quotations && field!.def.fieldType.typeString == NotenikConstants.booleanType {
                            // don't show flags in quotes mode
                        } else if field!.def.fieldType.typeString == NotenikConstants.pageStyleCommon {
                            // don't display as separate field
                        } else if field!.def == collection.attribFieldDef {
                            attribution = field
                        } else {
                            code.append(display(field!, noteTitle: noteTitle, note: note, collection: collection, io: io))
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
        if attribution != nil {
            code.append(display(attribution!, noteTitle: noteTitle, note: note, collection: collection, io: io))
        }
        
        // Put system-maintained dates at the bottom, for reference.
        if parms.fullDisplay && (note.hasDateAdded()
                                 || note.hasTimestamp()
                                 || note.hasDateModified()
                                 || note.hasDatePicked()) {
            code.horizontalRule()
            
            let stamp = note.getField(label: NotenikConstants.timestamp)
            if stamp != nil {
                code.append(display(stamp!, noteTitle: noteTitle, note: note, collection: collection, io: io))
            }
            
            let dateAdded = note.getField(label: NotenikConstants.dateAdded)
            if dateAdded != nil {
                code.append(display(dateAdded!, noteTitle: noteTitle, note: note, collection: collection, io: io))
            }
            
            let dateModified = note.getField(label: NotenikConstants.dateModified)
            if dateModified != nil {
                code.append(display(dateModified!, noteTitle: noteTitle, note: note, collection: collection, io: io))
            }
            
            if note.hasDatePicked() {
                if let datePicked = note.getField(def: collection.datePickedFieldDef!) {
                    code.append(display(datePicked,
                                        noteTitle: noteTitle, note: note,
                                        collection: collection, io: io))
                }
            }
        }
        
        // Finish up an included item, if needed.
        finishIncludedItem(code: code)
        
        // Add wiki links and backlinks, when present.
        formatWikilinks(note, linksHTML: code, io: io)
        formatBacklinks(note, linksHTML: code, io: io)
        
        // Now add the bottom of the page, if any.
        if !bottomOfPage.isEmpty {
            code.horizontalRule()
            code.append(bottomOfPage)
        } 
        
        // If this is the last included child, and if a list was requested, finish it off.
        if lastInList {
            finishListOfChildren(code: code)
        }
        
        code.finishMain()
        
        var footer = true
        if parms.epub3 {
            footer = false
        } else if parms.displayMode == .continuous || parms.displayMode == .continuousPartial {
            if continuousPosition != .last {
                footer = false
            }
        }
        if footer {
            let footerCode = collection.mkdownCommandList.getCodeFor(MkdownConstants.footerCmd)
            if note.includeInBook(epub: parms.epub3) && !footerCode.isEmpty && !parms.included.hasData {
                code.footer(footerCode, klass: "nnk-footer")
            }
        }
        
        // Finish off the entire document.
        if parms.displayMode != .continuous && parms.displayMode != .continuousPartial {
            code.finishDoc()
        }
        
        // Return the markup. 
        return String(describing: code)
    }
    
    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    public func quoteFieldsToHTML(_ note: Note,
                             topOfPage: String,
                             imageWithinPage: String,
                             bottomOfPage: String = "",
                             lastInList: Bool = false) -> String {
        
        let collection = note.collection
        
        // Start the Markedup code generator.
        let code = Markedup(format: parms.format)
        let noteTitle = pop.toXML(note.title.value)
        code.startDoc(withTitle: noteTitle,
                      withCSS: note.getCombinedCSS(cssString: parms.cssString),
                      linkToFile: parms.cssLinkToFile,
                      withJS: mkdownOptions.getHtmlScript(),
                      epub3: parms.epub3,
                      addins: parms.addins)
        
        var headerContents = ""
        if note.treatAsTitlePage {
            headerContents = parms.header
        } else {
            headerContents = parms.header + collection.mkdownCommandList.getCodeFor(MkdownConstants.headerCmd)
        }
        
        if note.mkdownCommandList.contentPage
            // && note.klass.value != NotenikConstants.titleKlass
            {
            if !headerContents.isEmpty {
                code.header(headerContents, klass: "nnk-header")
            }
            let navCode = collection.mkdownCommandList.getCodeFor(MkdownConstants.navCmd)
            if !navCode.isEmpty && note.klass.value != NotenikConstants.titleKlass {
                code.nav(navCode, klass: "nnk-nav")
            }
        }
        
        code.startMain()
        
        // Start with top of page code, if we have any.
        if !topOfPage.isEmpty {
            code.append(topOfPage)
        }
        
        // Start an included item, if needed.
        startIncludedItem(code: code)
        
        // Display the Tags
        if let field = note.getTagsAsField() {
            displayTags(field, collection: collection, markedup: code)
        }
        
        // Display the Title of the Note
        displayTitle(note: note, noteTitle: note.title.value, markedup: code)
        
        // Display the body of the note.
        if let bodyField = note.getBodyAsField() {
            displayBody(bodyField, note: note, collection: collection, mkdownContext: mkdownContext, markedup: code)
            // code.horizontalRule()
        } else {
            return ""
        }
        
        // Put quote attribution after the quote itself.
        // if quoted && attribution != nil {
        if attribution != nil {
            code.append(display(attribution!, noteTitle: noteTitle, note: note, collection: collection, io: io))
        } else {
            code.append(NoteSlugger.authorWorkSlug(fromNote: note, links: false, verbose: true))
        }
        
        // Finish up an included item, if needed.
        finishIncludedItem(code: code)
        
        // Now add the bottom of the page, if any.
        if !bottomOfPage.isEmpty {
            code.horizontalRule()
            code.append(bottomOfPage)
        }
        
        // If this is the last included child, and if a list was requested, finish it off.
        if lastInList {
            finishListOfChildren(code: code)
        }
        
        code.finishMain()
        
        let footerCode = collection.mkdownCommandList.getCodeFor(MkdownConstants.footerCmd)
        if note.includeInBook(epub: parms.epub3) && !footerCode.isEmpty {
            code.footer(footerCode, klass: "nnk-footer")
        }
        
        // Finish off the entire document.
        code.finishDoc()
        
        // Return the markup.
        return String(describing: code)
    }
    
    func startListOfChildren(code: Markedup) {

        guard parms.reducedDisplay else { return }
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
        guard parms.reducedDisplay else { return }
        guard parms.included.on else { return }
        if parms.included.value == IncludeChildrenList.orderedList
            || parms.included.value == IncludeChildrenList.unorderedList {
            code.startListItem()
        }
    }
    
    func finishIncludedItem(code: Markedup) {
        guard parms.reducedDisplay else { return }
        guard parms.included.on else { return }
        if parms.included.value == IncludeChildrenList.orderedList
            || parms.included.value == IncludeChildrenList.unorderedList {
            code.finishListItem()
        } else if parms.included.value == IncludeChildrenList.details {
            code.finishDetails()
        }
    }
    
    func finishListOfChildren(code: Markedup) {
        guard parms.reducedDisplay else { return }
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
    
    func formatWikilinks(_ note: Note, linksHTML: Markedup, io: NotenikIO?) {
        guard let def = note.collection.wikilinksDef else { return }
        let links = note.wikilinks
        guard links.hasData else { return }
        if io != nil {
            mkdownContext = NotesMkdownContext(io: io!, displayParms: parms)
        }
        var initialReveal = false
        if let wikiLinksType = def.fieldType as? WikilinkType {
            initialReveal = wikiLinksType.initialReveal
        }
        let wrangler = WikiLinkWrangler(options: mkdownOptions, context: mkdownContext)
        wrangler.targetsToHTML(properLabel: def.fieldLabel.properForm,
                               targets: links.notePointers,
                               markedup: linksHTML,
                               initialReveal: initialReveal)
    }
    
    func formatBacklinks(_ note: Note, linksHTML: Markedup, io: NotenikIO?) {
        guard let def = note.collection.backlinksDef else { return }
        let links = note.backlinks
        guard links.hasData else { return }
        if io != nil {
            mkdownContext = NotesMkdownContext(io: io!, displayParms: parms)
        }
        var initialReveal = false
        if let backLinksType = def.fieldType as? BacklinkType {
            initialReveal = backLinksType.initialReveal
        }
        let wrangler = WikiLinkWrangler(options: mkdownOptions, context: mkdownContext)
        wrangler.targetsToHTML(properLabel: def.fieldLabel.properForm,
                               targets: links.notePointers,
                               markedup: linksHTML,
                               initialReveal: initialReveal)
    }
    
    
    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField,
                 noteTitle: String,
                 note: Note,
                 collection: NoteCollection,
                 io: NotenikIO?) -> String {
        
        // Prepare for processing.
        if io != nil {
            mkdownContext = NotesMkdownContext(io: io!, displayParms: parms)
        }
        let code = Markedup(format: parms.format)
        
        // Format the Note's Title Line
        if field.def == collection.titleFieldDef {
            displayTitle(note: note,
                         noteTitle: noteTitle,
                         markedup: code)
            if mkdownContext != nil {
                mkdownContext!.identifyNoteToParse(id: note.noteID.commonID,
                                                   text: note.noteID.text,
                                                   fileName: note.noteID.commonFileName,
                                                   shortID: note.shortID.value)
            }
        // Format the tags field
        } else if field.def == collection.tagsFieldDef && parms.displayTags {
            displayTags(field, collection: collection, markedup: code)
        } else if field.def == collection.bodyFieldDef {
            displayBody(field,
                        note: note,
                        collection: collection,
                        mkdownContext: mkdownContext,
                        markedup: code)
        } else if parms.displayMode == .streamlinedReading
                    && collection.klassFieldDef != nil
                    && field.def == collection.klassFieldDef!
                    && note.klass.quote {
            // code.startParagraph()
            // code.startEmphasis()
            // code.append("Quotation:")
            // code.finishEmphasis()
            // code.finishParagraph()
        } else if field.def.fieldType is LinkType {
            displayLink(field, collection: collection, markedup: code)
        } else if field.def.fieldType is EmailType {
            displayEmail(field, markedup: code)
        } else if field.def.fieldType is PhoneType {
            displayPhone(field, markedup: code)
        } else if field.def.fieldType is AddressType {
            displayAddress(field, markedup: code)
        } else if field.def.fieldType is DirectionsType {
            displayDirections(field, markedup: code)
        } else if field.def.fieldType is AttribType {
            transformMarkdown(markdown: field.value.value,
                              fieldType: field.def.fieldType.typeString,
                              writer: code,
                              note: note,
                              shortID: note.shortID.value)
        } else if parms.reducedDisplay && !field.def.fieldType.reducedDisplay {
            // no output
        } else if parms.reducedDisplay {
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
            case NotenikConstants.workLargerTitleCommon:
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
            case NotenikConstants.imageCreditCommon:
                break
            case NotenikConstants.imageCreditLinkCommon:
                break
            case NotenikConstants.includeChildrenCommon:
                break
            case NotenikConstants.tagsCommon:
                break
            case NotenikConstants.seqCommon:
                break
            case NotenikConstants.displaySeqCommon:
                break
            case NotenikConstants.longTextType:
                displayMarkdown(field, markedup: code, noteTitle: noteTitle, note: note, mkdownContext: mkdownContext)
                if !collection.bodyLabel && note.hasBody() {
                    code.horizontalRule()
                }
            case NotenikConstants.akaCommon:
                break;
                /*
                code.startParagraph(klass: "notenik-\(field.def.fieldType.typeString)")
                code.startEmphasis()
                if field.def.fieldLabel.properForm == NotenikConstants.aka {
                    code.append("aka")
                } else {
                    code.append(field.def.fieldLabel.properForm)
                }
                code.append(": ")
                code.append(field.value.value)
                code.finishEmphasis()
                code.finishParagraph() */
            default:
                switch field.def.fieldLabel.commonForm {
                case NotenikConstants.teaserCommon:
                    break
                case NotenikConstants.imageCaptionCommon:
                    break
                case NotenikConstants.imageAltCommon:
                    break
                case NotenikConstants.workLargerTitleCommon:
                    break
                case NotenikConstants.imageCreditCommon:
                    break
                case NotenikConstants.imageCreditLinkCommon:
                    break
                default:
                    displayStraight(field, markedup: code)
                }
            }
        } else if field.def.fieldType.typeString == NotenikConstants.codeCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properWithParent)
            code.append(": ")
            code.finishParagraph()
            code.codeBlock(field.value.value)
        } else if field.def.fieldType.typeString == NotenikConstants.longTextType ||
                    field.def.fieldType.typeString == NotenikConstants.teaserCommon ||
                    field.def.fieldType.typeString == NotenikConstants.bodyCommon {
            displayMarkdown(field, markedup: code, noteTitle: noteTitle, note: note, mkdownContext: mkdownContext)
        } else if field.def.fieldType.typeString == NotenikConstants.dateType {
            code.startParagraph()
            code.append(field.def.fieldLabel.properWithParent)
            code.append(": ")
            if let dateValue = field.value as? DateValue {
                code.append(dateValue.valueToDisplay())
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
        } else if field.def.fieldType.typeString == NotenikConstants.seqCommon {
            displaySeq(field, note: note, collection: collection, markedup: code)
        } else {
            displayStraight(field, markedup: code)
        }

        return String(describing: code)
    }
    
    func displayBody(_ field: NoteField,
                     note: Note,
                     collection: NoteCollection,
                     mkdownContext: MkdownContext?,
                     markedup: Markedup) {
        
        if collection.bodyLabel && parms.fullDisplay {
            markedup.startParagraph()
            markedup.append(field.def.fieldLabel.properForm)
            markedup.append(": ")
            markedup.finishParagraph()
        }
        if parms.formatIsHTML {
            if note.klass.quote {
                if note.hasAttribution() {
                    markedup.startBlockQuote(klass: "attribution-following")
                } else {
                    markedup.startBlockQuote()
                }
                quoted = true
            }
            if collection.textFormatFieldDef != nil && note.textFormat.isText {
                markedup.startPreformatted()
                markedup.append(field.value.value)
                markedup.finishPreformatted()
            } else if bodyHTML != nil {
                markedup.append(bodyHTML!)
            } else {
                
                transformMarkdown(markdown: field.value.value,
                                  fieldType: NotenikConstants.bodyCommon,
                                  writer: markedup,
                                  note: note,
                                  shortID: note.shortID.value)
                
                if let context = results.mkdownContext {
                    if let bodyHTML = results.bodyHTML {
                        note.mkdownCommandList = context.mkdownCommandList
                        note.mkdownCommandList.updateWith(body: field.value.value, html: bodyHTML)
                        collection.mkdownCommandList.updateWith(noteList: note.mkdownCommandList)
                    }
                }
            }
            if note.klass.quote {
                markedup.finishBlockQuote()
            }
        } else if parms.format == .markdown && expandedMarkdown != nil && !expandedMarkdown!.isEmpty {
            markedup.append(expandedMarkdown!)
            markedup.newLine()
        } else {
            markedup.append(field.value.value)
            markedup.newLine()
        }
    }
    
    /// Provide special formatting for the Tags field. 
    func displayTags(_ field: NoteField, collection: NoteCollection, markedup: Markedup) {
        
        var klass = "nnk-tags"
        if collection.tagsDisplayOption == .replNavUp {
            klass = "nnk-tags-repl-nav-up"
        }
        markedup.startParagraph(klass: klass)
        if let tags = field.value as? TagsValue {
            var tagsCount = 0
            for tag in tags.tags {
                if tagsCount > 0 {
                    markedup.append(", ")
                }
                var link = ""
                if parms.wikiLinks.format == .fileName
                    && parms.hasTagsIndexFilename {
                    link = parms.formatLinkToTag(tag: tag.value)
                } else {
                    link = CustomURLFormatter().expandTag(collection: collection, tag: tag)
                }
                markedup.link(text: tag.description, path: link, style: "text-decoration: none")
                tagsCount += 1
            }
        }
        markedup.finishParagraph()
    }
    
    // Display the Title of the Note in one of several possible formats.
    func displayTitle(note: Note, noteTitle: String, markedup: Markedup) {
        
        var titleToDisplay = parms.compoundTitle(note: note)
        
        if parms.displayMode == .streamlinedReading && parms.included.on && note.klass.quote && note.hasAuthor() {
            let titleMarkup = Markedup(format: parms.format)
            titleMarkup.noDoc()
            titleMarkup.append("\(note.author.firstNameFirst): ")
            titleMarkup.leftDoubleQuote()
            titleMarkup.append(noteTitle)
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
        } else {
            markedup.displayLine(opt: note.collection.titleDisplayOption,
                                 text: titleToDisplay,
                                 depth: note.depth,
                                 addID: true,
                                 idText: note.title.value,
                                 style: "clear:both")
        }
    }
    
    func displayLink(_ field: NoteField, collection: NoteCollection, markedup: Markedup) {
        if parms.reducedDisplay {
            if field.def.fieldLabel.commonForm == NotenikConstants.imageCreditLinkCommon {
                return
            }
        }
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properWithParent)
        markedup.append(": ")
        let path = field.value.value
        let displayPath = field.value.value.removingPercentEncoding
        var pathToDisplay = displayPath
        if let linkValue = field.value as? LinkValue {
            pathToDisplay = collection.linkFormatter.format(link: linkValue)
        }
        var pathForLink = ""
        if displayPath == path {
            pathForLink = pop.toURL(path)
        } else {
            pathForLink = path
        }
        if pathToDisplay == nil {
            pathToDisplay = path
        }
        pathToDisplay = pop.toXML(pathToDisplay!)
        
        var blankTarget = parms.extLinksOpenInNewWindows
        if blankTarget {
            if !(path.starts(with: "https://") || path.starts(with: "http://") || path.starts(with: "www.")) {
                blankTarget = false
            }
        }
        
        markedup.link(text: pathToDisplay!,
                      path: pathForLink,
                      klass: "ext-link",
                      blankTarget: blankTarget)
        markedup.finishParagraph()
    }
    
    func displaySeq(_ field: NoteField, note: Note, collection: NoteCollection, markedup: Markedup) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properWithParent)
        markedup.append(": ")
        let display1 = field.value.valueToDisplay()
        markedup.append(display1)
        if !collection.seqFormatter.isEmpty {
            if let seqValue = field.value as? SeqValue {
                if seqValue.multiCount == 1 {
                    let (full, _) = collection.seqFormatter.format(seq: seqValue.firstSeq, klassDef: note.klassDef, full: true)
                    let (formatted, _) = collection.seqFormatter.format(seq: seqValue.firstSeq, klassDef: note.klassDef)
                    var displayFull = false
                    var displaySimple = false
                    if full != display1 {
                        displayFull = true
                    }
                    
                    if formatted != display1 && formatted != full {
                        displaySimple = true
                    }
                    
                    if displayFull || displaySimple {
                        markedup.append(" (formatted as ")
                    }
                    
                    if displayFull {
                        markedup.append("'\(full)'")
                    }
                    
                    if displayFull && displaySimple {
                        markedup.append(" or simply ")
                    }
                    
                    if displaySimple {
                        markedup.append("'\(formatted)'")
                    }
                    
                    if displayFull || displaySimple {
                        markedup.append(")")
                    }
                }
            }
        }
        markedup.finishParagraph()
    }
    
    func displayEmail(_ field: NoteField, markedup: Markedup) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properForm)
        markedup.append(": ")
        let email = field.value.value
        var pathForLink = "mailto:\(email)"
        if email.starts(with: "mailto:") {
            pathForLink = email
        }
        
        markedup.link(text: email,
                  path: pathForLink,
                  blankTarget: true)
        markedup.finishParagraph()
    }
    
    func displayPhone(_ field: NoteField, markedup: Markedup) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properForm)
        markedup.append(": ")
        let phoneNumber = field.value.value
        var pathForLink = "tel:\(phoneNumber)"
        if phoneNumber.starts(with: "tel:") {
            pathForLink = phoneNumber
        }
        
        markedup.link(text: phoneNumber,
                  path: pathForLink,
                  blankTarget: true)
        markedup.finishParagraph()
    }
    
    func displayAddress(_ field: NoteField, markedup: Markedup) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properForm)
        markedup.append(": ")
        if let av = field.value as? AddressValue {
            markedup.link(text: field.value.value, path: av.link, blankTarget: true)
        } else {
            markedup.append(field.value.value)
        }
        markedup.finishParagraph()
    }
    
    func displayDirections(_ field: NoteField, markedup: Markedup) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properForm)
        markedup.append(": ")
        if let dv = field.value as? DirectionsValue {
            markedup.link(text: dv.valueToDisplay(), path: dv.link, blankTarget: true)
        } else {
            markedup.append(field.value.value)
        }
        markedup.finishParagraph()
    }
    
    /// Display a field without any special formatting.
    func displayStraight(_ field: NoteField, markedup: Markedup) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properWithParent)
        markedup.append(": ")
        markedup.append(field.value.valueToDisplay())
        markedup.finishParagraph()
    }
    
    func displayMarkdown(_ field: NoteField,
                         markedup: Markedup,
                         noteTitle: String,
                         note: Note,
                         mkdownContext: MkdownContext?) {
        markedup.startParagraph()
        markedup.append(field.def.fieldLabel.properWithParent)
        markedup.append(": ")
        markedup.finishParagraph()
        if parms.formatIsHTML {
            transformMarkdown(markdown: field.value.value,
                              fieldType: field.def.fieldType.typeString,
                              writer: markedup,
                              note: note,
                              shortID: note.shortID.value)
        } else {
            markedup.append(field.value.value)
            markedup.newLine()
        }
    }
    
    func displayLookBack(def: FieldDefinition, note: Note, markedup: Markedup) {
        let lkBkLines = MultiFileIO.shared.getLookBackLines(collectionID: note.collection.collectionID,
                                                            noteID: note.noteID.commonID, 
                                                            lkBkCommonLabel: def.fieldLabel.commonForm)
        guard !lkBkLines.isEmpty else { return }
        markedup.startDetails(summary: def.fieldLabel.properForm + ": ")
        markedup.startUnorderedList(klass: nil)
        for line in lkBkLines {
            markedup.startListItem()
            let openLink = "notenik://open?shortcut=\(def.lookupFrom)&id=\(line.noteIdCommon)"
            markedup.link(text: line.noteIdText, path: openLink)
            markedup.finishListItem()
        }
        markedup.finishUnorderedList()
        markedup.finishDetails()
    }
    
    /// Display a lookup field.
    func displayLookup(_ field: NoteField,
                       note: Note,
                       collection: NoteCollection,
                       markedup: Markedup,
                       io: NotenikIO?) {
        
        var detailsFound = false
        let shortcut = field.def.lookupFrom
        let lookupNote = MultiFileIO.shared.getNote(shortcut: shortcut, knownAs: field.value.value)
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
    
    /// Format a quotation using HTML figure and figcaption tags. 
    public func formatQuoteWithAttribution(note: Note,
                                           markedup: Markedup,
                                           parms: DisplayParms,
                                           io: NotenikIO?,
                                           bodyHTML: String? = nil,
                                           withAttrib: Bool = true) {
        
        self.io = io
        
        if withAttrib && (note.hasAttribution() || note.hasAuthor() || note.hasWorkTitle()) {
            markedup.startFigure(klass: "notenik-quote-attrib")
        }
        
        markedup.startBlockQuote()
        
        if bodyHTML != nil {
            markedup.append(bodyHTML!)
        } else {
            transformMarkdown(markdown: note.body.value,
                              fieldType: NotenikConstants.bodyCommon,
                              writer: markedup,
                              note: note,
                              shortID: note.shortID.value)
            /* markdownToMarkedup(markdown: note.body.value,
                               context: nil,
                               writer: markedup) */
        }
        
        markedup.finishBlockQuote()
        
        if withAttrib && (note.hasAttribution() || note.hasAuthor() || note.hasWorkTitle()) {
            markedup.startFigureCaption()
            if note.hasAttribution() {
                markedup.newLine()
                // let balanced = attribBalancer.balance(str: note.attribution.value)
                transformMarkdown(markdown: note.attribution.value,
                                  fieldType: NotenikConstants.attribCommon,
                                  writer: markedup,
                                  note: note,
                                  shortID: note.shortID.value)
                /* markdownToMarkedup(markdown: note.attribution.value,
                                   context: mkdownContext,
                                   writer: markedup) */
            } else {
                markedup.newLine()
                markedup.writeEmDash()
                markedup.writeNonBreakingSpace()
                var attrib = ""
                let author = note.creatorValue
                if author.count > 0 {
                    let authorLinkField = FieldGrabber.getField(note: note, label: NotenikConstants.authorLinkCommon)
                    var authorLink = ""
                    if authorLinkField != nil {
                        authorLink = authorLinkField!.value.value
                    }
                    if !authorLink.isEmpty {
                        attrib.append("<a href=\"\(authorLink)\" class=\"notenik-attrib-link\">")
                    }
                    attrib.append(author)
                    if !authorLink.isEmpty {
                        attrib.append("</a>")
                    }
                }
                
                if note.hasWorkTitle() {
                    if attrib.count > 3 {
                        attrib.append(", ")
                    }
                    let workLinkField = FieldGrabber.getField(note: note, label: note.collection.workLinkFieldDef.fieldLabel.commonForm)
                    var workLink = ""
                    if workLinkField != nil {
                        workLink = workLinkField!.value.value
                    }
                    if !workLink.isEmpty {
                        attrib.append("<a href=\"\(workLink)\" class=\"notenik-attrib-link\">")
                    }
                    /*
                    let workTypeField = FieldGrabber.getField(note: note, label: note.collection.workTypeFieldDef.fieldLabel.commonForm)
                    var workType = ""
                    if workTypeField != nil {
                        workType = workTypeField!.value.value.lowercased()
                    }
                    if !workType.isEmpty {
                        attrib.append("from the \(workType) titled ")
                    }
                    */
                    attrib.append("<cite>\(note.workTitle.value)</cite>")
                    if !workLink.isEmpty {
                        attrib.append("</a>")
                    }
                }
                
                if note.hasDate() {
                    if attrib.count > 0 {
                        attrib.append(", ")
                    }
                    attrib.append(note.date.value)
                }
                
                // let balanced = attribBalancer.balance(str: attrib, prepending: 3)
                markedup.writeLine(attrib)
            }
            markedup.finishFigureCaption()
            markedup.finishFigure()
        }
    }
    
    /// Format a quotation using HTML figure and figcaption tags.
    public func formatQuoteFromBiblio(note: Note,
                                      authorNote: Note?,
                                      workNote: Note?,
                                      markedup: Markedup,
                                      parms: DisplayParms,
                                      io: NotenikIO?) {
        
        self.io = io
        
        markedup.startBlockQuote(klass: "attribution-following")
        
        transformMarkdown(markdown: note.body.value,
                          fieldType: NotenikConstants.bodyCommon,
                          writer: markedup,
                          note: note,
                          shortID: note.shortID.value)
        
        markedup.finishBlockQuote()
        
        let quoteFrom = QuoteFrom()
        
        if authorNote != nil {
            quoteFrom.author = authorNote!.title.value
            if authorNote!.hasAKA() {
                quoteFrom.author = authorNote!.aka.value
            } else if authorNote!.title.value.contains(", ") {
                let author = AuthorValue(authorNote!.title.value)
                quoteFrom.author = author.firstNameFirst
            }
            quoteFrom.authorLink = parms.wikiLinks.assembleWikiLink(idBasis: authorNote!.title.value)
        }
        
        if workNote != nil {
            quoteFrom.workTitle = workNote!.title.value
            if workNote!.hasDate() {
                quoteFrom.pubDate = workNote!.date.value
            }
            quoteFrom.workType = workNote!.getFieldAsString(label: NotenikConstants.workTypeCommon)
            quoteFrom.workLink = parms.wikiLinks.assembleWikiLink(idBasis: workNote!.title.value)
        }
        
        quoteFrom.formatFrom(writer: markedup)
    }
    
    /// Convert Markdown to HTML.
    /* func markdownToMarkedup(markdown: String,
                            context: MkdownContext?,
                            writer: Markedup) {
        
        writer.append(Markdown.parse(markdown: markdown, options: mkdownOptions, context: context))
    } */
    
    func transformMarkdown(markdown: String,
                           fieldType: String,
                           writer: Markedup,
                           note: Note,
                           shortID: String) {
        let parserID = AppPrefs.shared.markdownParser
        guard io != nil else {
            Logger.shared.log(subsystem: "NotenikLib",
                              category: "NoteFieldsToHTML",
                              level: .error, message: "I/O module is missing")
            return
        }
        TransformMarkdown.mdToHtml(parserID: parserID,
                                   fieldType: fieldType,
                                   markdown: markdown,
                                   io: io!,
                                   parms: parms,
                                   results: results,
                                   noteID: note.noteID.commonID,
                                   noteText: note.noteID.text,
                                   noteFileName: note.noteID.commonFileName,
                                   note: note)
        if fieldType == NotenikConstants.attribCommon {
            let sansPara = StringUtils.removeParagraphTags(results.html)
            writer.startParagraph(klass: "quote-from")
            writer.append(sansPara)
            writer.finishParagraph()
        } else {
            writer.append(results.html)
        }
    }
    
    enum CiteType {
        case none
        case minor
        case major
    }
}
