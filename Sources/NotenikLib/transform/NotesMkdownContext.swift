//
//  NotesMkdownContext.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/12/21.
//
//  Copyright © 2021 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// A class that can provide the Markdown parser with contextual information about
/// the environment from which the Markdown text was provided. 
public class NotesMkdownContext: MkdownContext {

    // -----------------------------------------------------------
    //
    // MARK: Initial setup.
    //
    // -----------------------------------------------------------
    
    var io: NotenikIO
    var displayParms = DisplayParms()
    
    let htmlConverter = StringConverter()
    
    public var includedNotes: [String] = []
    
    public init(io: NotenikIO, displayParms: DisplayParms? = nil) {
        self.io = io
        if displayParms != nil {
            self.displayParms = displayParms!
        }
        htmlConverter.addHTML()
    }
    
    /// Set the Title of the Note whose Markdown text is to be parsed.
    public func setTitleToParse(title: String) {
        guard let collection = io.collection else { return }
        collection.titleToParse = title
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Wiki Link Lookup.
    //
    // -----------------------------------------------------------
    
    /// Investigate an apparent link to another note, replacing it, if necessary, with
    /// a current and valid link.
    /// - Parameter title: A wiki link target that is possibly a timestamp instead of a title.
    /// - Returns: The corresponding title, if the lookup was successful, otherwise the title
    ///            that was passed as input.
    public func mkdownWikiLinkLookup(linkText: String) -> String? {
        
        guard io.collection != nil else { return linkText }
        guard io.collectionOpen else { return linkText }
        
        // Check for first possible case: title within the wiki link
        // points directly to another note having that same title.
        let titleID = StringUtils.toCommon(linkText)
        var linkedNote = io.getNote(forID: titleID)
        if linkedNote != nil {
            io.aliasList.add(titleID: titleID, timestamp: linkedNote!.timestampAsString)
            return linkedNote!.title.value
        }
        
        // Check for second possible case: title within the wiki link
        // uses the singular form of a word, but the word appears in its
        // plural form within the target note's title.
        linkedNote = io.getNote(forID: titleID + "s")
        if linkedNote != nil {
            return linkedNote!.title.value
        }
        
        // Check for third possible case: title within the wiki link
        // refers to an alias by which a Note is also known. 
        if io.collection!.akaFieldDef != nil {
            linkedNote = io.getNote(alsoKnownAs: titleID)
            if linkedNote != nil {
                return linkedNote!.title.value
            }
        }
        
        guard io.collection!.hasTimestamp else { return nil }
        
        // Check for fourth possible case: title within the wiki link
        // used to point directly to another note having that same title,
        // but the target note's title has since been modified.
        let timestamp = io.aliasList.get(titleID: titleID)
        if timestamp != nil {
            linkedNote = io.getNote(forTimestamp: timestamp!)
            if linkedNote != nil {
                return linkedNote!.title.value
            }
        }
        
        // Check for fifth possible case: string within the wiki link
        // is already a timestamp pointing to another note.
        guard linkText.count < 15 && linkText.count > 11 else { return linkText }
        linkedNote = io.getNote(forTimestamp: linkText)
        if linkedNote != nil {
            return linkedNote!.title.value
        }
        
        // Nothing worked, so return nada / zilch.
        return nil
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Collection Table of Contents.
    //
    // -----------------------------------------------------------
    
    var levelStart = 0
    var levelEnd = 999
    var hasLevel = false
    var hasSeq = false
    var hasLevelAndSeq: Bool {
        return hasLevel && hasSeq
    }
    var toc = Markedup(format: .htmlFragment)
    var levels: [Int] = []
    var lastLevel: Int {
        if levels.count > 0 {
            return levels[levels.count - 1]
        } else {
            return 0
        }
    }
    
    public func mkdownCollectionTOC(levelStart: Int, levelEnd: Int) -> String {
        self.levelStart = levelStart
        self.levelEnd = levelEnd
        guard io.collectionOpen else { return "" }
        guard let collection = io.collection else { return "" }
        collection.tocNoteID = StringUtils.toCommon(collection.titleToParse)
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        levels = []
        toc = Markedup(format: .htmlFragment)
        var (note, position) = io.firstNote()
        while note != nil {
            if note!.noteID.identifier != collection.tocNoteID {
                genTocEntry(for: note!)
            }
            (note, position) = io.nextNote(position)
        }
        closeTocEntries(downTo: 0)
        return toc.code
    }
    
    func genTocEntry(for note: Note) {
        var level = note.level.getInt()
        let seq = note.seq.value
        if hasLevelAndSeq && level <= 1 && seq.count == 0 { return }
        if !hasLevel { level = 1 }
        guard level >= levelStart else { return }
        guard level <= levelEnd else { return }
        
        // Manage nested lists.
        if level < lastLevel {
            closeTocEntries(downTo: level)
        } else if level == lastLevel {
            toc.finishListItem()
        } else if level > lastLevel {
            toc.startUnorderedList(klass: nil)
            levels.append(level)
        }
        
        // Display the next TOC entry
        toc.startListItem()
        if seq.count > 0 && !note.klass.frontOrBack {
            toc.write("\(seq) ")
        }
        let title = note.title.value
        let link = displayParms.assembleWikiLink(title: title)
        let text = htmlConverter.convert(from: title)
        toc.link(text: text, path: link)
    }
    
    func closeTocEntries(downTo: Int) {
        while lastLevel > downTo {
            toc.finishListItem()
            toc.finishUnorderedList()
            let top = levels.count - 1
            levels.remove(at: top)
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for an Index to the Collection.
    //
    // -----------------------------------------------------------
    
    var indexCollection  = IndexCollection()
    
    public var termCount = 0
    public var pageCount = 0
    
    /// Return an index to the Collection, formatted in HTML.
    public func mkdownIndex() -> String {
        
        // Spin through the collection and collection index terms and references.
        indexCollection  = IndexCollection()
        var (note, position) = io.firstNote()
        while note != nil {
            if note!.hasTitle() && note!.hasIndex() {
                let pageType = note!.getFieldAsString(label: NotenikConstants.typeCommon)
                indexCollection.add(page: note!.title.value, pageType: pageType, index: note!.index)
            }
            (note, position) = io.nextNote(position)
        }
        
        // Now sort the list of terms.
        indexCollection.sort()
        
        // Generate an index, formatted using Markdown.
        let mkdown = Markedup(format: .htmlFragment)
        termCount = 0
        pageCount = 0
        // var lastLetter = " "
        mkdown.startDefinitionList(klass: nil)
        for term in indexCollection.list {
            termCount += 1
            // let initialLetter = term.term.prefix(1).uppercased()
            
            /* if initialLetter != lastLetter {
                if lastLetter != " " {
                    mkdown.finishDefinitionList()
                }
                mkdown.heading(level: 2, text: "--- \(initialLetter) ---")
                lastLetter = initialLetter
                mkdown.startDefinitionList(klass: nil)
            } */
            mkdown.startDefTerm()
            mkdown.append(term.term)
            mkdown.finishDefTerm()
            for ref in term.refs {
                pageCount += 1
                mkdown.startDefDef()
                let link = displayParms.assembleWikiLink(title: ref.page)
                let text = htmlConverter.convert(from: ref.page)
                mkdown.link(text: text, path: link)
                mkdown.finishDefDef()
            }
        }
        mkdown.finishDefinitionList()
        return mkdown.code
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Tags Outline.
    //
    // -----------------------------------------------------------
  
    var tagsCode = Markedup(format: .htmlFragment)
    var tagsListLevel = 0
    
    /// Generate a separate page organized by Tags.
    public func mkdownTagsOutline(mods: String) -> String {
        guard io.collection != nil else { return "" }
        guard io.collectionOpen else { return "" }
        let includeUntagged = mods.isEmpty
        tagsCode = Markedup(format: .htmlFragment)
        tagsListLevel = 0
        openTagsList()
        let iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        while tagsNode != nil {
            generateTagsNode(node: tagsNode!, depth: iterator.depth, includeUntagged: includeUntagged)
            tagsNode = iterator.next()
        }
        closeTagContent(downTo: 0)
        return tagsCode.code
    }
    
    /// Generate html code for the next node.
    func generateTagsNode(node: TagsNode, depth: Int, includeUntagged: Bool) {
        switch node.type {
        case .root:
            break
        case .tag:
            closeTagContent(downTo: depth)
            tagsCode.startListItem()
            let text = htmlConverter.convert(from: node.description)
            tagsCode.startDetails(summary: text)
            // tagsCode.writeLine(text)
            openTagsList()
        case .note:
            let note = node.note!
            if includeUntagged || note.hasTags() {
                let seq = note.seq.value
                let title = note.title.value
                let link = displayParms.assembleWikiLink(title: title)
                tagsCode.startListItem()
                if seq.count > 0 {
                    tagsCode.write("\(seq) ")
                }
                let text = htmlConverter.convert(from: title)
                tagsCode.link(text: text, path: link)
                tagsCode.finishListItem()
            }
        }
    }
    
    func openTagsList() {
        tagsCode.startUnorderedList(klass: "tags-list")
        tagsListLevel += 1
    }
    
    func closeTagContent(downTo: Int) {
        while tagsListLevel > downTo {
            closeTagContents(level: tagsListLevel)
        }
    }
    
    func closeTagContents(level: Int) {
        tagsCode.finishUnorderedList()
        if level > 1 {
            tagsCode.finishDetails()
            tagsCode.finishListItem()
        }
        tagsListLevel -= 1
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML with teasers for children.
    //
    // -----------------------------------------------------------
    
    /// Return a list of children, with teasers formatted in HTML.
    public func mkdownTeasers() -> String {

        guard let collection = io.collection else { return "" }
        guard io.collectionOpen else { return "" }
        
        guard collection.seqFieldDef != nil else { return "" }
        guard collection.teaserFieldDef != nil else { return "" }
        guard collection.levelFieldDef != nil else { return "" }
        guard collection.sortParm == .seqPlusTitle else { return "" }
        
        
        guard let parent = io.getNote(knownAs: collection.titleToParse) else { return "" }
        let currentPosition = io.positionOfNote(parent)
        let (nextNote, nextPosition) = io.nextNote(currentPosition)
        guard nextPosition.valid && nextNote != nil else { return "" }
        
        var children: [Note] = []
        
        let nextLevel = nextNote!.level
        let nextSeq = nextNote!.seq

        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        var followingNote: Note?
        followingNote = nextNote
        var followingPosition = nextPosition
        var followingLevel = LevelValue(i: nextLevel.getInt(), config: io.collection!.levelConfig)
        var followingSeq = nextSeq.dupe()
        
        var displayedChildCount = 0
        
        while followingNote != nil
                && followingPosition.valid
                && followingLevel > parent.level
                && followingSeq > parent.seq {
            
            if followingLevel == nextLevel {
                children.append(followingNote!)
            }
            
            let (nextUpNote, nextUpPosition) = io.nextNote(followingPosition)

            displayedChildCount += 1

            followingNote = nextUpNote
            followingPosition = nextUpPosition

            if followingNote != nil {
                followingLevel = followingNote!.level
                followingSeq = followingNote!.seq
            }
        }
        
        let teasers = Markedup()
        let startingFormat = displayParms.format
        displayParms.format = .htmlFragment
        let mkdownOptions = displayParms.genMkdownOptions()
        
        for child in children {
            
            teasers.startParagraph()
            
            let seq = child.seq
            let seqStack = seq.seqStack
            let finalSegment = seqStack.segments[seqStack.max]
            teasers.append("\(finalSegment.value). ")
            
            let mkdown = MkdownParser(child.teaser.value, options: mkdownOptions)
            // mkdown.setWikiLinkFormatting(prefix: "", format: .fileName, suffix: ".html", context: workspace?.mkdownContext)
            // mkdown.setWikiLinkFormatting(prefix: "#", format: .fileName, suffix: "", context: workspace?.mkdownContext)
            mkdown.setWikiLinkFormatting(prefix: mkdownOptions.wikiLinkPrefix,
                                         format: mkdownOptions.wikiLinkFormatting,
                                         suffix: mkdownOptions.wikiLinkSuffix,
                                         context: self)
            mkdown.parse()
            let stripped = StringUtils.removeParagraphTags(mkdown.html)
            teasers.append(stripped)
 
            teasers.finishParagraph()
        }
        
        displayParms.format = startingFormat
        if displayedChildCount > 0 {
            collection.teasers = true
        }
        
        return teasers.code
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Tags Cloud.
    //
    // -----------------------------------------------------------
    
    var tagsList: [String] = []
    var tagsConcat = ""
    var tagsLast = ""
    
    /// Return a tags cloud of the collection, formatted in HTML.
    public func mkdownTagsCloud(mods: String) -> String {
        guard io.collection != nil else { return "" }
        guard io.collectionOpen else { return "" }
        tagsCode = Markedup(format: .htmlFragment)
        
        // Perform first pass.
        tagsLast = ""
        tagsCode.startUnorderedList(klass: "tags-cloud")
        var iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        while tagsNode != nil {
            generateTagsCloudNode(pass: 1, node: tagsNode!, depth: iterator.depth)
            tagsNode = iterator.next()
        }
        tagsCode.finishUnorderedList()
        
        tagsCode.horizontalRule()
        
        // Perform second pass.
        tagsLast = ""
        tagsCode.startDiv(klass: "tags-contents")
        iterator = io.makeTagsNodeIterator()
        tagsNode = iterator.next()
        while tagsNode != nil {
            generateTagsCloudNode(pass: 2, node: tagsNode!, depth: iterator.depth)
            tagsNode = iterator.next()
        }
        if !tagsLast.isEmpty {
            tagsCode.finishUnorderedList()
        }
        tagsCode.finishDiv()
        
        return tagsCode.code
    }
    
    /// Generate html code for the next node.
    func generateTagsCloudNode(pass: Int, node: TagsNode, depth: Int) {
        switch node.type {
        case .root:
            break
        case .tag:
            if tagsList.count >= depth {
                tagsList[depth - 1] = node.tag!.forDisplay
            } else {
                tagsList.append(node.tag!.forDisplay)
            }
            tagsConcat = ""
            var i = 0
            while i < depth {
                if i > 0 {
                    tagsConcat.append(".")
                }
                tagsConcat.append(tagsList[i])
                i += 1
            }
        case .note:
            let note = node.note!
            guard note.hasTags() else { break }

            if tagsConcat != tagsLast {
                if pass == 1 {
                    startTagsCloudFirstPass()
                } else {
                    startTagsCloudSecondPass()
                }
                tagsLast = tagsConcat
            }
            
            guard pass == 2 else { break }
            
            let title = note.title.value
            let link = displayParms.assembleWikiLink(title: title)
            let text = htmlConverter.convert(from: title)
            tagsCode.startListItem()
            tagsCode.link(text: text, path: link)
            tagsCode.finishListItem()

        }
    }
    
    func startTagsCloudFirstPass() {
        tagsCode.startListItem()
        tagsCode.link(text: tagsConcat, path: "#tags.\(tagsConcat)")
        tagsCode.finishListItem()
    }
    
    func startTagsCloudSecondPass() {
        if !tagsLast.isEmpty {
            tagsCode.finishUnorderedList()
        }
        tagsCode.heading(level: 5, text: tagsConcat, addID: true, idText: "tags.\(tagsConcat)")
        tagsCode.startUnorderedList(klass: nil)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Include another item (Note or file). 
    //
    // -----------------------------------------------------------
    
    public func mkdownInclude(item: String, style: String) -> String? {
        guard io.collection != nil else { return nil }
        guard io.collectionOpen else { return nil }
        var str: String?
        if item.contains(".") {
            str = includeFromFile(item: item)
        }
        if str == nil {
            str = includeFromNote(item: item, style: style)
        }
        return str
    }
    
    func includeFromFile(item: String) -> String? {
        guard let collection = io.collection else { return nil }
        guard let collectionURL = collection.fullPathURL else { return nil }
        let fileURL = URL(fileURLWithPath: item,
                                isDirectory: false,
                                relativeTo: collectionURL) 
        if let str = try? String(contentsOf: fileURL) {
            return str
        }
        return nil
    }
    
    public func clearIncludedNotes() {
        includedNotes = []
    }
    
    func includeFromNote(item: String, style: String) -> String? {
        
        guard io.collection != nil else { return item }
        guard io.collectionOpen else { return item }
        
        guard let noteTitle = mkdownWikiLinkLookup(linkText: item) else { return nil }
        let noteID = StringUtils.toCommon(noteTitle)
        guard let note = io.getNote(forID: noteID) else {
            return "Note titled '\(item)' could not be included"
        }
        
        includedNotes.append(noteID)
        
        switch style {
        case "body":
            return note.body.value
        case "note":
            return includeTextFromNote(note: note)
        case "quotebody", "quote-body":
            return includeQuoteFromNote(note: note, withAttrib: false)
        case "quote":
            return includeQuoteFromNote(note: note)
        default:
            return note.body.value
        }
    }
    
    func includeTextFromNote(note: Note) -> String? {
        let maker = NoteLineMaker()
        _ = maker.putNote(note)
        if let writer = maker.writer as? BigStringWriter {
            return writer.bigString
        }
        return nil
    }
    
    func includeQuoteFromNote(note: Note, withAttrib: Bool = true) -> String? {
        let markedUp = Markedup(format: .htmlFragment)
        let fieldsToHTML = NoteFieldsToHTML()
        fieldsToHTML.formatQuoteWithAttribution(note: note,
                                                markedup: markedUp,
                                                parms: displayParms,
                                                io: io,
                                                bodyHTML: nil,
                                                withAttrib: withAttrib)
        return markedUp.code
    }
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "WebBookMaker",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "WebBookMaker",
                          level: .error,
                          message: msg)
    }
}
