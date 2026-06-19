//
//  NoteFieldsToPresent.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/12/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// Generate the coding necessary to display a Note as part of a Presentation.
public class NoteFieldsToPresent {
    
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
    
    var contentContainer = false
    
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
        // self.minutesToRead = results.minutesToRead
        
        // var tagsDisplayed = false
        contentContainer = false
        
        let collection = note.collection
        let dict = collection.dict
        
        // Start the Markedup code generator.
        let code = Markedup(format: parms.format)
        
        var noteTitle = note.title.plain
        var suffix = parms.titleSuffix
        if !suffix.isEmpty && suffix.last!.isWhitespace {
            suffix.removeLast()
        }
        if !suffix.isEmpty {
            if suffix.last!.isPunctuation {
                noteTitle = pop.toXML(suffix + " " + note.title.plain)
            } else {
                noteTitle = pop.toXML(note.title.plain + " " + suffix)
            }
        }
        
        // See if we have a meta description value
        var desc: String? = nil
        if parms.descriptionCode == .longTitle && note.hasLongTitle() {
            desc = note.longTitle.value
        }
        if parms.descriptionCode == .teaser && note.hasTeaser() {
            desc = note.teaser.value
        }
        if desc == nil && parms.descriptionCode != .none && results.bodyText != nil {
            desc = StringUtils.summarize(results.bodyText!, max: 160, ellipsis: true, trailingPeriod: false)
        }
        
        // Determine the author to identify (if any)
        var author = ""
        if !parms.author.isEmpty {
            let creator = note.creator
            if !creator.isEmpty {
                if let authorValue = creator as? AuthorValue {
                    author = authorValue.firstNameFirst
                } else {
                    author = creator.value
                }
            } else if note.hasKlass() {
                if note.klass.value == "author" {
                    if note.hasAKA() {
                        author = note.aka.value
                    } else {
                        let authorTitle = note.title.value
                        if authorTitle.contains(", ") {
                            let authorValue = AuthorValue(authorTitle)
                            author = authorValue.firstNameFirst
                        } else {
                            author = note.title.value
                        }
                    }
                }
            } else {
                author = parms.author
            }
        }
        
        // Start the document now, creating the head section
        let headInfo = MarkedupHeadInfo(withTitle: noteTitle,
                                        withAuthor: author,
                                        withJS: mkdownOptions.getHtmlScript(),
                                        addins: parms.addins)
        parms.setCSS(headInfo: headInfo,
                     note: note,
                     displayBoost: true,
                     boostFactor: parms.boostFactor)
        code.startDoc(headInfo: headInfo,
                      epub3: parms.epub3)
        
        code.startDiv(klass: "slide")
        
        // See if we need to start a list of included children.
        startListOfChildren(code: code)
        
        var headerContents = ""
        if note.treatAsTitlePage {
            headerContents = parms.header
        } else {
            headerContents = parms.header + collection.mkdownCommandList.getCodeFor(MkdownConstants.headerCmd)
        }
        
        let headerAndNav = true
        if headerAndNav {
            if note.mkdownCommandList.contentPage && !parms.included.hasData {
                if !headerContents.isEmpty {
                    code.header(headerContents, klass: "nnk-header")
                }
                let navCode = collection.mkdownCommandList.getCodeFor(MkdownConstants.navCmd)
                if !navCode.isEmpty && !note.klass.title {
                    code.nav(navCode, klass: "nnk-nav")
                }
            }
        }
        
        code.startMain(klass: "pitch")
        
        // Start with top of page code, if we have any.
        if !self.topOfPage.isEmpty {
            code.append(self.topOfPage)
        }
        
        // Start an included item, if needed.
        startIncludedItem(code: code)
        
