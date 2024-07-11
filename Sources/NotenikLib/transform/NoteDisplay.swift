//
//  NoteDisplay.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
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
    public var mkdownOptions = MkdownOptions()
    public var mkdownContext: NotesMkdownContext?
    
    var includedNotes: [String] = []
    var mdBodyParser: MkdownParser?
    var mdResults = TransformMdResults()
    var expandedMarkdown: String? = nil
    
    public var results: TransformMdResults {
        return mdResults
    }
    
    public init() {
        
    }
    
    public func loadResourcePagesForCollection(io: NotenikIO, parms: DisplayParms) {
        guard parms.formatIsHTML && AppPrefs.shared.parseUsingNotenik else { return }
        guard let collection = io.collection else { return }
        mkdownOptions = MkdownOptions()
        for usage in collection.mkdownCommandList.commands {
            guard !usage.noteID.isEmpty else { continue }
            guard let noteWithCommand = io.getNote(knownAs: usage.noteID) else { continue }
            let noteBody = noteWithCommand.body.value
            parms.setMkdownOptions(mkdownOptions)
            mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
            mkdownContext!.setTitleToParse(id: noteWithCommand.noteID.commonID,
                                           text: noteWithCommand.noteID.text,
                                           fileName: noteWithCommand.noteID.commonFileName,
                                           shortID: noteWithCommand.shortID.value)
            mdBodyParser = MkdownParser(noteBody, options: mkdownOptions)
            mdBodyParser!.setWikiLinkFormatting(prefix: parms.wikiLinks.prefix,
                                                format: parms.wikiLinks.format,
                                                suffix: parms.wikiLinks.suffix,
                                                context: mkdownContext)
            mdBodyParser!.parse()
            
            noteWithCommand.mkdownCommandList = mkdownContext!.mkdownCommandList
            noteWithCommand.mkdownCommandList.updateWith(body: noteBody, html: mdBodyParser!.html)
            collection.mkdownCommandList.updateWith(noteList: noteWithCommand.mkdownCommandList)
        }
    }
    
    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Parameter io: The active I/O module for this Collection.
    /// - Parameter parms: Parms used to control the formatting of the display.
    /// - Parameter mdResults: The results of the Markdown transformation(s) performed.
    /// - Returns: A string containing the encoded note, and a flag indicating whether
    ///            any wiki link targets that did not yet exist were automatically added.
    ///
    public func display(_ note: Note,
                        io: NotenikIO,
                        parms: DisplayParms,
                        mdResults: TransformMdResults,
                        expandedMarkdown: String? = nil) -> String {

        self.parms = parms
        self.mdResults = mdResults
        self.expandedMarkdown = expandedMarkdown

        if note.hasShortID() {
            mkdownOptions.shortID = note.shortID.value
        } else {
            mkdownOptions.shortID = ""
        }

        // mkdownContext.setTitleToParse(title: note.title.value, shortID: note.shortID.value)
        let collection = note.collection
        collection.skipContentsForParent = false
        
        // Pre-parse the body field if we're generating HTML.
        if parms.formatIsHTML && AppPrefs.shared.parseUsingNotenik {
            
            var shortID = ""
            if note.hasShortID() {
                shortID = note.shortID.value
            }
            
            TransformMarkdown.mdToHtml(parserID: NotenikConstants.notenikParser,
                                       fieldType: NotenikConstants.bodyCommon,
                                       markdown: note.body.value,
                                       io: io,
                                       parms: parms,
                                       results: self.mdResults,
                                       noteTitle: note.title.value,
                                       shortID: shortID)
            
            if mdResults.mkdownContext != nil {
                note.mkdownCommandList = mdResults.mkdownContext!.mkdownCommandList
                note.mkdownCommandList.updateWith(body: note.body.value, html: mdResults.html)
                collection.mkdownCommandList.updateWith(noteList: note.mkdownCommandList)
                includedNotes = mdResults.mkdownContext!.includedNotes
            }
        }
        
        let position = io.positionOfNote(note)
        let topHTML = formatTopOfPage(note, io: io)
        let imageHTML = formatImage(note, io: io)
        let bottomHTML = formatBottomOfPage(note, io: io)
        if position.valid {
            _ = io.selectNote(at: position.index)
        }
        
        if parms.displayTemplate.count > 0 && parms.displayMode == .custom && parms.formatIsHTML {
            return displayWithTemplate(note, io: io)
        } else {
            return displayWithoutTemplate(note, io: io,
                                          topOfPage: topHTML,
                                          imageWithinPage: imageHTML,
                                          bottomOfPage: bottomHTML)
        }
    }
    
    /// If we have a note level greater than 1, then try to display the preceding Note just higher in
    /// the implied hierarchy.
    func formatTopOfPage(_ note: Note, io: NotenikIO) -> String {
        guard parms.displayMode == .streamlinedReading else { return "" }
        guard !parms.concatenated else { return "" }
        guard !parms.epub3 else { return "" }
        guard note.hasLevel() else { return "" }
        let noteLevel = note.level.level
        guard noteLevel > 1 else { return "" }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle else { return "" }
        var currentPosition = io.positionOfNote(note)
        var parentNote: Note?
        
        while currentPosition.valid {
            let (priorNote, priorPosition) = io.priorNote(currentPosition)
            currentPosition = priorPosition
            guard priorPosition.valid && priorNote != nil else { break }
            guard priorNote!.hasLevel() else { continue }
            if priorNote!.level.level < noteLevel {
                parentNote = priorNote!
                break
            }
        }
        guard parentNote != nil else { return "" }
        
        let topHTML = Markedup()
        topHTML.startParagraph()
        parms.streamlinedTitleWithLink(markedup: topHTML, note: parentNote!, klass: Markedup.htmlClassNavLink)
        topHTML.append("&#160;") // numeric code for non-breaking space
        topHTML.append("&#8593;") // Up arrow
        topHTML.finishParagraph()
        return topHTML.code
    }
    
    func formatImage(_ note: Note, io: NotenikIO) -> String {
        guard !parms.imagesPath.isEmpty else { return "" }
        guard let imageAttachment = note.getImageAttachment() else { return "" }
        
        var imageAlt = ""
        if let imageAltField = note.getField(label: NotenikConstants.imageAltCommon) {
            imageAlt = imageAltField.value.value
        }
        
        var imageCaption = ""
        if let imageCaptionField = note.getField(label: NotenikConstants.imageCaptionCommon) {
            imageCaption = imageCaptionField.value.value
        }
        
        var imageCaptionPrefix = ""
        var imageCaptionLink = ""
        var imageCaptionText = ""
        if let imageCreditField = note.getField(label: NotenikConstants.imageCreditCommon) {
            imageCaptionPrefix = "Image Credit: "
            imageCaptionText = imageCreditField.value.value
            if let imageCreditLinkField = note.getField(label: NotenikConstants.imageCreditLinkCommon) {
                imageCaptionLink = imageCreditLinkField.value.value
            }
        }
        
        var imagePath = ""
        if parms.imagesPath == NotenikConstants.filesFolderName {
            imagePath = parms.imagesPath + "/" + imageAttachment.fullName
        } else {
            imagePath = parms.imagesPath + "/" + imageAttachment.commonName
        }

        let imageHTML = Markedup()
        if imageCaption.isEmpty && imageCaptionText.isEmpty {
            imageHTML.image(alt: imageAlt, path: imagePath, title: imageAlt)
        } else if imageCaption.isEmpty {            
            imageHTML.startFigure()
            let pathFixed = imagePath.replacingOccurrences(of: "?", with: "%3F")
            imageHTML.image(alt: imageAlt, path: pathFixed, title: imageAlt)
            imageHTML.startFigureCaption()
            imageHTML.append(imageCaptionPrefix)
            if !imageCaptionLink.isEmpty {
                let blankTarget = parms.extLinksOpenInNewWindows
                imageHTML.startLink(path: imageCaptionLink, klass: "ext-link", blankTarget: blankTarget)
            }
            imageHTML.append(imageCaptionText)
            if !imageCaptionLink.isEmpty {
                imageHTML.finishLink()
            }
            imageHTML.finishFigureCaption()
            imageHTML.finishFigure()
        } else {
            imageHTML.image(path: imagePath,
                            alt: imageAlt,
                            title: imageAlt,
                            caption: imageCaption)
        }
        
        return imageHTML.code
    }
    
    /// In a sequenced list, show upcoming Notes.
    func formatBottomOfPage(_ note: Note, io: NotenikIO) -> String {
        
        // See if we meet necessary conditions.
        guard parms.displayMode != .normal else { return "" }
        guard !parms.concatenated else { return "" }
        guard note.collection.seqFieldDef != nil || parms.displayMode == .quotations else { return "" }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle || parms.displayMode == .quotations else { return "" }
        
        let bottomHTML = Markedup()
        
        let currentPosition = io.positionOfNote(note)
        let currDepth = note.depth
        var (nextNote, nextPosition) = nextNote(startingPosition: currentPosition, startingNote: note, passedIO: io)
        guard nextPosition.valid && nextNote != nil else {
            backToTop(io: io, bottomHTML: bottomHTML)
            return bottomHTML.code
        }
        
        var nextBasis = nextNote!.noteID.getBasis()
        var nextText  = nextNote!.noteID.text
        var nextLevel = nextNote!.level
        var nextSeq = nextNote!.seq
        var nextDepth = nextNote!.depth
        
        var skipTitleWithSeq = ""
        var skipTitle = ""
        
        if note.collection.levelFieldDef != nil {
            let includeChildren = note.includeChildren
            if includeChildren.on {
                (nextNote, nextPosition) = formatIncludedChildren(note,
                                                   io: io,
                                                   nextNote: nextNote!,
                                                   nextPosition: nextPosition,
                                                   nextLevel: nextLevel,
                                                   nextSeq: nextSeq,
                                                   bottomHTML: bottomHTML)
            }
            (nextNote, nextPosition) = skipNonMainPageTypes(startingPosition: nextPosition, startingNote: nextNote, passedIO: io)
            if nextNote != nil && nextPosition.valid {
                nextBasis = nextNote!.noteID.getBasis()
                nextText  = nextNote!.noteID.text
                nextLevel = nextNote!.level
                nextSeq = nextNote!.seq
                nextDepth = nextNote!.depth
                if !note.collection.skipContentsForParent {
                    formatToCforBottom(note,
                                       io: io,
                                       nextNote: nextNote!,
                                       nextPosition: nextPosition,
                                       nextLevel: nextLevel,
                                       nextSeq: nextSeq,
                                       bottomHTML: bottomHTML)
                }
            } else {
                nextBasis = ""
                nextText  = ""
            }
        }
        
        if parms.displayMode == .streamlinedReading && nextNote != nil && !nextBasis.isEmpty && nextDepth > currDepth {
            (skipTitleWithSeq, skipTitle) = skipDetails(note, io: io, nextNote: nextNote!, nextPosition: nextPosition)
        }
        
        if !parms.epub3 {
            if parms.displayMode == .quotations {
                bottomHTML.startDiv(klass: nil)
                bottomHTML.startParagraph()
                bottomHTML.link(text: "Next", path: parms.wikiLinks.assembleWikiLink(idBasis: nextBasis), klass: Markedup.htmlClassNavLink)
                bottomHTML.append(" &nbsp; ")
                guard let collection = io.collection else { return "" }
                var str = "notenik://open?"
                if collection.shortcut.count > 0 {
                    str.append("shortcut=\(collection.shortcut)")
                } else {
                    let folderURL = URL(fileURLWithPath: collection.fullPath)
                    let encodedPath = String(folderURL.absoluteString.dropFirst(7))
                    str.append("path=\(encodedPath)")
                }
                str.append("&select=random")
                bottomHTML.link(text: "Random", path: str, klass: Markedup.htmlClassNavLink)
                bottomHTML.finishParagraph()
                bottomHTML.finishDiv()
            } else if nextBasis.isEmpty {
                backToTop(io: io, bottomHTML: bottomHTML)
            } else if parms.displayMode == .streamlinedReading {
                bottomHTML.startDiv(klass: nil)
                if !skipTitle.isEmpty {
                    bottomHTML.startParagraph(klass: "float-left")
                } else {
                    bottomHTML.startParagraph()
                }
                bottomHTML.append("Next: ")
                bottomHTML.link(text: nextText, path: parms.wikiLinks.assembleWikiLink(idBasis: nextBasis), klass: Markedup.htmlClassNavLink)
                bottomHTML.finishParagraph()
                if !skipTitle.isEmpty {
                    bottomHTML.startParagraph(klass: "float-right")
                    bottomHTML.append("Skip to: ")
                    bottomHTML.link(text: skipTitleWithSeq,
                                    path: parms.wikiLinks.assembleWikiLink(idBasis: skipTitle),
                                    klass: Markedup.htmlClassNavLink)
                    bottomHTML.finishParagraph()
                }
                bottomHTML.finishDiv()
            } else if parms.displayMode == .presentation {
                bottomHTML.startParagraph()
                bottomHTML.link(text: "Next", path: parms.wikiLinks.assembleWikiLink(idBasis: nextBasis), klass: Markedup.htmlClassNavLink)
                bottomHTML.finishParagraph()
            }
        }
        
        return bottomHTML.code
    }
    
    public func nextNote(startingPosition: NotePosition, startingNote: Note?, passedIO: NotenikIO) -> (Note?, NotePosition) {
        guard startingPosition.valid && startingNote != nil else { return (startingNote, startingPosition) }
        var (nextNote, nextPosition) = passedIO.nextNote(startingPosition)
        (nextNote, nextPosition) = skipNonMainPageTypes(startingPosition: nextPosition, startingNote: nextNote, passedIO: passedIO)
        return (nextNote, nextPosition)
    }
    
    func skipNonMainPageTypes(startingPosition: NotePosition, startingNote: Note?, passedIO: NotenikIO) -> (Note?, NotePosition) {
        guard startingPosition.valid && startingNote != nil else { return (startingNote, startingPosition) }
        var nextNote: Note? = startingNote
        var nextPosition: NotePosition = startingPosition
        while nextNote != nil && nextNote!.excludeFromBook(epub: parms.epub3) {
            (nextNote, nextPosition) = passedIO.nextNote(nextPosition)
        }
        return (nextNote, nextPosition)
    }
    
    func backToTop(io: NotenikIO, bottomHTML: Markedup) {
        let (firstNote, _) = io.firstNote()
        guard firstNote != nil else { return }
        let firstBasis = firstNote!.noteID.getBasis() 
        let firstText = firstNote!.noteID.text
        bottomHTML.startParagraph()
        bottomHTML.append("Back to Top: ")
        bottomHTML.link(text: firstText, path: parms.wikiLinks.assembleWikiLink(idBasis: firstBasis), klass: Markedup.htmlClassNavLink)
        bottomHTML.finishParagraph()
    }
    
    func skipDetails(_ note: Note,
                     io: NotenikIO,
                     nextNote: Note,
                     nextPosition: NotePosition) -> (String, String) {
        
        let startingDepth = note.depth
        var followingNote: Note?
        followingNote = nextNote
        var followingPosition = nextPosition
        var followingDepth = nextNote.depth
        
        while followingNote != nil && followingPosition.valid && followingDepth > startingDepth {
            let (nextUpNote, nextUpPosition) = io.nextNote(followingPosition)
            followingNote = nextUpNote
            followingPosition = nextUpPosition
            if followingNote != nil {
                followingDepth = followingNote!.depth
            }
        }
        if followingNote != nil {
            return (followingNote!.getTitle(withSeq: true, formattedSeq: true), followingNote!.title.value)
        } else {
            return ("", "")
        }
    }
    
    func formatIncludedChildren(_ note: Note,
                                io: NotenikIO,
                                nextNote: Note,
                                nextPosition: NotePosition,
                                nextLevel: LevelValue,
                                nextSeq: SeqValue,
                                bottomHTML: Markedup) -> (Note?, NotePosition) {
        
        var followingNote: Note?
        followingNote = nextNote
        var followingPosition = nextPosition
        var followingLevel = LevelValue(i: nextLevel.getInt(), config: io.collection!.levelConfig)
        var followingSeq = nextSeq.dupe()
        
        let startingFormat = parms.format
        parms.format = .htmlFragment
        
        var displayedChildCount = 0
        
        while followingNote != nil
                && followingPosition.valid
                && followingLevel > note.level
                && followingLevel == nextLevel
                && followingSeq > note.seq {
            
            let fieldsToHTML = NoteFieldsToHTML()
            parms.included = note.includeChildren.copy()
            
            let (nextUpNote, nextUpPosition) = io.nextNote(followingPosition)
            
            let lastInList = nextUpNote == nil || nextUpPosition.invalid || nextUpNote!.level <= note.level || nextUpNote!.seq <= note.seq
            
            var alreadyIncluded = false
            let followingID = followingNote!.noteID.commonID
            for includedNote in includedNotes {
                if followingID == includedNote {
                    alreadyIncluded = true
                    break
                }
            }
            
            if !alreadyIncluded {
                let childResults = TransformMdResults()
                let childDisplay = fieldsToHTML.fieldsToHTML(followingNote!,
                                                             io: io,
                                                             parms: parms,
                                                             topOfPage: "",
                                                             imageWithinPage: "",
                                                             results: childResults,
                                                             bottomOfPage: "",
                                                             lastInList: lastInList)
                bottomHTML.append(childDisplay)
                displayedChildCount += 1
            }
            
            followingNote = nextUpNote
            followingPosition = nextUpPosition

            if followingNote != nil {
                followingLevel = followingNote!.level
                followingSeq = followingNote!.seq
            }
        }
        
        parms.format = startingFormat
        
        if followingNote == nil {
            return (followingNote, followingPosition)
        } else {
            if displayedChildCount > 0 {
                bottomHTML.horizontalRule()
            }
            return (followingNote, followingPosition)
        }
    }
    
    func formatToCforBottom(_ note: Note,
                            io: NotenikIO,
                            nextNote: Note,
                            nextPosition: NotePosition,
                            nextLevel: LevelValue,
                            nextSeq: SeqValue,
                            bottomHTML: Markedup) {

        var tocNotes: [Note] = []
        if nextLevel > note.level && nextSeq > note.seq {
            tocNotes.append(nextNote)
            let tocLevel = nextLevel
            var (anotherNote, anotherPosition) = io.nextNote(nextPosition)
            while anotherNote != nil && anotherNote!.level >= tocLevel {
                if anotherNote!.level == tocLevel && anotherNote!.includeInBook(epub: parms.epub3) {
                    tocNotes.append(anotherNote!)
                }
                (anotherNote, anotherPosition) = io.nextNote(anotherPosition)
            }
            if tocNotes.count > 1 {
                bottomHTML.heading(level: 4, text: "Contents")
                bottomHTML.startUnorderedList(klass: "notenik-toc")
                for tocNote in tocNotes {
                    bottomHTML.startListItem()
                    parms.streamlinedTitleWithLink(markedup: bottomHTML, note: tocNote, klass: Markedup.htmlClassNavLink)
                    bottomHTML.finishListItem()
                }
                bottomHTML.finishUnorderedList()
                bottomHTML.horizontalRule()
            }
        }
    }
    
    func displayWithTemplate(_ note: Note, io: NotenikIO) -> String {
        let template = Template()
        template.openTemplate(templateContents: parms.displayTemplate)
        let notesList = NotesList()
        notesList.append(note)
        template.supplyData(note,
                            dataSource: note.collection.title,
                            io: io,
                            bodyHTML: mdResults.bodyHTML,
                            minutesToRead: mdResults.minutesToRead)
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
                                imageWithinPage: String,
                                bottomOfPage: String) -> String {
        
        let fieldsToHTML = NoteFieldsToHTML()
        parms.included.reset()
        return fieldsToHTML.fieldsToHTML(note,
                                         io: io,
                                         parms: parms,
                                         topOfPage: topOfPage,
                                         imageWithinPage: imageWithinPage,
                                         results: mdResults,
                                         bottomOfPage: bottomOfPage,
                                         expandedMarkdown: expandedMarkdown)
    }

    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField, 
                 note: Note,
                 collection: NoteCollection,
                 io: NotenikIO) -> String {
        
        mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
        let code = Markedup(format: parms.format)
        if field.def == collection.titleFieldDef {
            mkdownContext!.setTitleToParse(id: note.noteID.commonID,
                                           text: note.noteID.text,
                                           fileName: note.noteID.commonFileName,
                                           shortID: note.shortID.value)
            code.displayLine(opt: collection.titleDisplayOption,
                             text: field.value.value,
                             depth: note.depth,
                             addID: true,
                             idText: field.value.value)
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
                if AppPrefs.shared.parseUsingNotenik {
                    code.append(mdBodyParser!.html)
                } else {
                    code.append(parseMarkdown(field.value.value, context: mkdownContext!))
                }
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
                    field.def.fieldType.typeString == NotenikConstants.teaserCommon ||
                    field.def.fieldType.typeString == NotenikConstants.bodyCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            if parms.formatIsHTML {
                code.append(parseMarkdown(field.value.value, context: mkdownContext!))
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
            if mdResults.minutesToRead != nil {
                code.append(mdResults.minutesToRead!.value)
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
    
    func parseMarkdown(_ md: String, context: MkdownContext) -> String {
        let markdown = Markdown()
        markdown.md = md
        markdown.mkdownOptions = mkdownOptions
        markdown.context = context
        markdown.parse()
        return markdown.html
    }
    
}
