//
//  NoteDisplay.swift
//  Notenik
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 - 2022 Herb Bowie (https://hbowie.net)
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
    
    var includedNotes: [String] = []
    var mdBodyParser: MkdownParser?
    var bodyHTML:     String?
    
    public var counts = MkdownCounts()
    
    public var wikilinks: WikiLinkList?
    
    var minutesToRead: MinutesToReadValue?
    
    public init() {
        
    }
    
    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Parameter io: The active I/O module for this Collection.
    /// - Parameter parms: Parms used to control the formatting of the display.
    /// - Returns: A string containing the encoded note, and a flag indicating whether
    ///            any wiki link targets that did not yet exist were automatically added.
    ///
    public func display(_ note: Note, io: NotenikIO, parms: DisplayParms) -> (code: String, wikiAdds: Bool) {
        self.parms = parms
        parms.setMkdownOptions(mkdownOptions)
        let mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
        mkdownContext.setTitleToParse(title: note.title.value)
        let collection = note.collection
        collection.skipContentsForParent = false
        minutesToRead = nil
        mdBodyParser = nil
        bodyHTML = nil
        wikilinks = nil
        var wikiAdds = false
        
        // Pre-parse the body field if we're generating HTML.
        if parms.formatIsHTML && AppPrefs.shared.parseUsingNotenik {
            let body = note.body
            mdBodyParser = MkdownParser(body.value, options: mkdownOptions)
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
            wikilinks = mdBodyParser!.wikiLinkList
            includedNotes = mkdownContext.includedNotes
            if collection.missingTargets {
                for link in mdBodyParser!.wikiLinkList.links {
                    if !link.targetFound {
                        let newNote = Note(collection: note.collection)
                        _ = newNote.setTitle(link.originalTarget.item)
                        newNote.setID()
                        if collection.backlinksDef == nil {
                            _ = newNote.setBody("Created by Wiki-style Link found in the body of the Note titled [[\(note.title.value)]].")
                        } else {
                            _ = newNote.setBacklinks(note.title.value)
                            _ = newNote.setBody("Created by Wiki-style Link found in the body of the Note titled \(note.title.value).")
                        }
                        _ = io.addNote(newNote: newNote)
                        wikiAdds = true
                    }
                }
            }
        }
        
        let position = io.positionOfNote(note)
        let topHTML = formatTopOfPage(note, io: io)
        let imageHTML = formatImage(note, io: io)
        let bottomHTML = formatBottomOfPage(note, io: io)
        if position.valid {
            _ = io.selectNote(at: position.index)
        }
        
        if parms.displayTemplate.count > 0 {
            return (displayWithTemplate(note, io: io), wikiAdds)
        } else {
            return (displayWithoutTemplate(note, io: io,
                                           topOfPage: topHTML,
                                           imageWithinPage: imageHTML,
                                           bottomOfPage: bottomHTML), wikiAdds)
        }
    }
    
    /// If we have a note level greater than 1, then try to display the preceding Note just higher in
    /// the implied hierarchy.
    func formatTopOfPage(_ note: Note, io: NotenikIO) -> String {
        guard parms.streamlined else { return "" }
        guard !parms.concatenated else { return ""}
        guard note.hasLevel() else { return parms.header }
        let noteLevel = note.level.level
        guard noteLevel > 1 else { return parms.header }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle else { return parms.header }
        var klass = KlassValue()
        if note.collection.klassFieldDef != nil {
            klass = note.klass
        }
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
        guard !parentTitle.isEmpty else { return parms.header }
        let topHTML = Markedup()
        topHTML.append(parms.header)
        topHTML.startParagraph()
        if parentSeq.count > 0 {
            if !klass.frontOrBack {
                topHTML.append("\(parentSeq) ")
            }
        }
        topHTML.link(text: parentTitle, path: parms.assembleWikiLink(title: parentTitle), klass: Markedup.htmlClassNavLink)
        topHTML.append("&nbsp;")
        topHTML.append("&#8593;")
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
            imageHTML.image(path: imagePath,
                            alt: imageAlt,
                            title: imageAlt,
                            captionPrefix: imageCaptionPrefix,
                            captionText: imageCaptionText,
                            captionLink: imageCaptionLink)
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
        guard parms.streamlined else { return "" }
        guard !parms.concatenated else { return ""}
        guard note.collection.seqFieldDef != nil else { return "" }
        let sortParm = parms.sortParm
        guard sortParm == .seqPlusTitle else { return "" }
        
        let bottomHTML = Markedup()
        
        let currentPosition = io.positionOfNote(note)
        var (nextNote, nextPosition) = io.nextNote(currentPosition)
        guard nextPosition.valid && nextNote != nil else {
            backToTop(io: io, bottomHTML: bottomHTML)
            return bottomHTML.code
        }
        
        var nextTitle = nextNote!.title.value
        var nextLevel = nextNote!.level
        var nextSeq = nextNote!.seq
        
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
            if nextNote != nil && nextPosition.valid {
                nextTitle = nextNote!.title.value
                nextLevel = nextNote!.level
                nextSeq = nextNote!.seq
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
                nextTitle = ""
            }
        }
        
        if nextTitle.isEmpty {
            backToTop(io: io, bottomHTML: bottomHTML)
        } else {
            bottomHTML.startParagraph()
            bottomHTML.append("Next: ")
            bottomHTML.link(text: nextTitle, path: parms.assembleWikiLink(title: nextTitle), klass: Markedup.htmlClassNavLink)
            bottomHTML.finishParagraph()
        }
        
        return bottomHTML.code
    }
    
    func backToTop(io: NotenikIO, bottomHTML: Markedup) {
        let (firstNote, _) = io.firstNote()
        guard firstNote != nil else { return }
        let firstTitle = firstNote!.title.value
        bottomHTML.startParagraph()
        bottomHTML.append("Back to Top: ")
        bottomHTML.link(text: firstTitle, path: parms.assembleWikiLink(title: firstTitle), klass: Markedup.htmlClassNavLink)
        bottomHTML.finishParagraph()
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
            let followingID = followingNote!.noteID.identifier
            for includedNote in includedNotes {
                if followingID == includedNote {
                    alreadyIncluded = true
                    break
                }
            }
            
            if !alreadyIncluded {
                let childDisplay = fieldsToHTML.fieldsToHTML(followingNote!,
                                                             io: io,
                                                             parms: parms,
                                                             topOfPage: "",
                                                             imageWithinPage: "",
                                                             bodyHTML: nil,
                                                             minutesToRead: nil,
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
                if anotherNote!.level == tocLevel {
                    tocNotes.append(anotherNote!)
                }
                (anotherNote, anotherPosition) = io.nextNote(anotherPosition)
            }
            if tocNotes.count > 1 {
                bottomHTML.heading(level: 4, text: "Contents")
                bottomHTML.startUnorderedList(klass: "notenik-toc")
                for tocNote in tocNotes {
                    let tocTitle = tocNote.title.value
                    bottomHTML.startListItem()
                    if !tocNote.klass.frontOrBack {
                        bottomHTML.append("\(tocNote.formattedSeqForDisplay) ")
                    }
                    bottomHTML.link(text: tocTitle, path: parms.assembleWikiLink(title: tocTitle), klass: Markedup.htmlClassNavLink)
                    /*
                    let aka = tocNote.aka.value
                    if !aka.isEmpty && (tocTitle.count + aka.count) < 60 {
                        let (matched, unmatched) = StringUtils.matchCounts(str1: tocTitle, str2: aka)
                        var shorter = tocTitle.count
                        if aka.count < shorter {
                            shorter = aka.count
                        }
                        let matching: Double = Double(Double(matched) / Double(shorter))
                        if !(matching > 0.60 || matched > unmatched) {
                            bottomHTML.startEmphasis()
                            bottomHTML.append(" (aka: \(aka))")
                            bottomHTML.finishEmphasis()
                        }
                    } */
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
                                imageWithinPage: String,
                                bottomOfPage: String) -> String {
        
        let fieldsToHTML = NoteFieldsToHTML()
        parms.included.reset()
        return fieldsToHTML.fieldsToHTML(note,
                                         io: io,
                                         parms: parms,
                                         topOfPage: topOfPage,
                                         imageWithinPage: imageWithinPage,
                                         bodyHTML: bodyHTML,
                                         minutesToRead: minutesToRead,
                                         bottomOfPage: bottomOfPage)
    }

    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField, note: Note, collection: NoteCollection, io: NotenikIO) -> String {
        
        let mkdownContext = NotesMkdownContext(io: io, displayParms: parms)
        let code = Markedup(format: parms.format)
        if field.def == collection.titleFieldDef {
            mkdownContext.setTitleToParse(title: field.value.value)
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
                    code.append(parseMarkdown(field.value.value, context: mkdownContext))
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
                code.append(parseMarkdown(field.value.value, context: mkdownContext))
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
    
    func parseMarkdown(_ md: String, context: MkdownContext) -> String {
        let markdown = Markdown()
        markdown.md = md
        markdown.mkdownOptions = mkdownOptions
        markdown.context = context
        markdown.parse()
        return markdown.html
    }
    
}