        // Now let's display each of the fields, in dictionary order.
        var i = 0
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                let field = note.getField(def: def!)
                if field != nil && field!.value.hasData {
                    if field!.def == collection.tagsFieldDef {
                        // ignore
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
                    } else if field!.def == collection.inclusionsDef {
                        // ignore for now
                    } else if field!.def == collection.includedByDef {
                        // ignore for now
                    } else if field!.def.fieldType.typeString == NotenikConstants.pageStyleCommon {
                        // don't display as separate field
                    } else if field!.def == collection.attribFieldDef {
                        // not used for presentation
                    } else {
                        code.append(display(field!, noteTitle: noteTitle, note: note, collection: collection, io: io))
                        if field!.def == collection.titleFieldDef {
                            if !imageWithinPage.isEmpty && !contentContainer && note.imageLayout.enumValue == .belowTitleFullWidth {
                                code.append(imageWithinPage)
                            }
                        }
                    }
                }
            }
            i += 1
        }
        
        // Finish up an included item, if needed.
        finishIncludedItem(code: code)
        
        if !imageWithinPage.isEmpty && !contentContainer && note.imageLayout.enumValue == .belowBodyFullWidth {
            code.append(imageWithinPage)
        }
        
        if contentContainer {
            code.finishDiv()
            code.startDiv(klass: "content-item")
            code.append(imageWithinPage)
            code.finishDiv()
            code.finishDiv()
        }
        
        code.finishMain()
        
        // Now add the bottom of the page, if any.
        if !bottomOfPage.isEmpty {
            code.horizontalRule()
            code.append(bottomOfPage)
        }
        
        // If this is the last included child, and if a list was requested, finish it off.
        if lastInList {
            finishListOfChildren(code: code)
        }
        
        let footerCode = collection.mkdownCommandList.getCodeFor(MkdownConstants.footerCmd)
        if !footerCode.isEmpty && !parms.included.hasData {
            if note.includeInBook(epub: parms.epub3) {
                code.footer(footerCode, klass: "nnk-footer")
            } else if parms.displayMode == .presentation {
                code.footer(footerCode, klass: "nnk-footer")
            }
        }

        
        // Finish off the entire document.
        code.finishDiv()
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
                                                   shortID: note.shortID.value,
                                                   initialDisplay: true)
                if let nmkdcontext = mkdownContext as? NotesMkdownContext {
                    nmkdcontext.clearIncludedNotes()
                }
            }
        // Format the tags field
        } else if field.def == collection.tagsFieldDef && parms.displayTags {
            // No tags for the presentation
        } else if field.def == collection.bodyFieldDef {
            displayBody(field,
                        note: note,
                        collection: collection,
                        mkdownContext: mkdownContext,
                        markedup: code)
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
            case NotenikConstants.imageLayoutCommon:
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
        }

        return String(describing: code)
    }
    
    func displayBody(_ field: NoteField,
                     note: Note,
                     collection: NoteCollection,
                     mkdownContext: MkdownContext?,
                     markedup: Markedup) {
        
        if parms.formatIsHTML {
            if note.klass.quote {
                if note.hasAttribution() {
                    markedup.startBlockQuote(klass: "attribution-following")
                } else {
                    markedup.startBlockQuote()
                }
                // quoted = true
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
    
    // Display the Title of the Note in one of several possible formats.
    func displayTitle(note: Note, noteTitle: String, markedup: Markedup) {
        
        var titleToDisplay = parms.compoundTitle(note: note, titleFormat: .html)
        
        var style = "clear:both;"
        var depth = note.depth
        if note.klass.title {
            style.append("margin-top:2em;margin-bottom:3em;")
        } else {
            if note.collection.slideDepth > 0 {
                depth = note.collection.slideDepth
            } else {
                note.collection.slideDepth = depth
            }
        }
        markedup.displayLine(opt: note.collection.titleDisplayOption,
                             text: titleToDisplay,
                             depth: depth,
                             addID: true,
                             idText: note.title.value,
                             style: style)
        
        if !note.klass.title {
                
            markedup.startDiv(klass: "top-divider")
            
            markedup.startDiv(klass: "top-divider-hr")
            markedup.horizontalRule(klass: "pitch-divider-1")
            markedup.finishDiv()
            
            var homeBasis = ""
            var nextBasis = ""
            var priorBasis = ""
            if let navIO = io {
                if navIO.count > 1 {
                    let position = navIO.positionOfNote(note)
                    let index = position.index
                    if let homeNote = navIO.getSortedNote(at: 0) {
                        homeBasis = homeNote.note.noteID.basis
                    }
                    var nextIndex = index + 1
                    if nextIndex >= navIO.count {
                        nextIndex = 0
                        nextBasis = homeBasis
                    } else {
                        if let nextNote = navIO.getSortedNote(at: nextIndex) {
                            nextBasis = nextNote.note.noteID.basis
                        }
                    }
                    var priorIndex = index - 1
                    if priorIndex < 0 {
                        priorIndex = navIO.count - 1
                        if let lastNote = navIO.getSortedNote(at: priorIndex) {
                            priorBasis = lastNote.note.noteID.basis
                        }
                    } else {
                        if let priorNote = navIO.getSortedNote(at: priorIndex) {
                            priorBasis = priorNote.note.noteID.basis
                        }
                    }
                }
            }
            
            markedup.startDiv(klass: "top-divider-links")
            
            // Down arrow to go to next slide
            if !nextBasis.isEmpty {
                markedup.link(text: "&#x2193;", path: parms.wikiLinks.assembleWikiLink(idBasis: nextBasis), klass: "nav-link")
            }
            markedup.append("&nbsp;")
            if !priorBasis.isEmpty {
                markedup.link(text: "&#x2191;", path: parms.wikiLinks.assembleWikiLink(idBasis: priorBasis), klass: "nav-link")
            }
            markedup.append("&nbsp;")
            if !homeBasis.isEmpty {
                markedup.link(text: "&#x2302;", path: parms.wikiLinks.assembleWikiLink(idBasis: homeBasis), klass: "nav-link")
            }
            
            markedup.finishDiv()
            
            markedup.finishDiv()
        }
        
        if note.hasImageName(pref: .either) {
            if note.imageLayout.enumValue == .belowTitleRightSide {
                markedup.startDiv(klass: "content-container")
                contentContainer = true
                markedup.startDiv(klass: "content-item")
            }
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
    
}
