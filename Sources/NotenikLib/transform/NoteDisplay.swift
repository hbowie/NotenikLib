//
//  NoteDisplay.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
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
    
    let pop = PopConverter.shared
    
    public var parms = DisplayParms()
    public var mkdownOptions = MkdownOptions()
    public var mkdownContext: NotesMkdownContext?
    
    var imagePref: ImagePref = .light
    
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
            mkdownContext!.identifyNoteToParse(id: noteWithCommand.noteID.commonID,
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
    
    public func display(_ note: Note,
                        io: NotenikIO,
                        parms: DisplayParms,
                        mdResults: TransformMdResults,
                        expandedMarkdown: String? = nil,
                        imagePref: ImagePref = .light) -> String {
        let sortedNote = SortedNote(note: note)
        return display(sortedNote,
                       io: io,
                       parms: parms,
                       mdResults: mdResults,
                       expandedMarkdown: expandedMarkdown,
                       imagePref: imagePref)
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
    public func display(_ sortedNote: SortedNote,
                        io: NotenikIO,
                        parms: DisplayParms,
                        mdResults: TransformMdResults,
                        expandedMarkdown: String? = nil,
                        imagePref: ImagePref = .light) -> String {

        self.parms = parms
        self.mdResults = mdResults
        self.expandedMarkdown = expandedMarkdown
        self.imagePref = imagePref
        
        if parms.displayMode == .continuous {
            return displayCollection(sortedNote: sortedNote, io: io)
        } else if parms.displayMode == .continuousPartial {
            return displayPartial(sortedNote: sortedNote, io: io)
        } else {
            return displayOneNote(sortedNote, io: io, mdResults: mdResults)
        }
    }
    
    func displayCollection(sortedNote: SortedNote, io: NotenikIO) -> String {
        let otherResults = TransformMdResults()
        let position = io.positionOfNote(sortedNote)
        // Start the Markedup code generator.
        let code = Markedup(format: parms.format)
        var i = 0
        var nextNote = io.getSortedNote(at: i)
        var continuousPosition: ContinuousPosition = .first
        while nextNote != nil {
            if i == 0 {
                let noteTitle = pop.toXML(nextNote!.note.title.value)
                code.startDoc(withTitle: noteTitle,
                              withCSS: sortedNote.note.getCombinedCSS(cssString: parms.cssString),
                              linkToFile: parms.cssLinkToFile,
                              withJS: mkdownOptions.getHtmlScript(),
                              epub3: parms.epub3,
                              addins: parms.addins)
            }
            if nextNote!.note.noteID.id != sortedNote.note.noteID.id {
                code.append(displayOneNote(nextNote!, io: io, mdResults: otherResults, continuousPosition: continuousPosition))
            } else {
                code.append(displayOneNote(nextNote!, io: io, mdResults: mdResults, continuousPosition: continuousPosition))
            }
            i += 1
            nextNote = io.getSortedNote(at: i)
            if i == (io.notesCount - 1) {
                continuousPosition = .last
            } else {
                continuousPosition = .middle
            }
        }
        if position.valid {
            _ = io.selectNote(at: position.index)
        }
        
        let id = StringUtils.autoID(sortedNote.note.noteID.basis)
        var js = "window.addEventListener(\"load\", () => { \n"
        js.append("  document.getElementById('\(id)').scrollIntoView(); \n")
        js.append("});")
        code.startScript()
        code.append(js)
        code.finishScript()
        code.finishDoc()
        return code.code
    }
    
    func displayPartial(sortedNote: SortedNote, io: NotenikIO) -> String {
        guard let collection = io.collection else {
            return ""
        }
        let otherResults = TransformMdResults()
        let position = io.positionOfNote(sortedNote)
        // Start the Markedup code generator.
        let code = Markedup(format: parms.format)
        var i = 0
        var continuousPosition: ContinuousPosition = .first
        var nextNote = collection.displayedNotes.getNote(at: i)
        while nextNote != nil {
            if i == 0 {
                let noteTitle = pop.toXML(nextNote!.note.title.value)
                code.startDoc(withTitle: noteTitle,
                              withCSS: sortedNote.note.getCombinedCSS(cssString: parms.cssString),
                              linkToFile: parms.cssLinkToFile,
                              withJS: mkdownOptions.getHtmlScript(),
                              epub3: parms.epub3,
                              addins: parms.addins)
            }
            if nextNote!.noteID.id != sortedNote.note.noteID.id {
                code.append(displayOneNote(nextNote!, io: io, mdResults: otherResults, continuousPosition: continuousPosition))
            } else {
                code.append(displayOneNote(nextNote!, io: io, mdResults: mdResults, continuousPosition: continuousPosition))
            }
            i += 1
            nextNote = collection.displayedNotes.getNote(at: i)
            if i == (collection.displayedNotes.count - 1) {
                continuousPosition = .last
            } else {
                continuousPosition = .middle
            }
        }
        if position.valid {
            _ = io.selectNote(at: position.index)
        }
        
        let id = StringUtils.autoID(sortedNote.note.noteID.basis)
        var js = "window.addEventListener(\"load\", () => { \n"
        js.append("  document.getElementById('\(id)').scrollIntoView(); \n")
        js.append("});")
        code.startScript()
        code.append(js)
        code.finishScript()
        code.finishDoc()
        return code.code
    }
    
    func displayOneNote(_ sortedNote: SortedNote,
                        io: NotenikIO,
                        mdResults: TransformMdResults,
                        continuousPosition: ContinuousPosition = .middle) -> String {
        
        if sortedNote.note.hasShortID() {
            mkdownOptions.shortID = sortedNote.note.shortID.value
        } else {
            mkdownOptions.shortID = ""
        }

        // mkdownContext.setTitleToParse(title: note.title.value, shortID: note.shortID.value)
        let collection = sortedNote.note.collection
        collection.skipContentsForParent = false
        
        // Pre-parse the body field if we're generating HTML.
        if parms.formatIsHTML && AppPrefs.shared.parseUsingNotenik {
            
            TransformMarkdown.mdToHtml(parserID: NotenikConstants.notenikParser,
                                       fieldType: NotenikConstants.bodyCommon,
                                       markdown: sortedNote.note.body.value,
                                       io: io,
                                       parms: parms,
                                       results: self.mdResults,
                                       noteID: sortedNote.note.noteID.commonID,
                                       noteText: sortedNote.note.noteID.text,
                                       noteFileName: sortedNote.note.noteID.commonFileName,
                                       note: sortedNote.note)
            
            if mdResults.mkdownContext != nil {
                sortedNote.note.mkdownCommandList = mdResults.mkdownContext!.mkdownCommandList
                sortedNote.note.mkdownCommandList.updateWith(body: sortedNote.note.body.value, html: mdResults.html)
                collection.mkdownCommandList.updateWith(noteList: sortedNote.note.mkdownCommandList)
                includedNotes = mdResults.mkdownContext!.includedNotes
            }
        }
        
        let position = io.positionOfNote(sortedNote)
        let topHTML = formatTopOfPage(sortedNote, io: io)
        let imageHTML = formatImage(sortedNote.note, io: io)
        let bottomHTML = formatBottomOfPage(sortedNote, io: io)
        if position.valid {
            _ = io.selectNote(at: position.index)
        }
        
        if parms.displayTemplate.count > 0 && parms.displayMode == .custom && parms.formatIsHTML {
            return displayWithTemplate(sortedNote.note, io: io)
        } else {
            return displayWithoutTemplate(sortedNote.note,
                                          io: io,
                                          topOfPage: topHTML,
                                          imageWithinPage: imageHTML,
                                          bottomOfPage: bottomHTML,
                                          continuousPosition: continuousPosition)
        }
    }
    
    /// If we have a note level greater than 1, then try to display the preceding Note just higher in
    /// the implied hierarchy.
    func formatTopOfPage(_ sortedNote: SortedNote, io: NotenikIO) -> String {
        guard parms.displayMode == .streamlinedReading else { return "" }
        guard !parms.concatenated else { return "" }
        guard !parms.epub3 else { return "" }
        guard sortedNote.note.hasLevel() else { return "" }
        let noteLevel = sortedNote.note.level.level
        guard noteLevel > 1 else {
            return ""
        }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle else { return "" }
        var currentPosition = io.positionOfNote(sortedNote)
        var parentNote: SortedNote?
        
        while currentPosition.valid {
            let (priorNote, priorPosition) = io.priorNote(currentPosition)
            currentPosition = priorPosition
            guard priorPosition.valid && priorNote != nil else { break }
            guard priorNote!.note.hasLevel() else { continue }
            if priorNote!.note.level.level < noteLevel && !priorNote!.note.excludeFromBook(epub: parms.epub3){
                parentNote = priorNote
                break
            }
        }
        guard parentNote != nil else { return "" }
        
        let topHTML = Markedup()
        topHTML.startParagraph()
        parms.streamlinedTitleWithLink(markedup: topHTML, sortedNote: parentNote!, klass: Markedup.htmlClassNavLink)
        topHTML.append("&#160;") // numeric code for non-breaking space
        topHTML.append("&#8593;") // Up arrow
        topHTML.finishParagraph()
        return topHTML.code
    }
    
    func formatImage(_ note: Note, io: NotenikIO) -> String {
        guard !parms.imagesPath.isEmpty else { return "" }

        guard let imageAttachment = note.getImageAttachment(pref: imagePref) else { return "" }
        
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
            imageHTML.image(alt: imageAlt, path: imagePath, title: imageAlt, klass: NotenikConstants.imageKlass)
        } else if imageCaption.isEmpty {
            imageHTML.startFigure()
            let pathFixed = imagePath.replacingOccurrences(of: "?", with: "%3F")
            imageHTML.image(alt: imageAlt, path: pathFixed, title: imageAlt, klass: NotenikConstants.imageKlass)
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
    func formatBottomOfPage(_ sortedNote: SortedNote, io: NotenikIO) -> String {
        
        // See if we meet necessary conditions.
        guard parms.displayMode != .normal else { return "" }
        guard parms.displayMode != .continuous else { return "" }
        guard !parms.concatenated else { return "" }
        guard sortedNote.note.collection.seqFieldDef != nil || parms.displayMode == .quotations else { return "" }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle || parms.displayMode == .quotations else { return "" }
        
        let bottomHTML = Markedup()
        
        let currentPosition = io.positionOfNote(sortedNote)
        let currDepth = sortedNote.depth
        var (nextNote, nextPosition) = nextNote(startingPosition: currentPosition, startingNote: sortedNote, passedIO: io)
        guard nextPosition.valid && nextNote != nil else {
            backToTop(io: io, bottomHTML: bottomHTML)
            return bottomHTML.code
        }
        
        var nextBasis = nextNote!.noteID.getBasis()
        var nextLevel = nextNote!.note.level
        var nextSeq = nextNote!.seqSingleValue
        var nextDepth = nextNote!.depth
        
        var skipIdText = ""
        var skipIdBasis = ""
        
        if sortedNote.note.collection.levelFieldDef != nil {
            let includeChildren = sortedNote.note.includeChildren
            if includeChildren.on {
                (nextNote, nextPosition) = formatIncludedChildren(sortedNote,
                                                   io: io,
                                                   nextSortedNote: nextNote!,
                                                   nextPosition: nextPosition,
                                                   nextLevel: nextLevel,
                                                   nextSeq: nextSeq,
                                                   bottomHTML: bottomHTML)
            }
            (nextNote, nextPosition) = skipNonMainPageTypes(startingPosition: nextPosition,
                                                            startingNote: nextNote,
                                                            passedIO: io)
            if nextNote != nil
                && nextPosition.valid {
                nextBasis = nextNote!.noteID.getBasis()
                nextLevel = nextNote!.note.level
                nextSeq = nextNote!.seqSingleValue
                nextDepth = nextNote!.depth
                if nextNote!.noteID.commonID != "tableofcontents"
                    && nextNote!.note.klass.value != "toc" {
                    let collectionToC = sortedNote.note.mkdownCommandList.contains(MkdownConstants.collectionTocCmd)
                    if !sortedNote.note.collection.skipContentsForParent && !collectionToC {
                        formatToCforBottom(sortedNote,
                                           io: io,
                                           nextSortedNote: nextNote!,
                                           nextPosition: nextPosition,
                                           nextLevel: nextLevel,
                                           nextSeq: nextSeq,
                                           bottomHTML: bottomHTML)
                    }
                }
            } else {
                nextBasis = ""
            }
        }
        
        if parms.displayMode == .streamlinedReading && nextNote != nil && !nextBasis.isEmpty && nextDepth > currDepth {
            (skipIdText, skipIdBasis) = skipDetails(sortedNote, io: io, nextSortedNote: nextNote!, nextPosition: nextPosition)
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
                if !skipIdBasis.isEmpty {
                    bottomHTML.startParagraph(klass: "float-left")
                } else {
                    bottomHTML.startParagraph()
                }
                bottomHTML.append("Next: ")
                parms.streamlinedTitleWithLink(markedup: bottomHTML, sortedNote: nextNote!, klass: Markedup.htmlClassNavLink)
                bottomHTML.finishParagraph()
                if !skipIdBasis.isEmpty {
                    bottomHTML.startParagraph(klass: "float-right")
                    bottomHTML.append("Skip to: ")
                    bottomHTML.link(text: skipIdText,
                                    path: parms.wikiLinks.assembleWikiLink(idBasis: skipIdBasis),
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
    
    public func nextNote(startingPosition: NotePosition, startingNote: SortedNote?, passedIO: NotenikIO) -> (SortedNote?, NotePosition) {
        guard startingPosition.valid && startingNote != nil else { return (startingNote, startingPosition) }
        var (nextSortedNote, nextPosition) = passedIO.nextNote(startingPosition)
        (nextSortedNote, nextPosition) = skipNonMainPageTypes(startingPosition: nextPosition, startingNote: nextSortedNote, passedIO: passedIO)
        return (nextSortedNote, nextPosition)
    }
    
    func skipNonMainPageTypes(startingPosition: NotePosition, startingNote: SortedNote?, passedIO: NotenikIO) -> (SortedNote?, NotePosition) {
        guard startingPosition.valid && startingNote != nil else { return (startingNote, startingPosition) }
        var nextSortedNote: SortedNote? = startingNote
        var nextPosition: NotePosition = startingPosition
        while nextSortedNote != nil && nextSortedNote!.note.excludeFromBook(epub: parms.epub3) {
            (nextSortedNote, nextPosition) = passedIO.nextNote(nextPosition)
        }
        return (nextSortedNote, nextPosition)
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
    
    func skipDetails(_ sortedNote: SortedNote,
                     io: NotenikIO,
                     nextSortedNote: SortedNote,
                     nextPosition: NotePosition) -> (String, String) {
        
        let startingDepth = sortedNote.depth
        var followingNote: SortedNote?
        followingNote = nextSortedNote
        var followingPosition = nextPosition
        var followingDepth = nextSortedNote.depth
        
        while followingNote != nil && followingPosition.valid && followingDepth > startingDepth {
            let (nextUpNote, nextUpPosition) = io.nextNote(followingPosition)
            followingNote = nextUpNote
            followingPosition = nextUpPosition
            if followingNote != nil {
                followingDepth = followingNote!.depth
            }
        }
        if followingNote != nil {
            return (followingNote!.noteID.text, followingNote!.noteID.basis)
        } else {
            return ("", "")
        }
    }
    
    /// Include children on the parent's display.
    func formatIncludedChildren(_ sortedNote: SortedNote,
                                io: NotenikIO,
                                nextSortedNote: SortedNote,
                                nextPosition: NotePosition,
                                nextLevel: LevelValue,
                                nextSeq: SeqSingleValue,
                                bottomHTML: Markedup) -> (SortedNote?, NotePosition) {
        
        var followingNote: SortedNote?
        followingNote = nextSortedNote
        var followingPosition = nextPosition
        var followingLevel = LevelValue(i: nextLevel.getInt(), config: io.collection!.levelConfig)
        var followingSeq = nextSeq.dupe()
        
        let startingFormat = parms.format
        parms.format = .htmlFragment
        
        var displayedChildCount = 0
        
        while followingNote != nil
                && followingPosition.valid
                && followingLevel > sortedNote.note.level
                && followingSeq > sortedNote.seqSingleValue {
            
            let (nextUpNote, nextUpPosition) = io.nextNote(followingPosition)
            
            if followingLevel == nextLevel {
                let fieldsToHTML = NoteFieldsToHTML()
                parms.included = sortedNote.note.includeChildren.copy()
                
                let lastInList = nextUpNote == nil
                    || nextUpPosition.invalid
                    || nextUpNote!.note.level <= sortedNote.note.level
                    || nextUpNote!.seqSingleValue <= sortedNote.seqSingleValue
                
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
                    let childDisplay = fieldsToHTML.fieldsToHTML(followingNote!.note,
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
            }
            
            followingNote = nextUpNote
            followingPosition = nextUpPosition

            if followingNote != nil {
                followingLevel = followingNote!.note.level
                followingSeq = followingNote!.seqSingleValue
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
    
    func formatToCforBottom(_ sortedNote: SortedNote,
                            io: NotenikIO,
                            nextSortedNote: SortedNote,
                            nextPosition: NotePosition,
                            nextLevel: LevelValue,
                            nextSeq: SeqSingleValue,
                            bottomHTML: Markedup) {

        var tocNotes: [SortedNote] = []
        if nextLevel > sortedNote.note.level && nextSeq > sortedNote.seqSingleValue {
            tocNotes.append(nextSortedNote)
            let tocLevel = nextLevel
            var (anotherNote, anotherPosition) = io.nextNote(nextPosition)
            while anotherNote != nil && anotherNote!.note.level >= tocLevel {
                if anotherNote!.note.level == tocLevel && anotherNote!.note.includeInBook(epub: parms.epub3) {
                    tocNotes.append(anotherNote!)
                }
                (anotherNote, anotherPosition) = io.nextNote(anotherPosition)
            }
            if tocNotes.count > 0 {
                bottomHTML.heading(level: 4, text: "Contents")
                bottomHTML.startUnorderedList(klass: "notenik-toc")
                for tocNote in tocNotes {
                    bottomHTML.startListItem()
                    parms.streamlinedTitleWithLink(markedup: bottomHTML, sortedNote: tocNote, klass: Markedup.htmlClassNavLink)
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
                                bottomOfPage: String,
                                continuousPosition: ContinuousPosition = .middle) -> String {
        
        let fieldsToHTML = NoteFieldsToHTML()
        parms.included.reset()
        return fieldsToHTML.fieldsToHTML(note,
                                         io: io,
                                         parms: parms,
                                         topOfPage: topOfPage,
                                         imageWithinPage: imageWithinPage,
                                         results: mdResults,
                                         bottomOfPage: bottomOfPage,
                                         expandedMarkdown: expandedMarkdown,
                                         continuousPosition: continuousPosition)
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
            mkdownContext!.identifyNoteToParse(id: note.noteID.commonID,
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
