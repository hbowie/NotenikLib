//
//  NotesMkdownContext.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/12/21.
//
//  Copyright © 2021 - 2025 Herb Bowie (https://hbowie.net)
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
    
    
    // Loaded at initialization. 
    var io: NotenikIO
    var displayParms = DisplayParms()
    
    // Data provided by one or more methods, for potential use
    // outside of the Markdown parser.
    public var mkdownCommandList = MkdownCommandList(collectionLevel: false)
    public var includedNotes: [String] = []
    public var includedLinks = WikiLinkList()
    public var javaScript = ""
    public var hashTags: [String] = []
    public var localImages: [LinkPair] = []
    
    // Utility.
    let htmlConverter = StringConverter()
    
    /// Initialization.
    public init(io: NotenikIO, displayParms: DisplayParms? = nil) {
        self.io = io
        if displayParms != nil {
            self.displayParms = displayParms!
        }
        htmlConverter.addHTML()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Identify the Note to be parsed.
    //
    // -----------------------------------------------------------
    
    /// Identify the note that is about to be parsed.
    /// - Parameters:
    ///   - id: The common ID for the note, to be used by Notenik.
    ///   - text: A textual representation of the note ID, to be read by humans.
    ///   - fileName: The common filename for the note.
    ///   - shortID: The short, minimal, ID for the note.
    public func identifyNoteToParse(id: String, text: String, fileName: String, shortID: String) {
        guard let collection = io.collection else { return }
        collection.idToParse = id
        collection.textToParse = text
        collection.fileNameToParse = fileName
        collection.shortID = shortID
        if collection.idToParse != collection.lastInclusion {
            collection.includingID = id
            collection.lastInclusion = ""
        }
        mkdownCommandList = MkdownCommandList(collectionLevel: false)
        localImages = []
        javaScript = ""
        hashTags = []
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Expose the usage of interesting Markdown.
    //
    // -----------------------------------------------------------
    
    /// Expose the usage of a Markdown command found within the page.
    public func exposeMarkdownCommand(_ command: String, mods: String? = nil) {
        guard let collection = io.collection else {
            // print("  - collection is missing!")
            return
        }
        guard !collection.idToParse.isEmpty else {
            // print("  - id to parse is missing!")
            return
        }
        mkdownCommandList.updateWith(command: command, noteTitle: collection.idToParse, code: nil, mods: mods)
    }
    
    /// Expose the usage of an image link.
    public func exposeImageLink(original: String, modified: String) {
        guard !original.isEmpty else { return }
        guard let collection = io.collection else { return }
        guard !collection.idToParse.isEmpty else { return }
        if !original.contains("://") {
            localImages.append(LinkPair(original: original, modified: modified))
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Collect embedded hash tags.
    //
    // -----------------------------------------------------------
    
    /// Collect embedded hash tags found within the Markdown.
    public func addHashTag(_ tag: String) -> String {
        guard !tag.isEmpty else { return "" }
        hashTags.append(tag)
        guard let collection = io.collection else { return "" }
        let tagValue = TagValue(tag)
        return CustomURLFormatter().expandTag(collection: collection, tag: tagValue)
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
    public func mkdownWikiLinkLookup(linkText: String) -> WikiLinkTarget? {
        
        let resolution = NoteLinkResolution(io: io, linkText: linkText)
        NoteLinkResolver.resolve(resolution: resolution)
        return resolution.genWikiLinkTarget()
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
        includedLinks = WikiLinkList()
    }
    
    func includeFromNote(item: String, style: String) -> String? {
        
        let resolution = NoteLinkResolution(io: io, linkText: item)
        NoteLinkResolver.resolve(resolution: resolution)

        guard resolution.result != .badInput else { return item }
        
        guard resolution.result == .resolved else {
            return "Note titled '\(item)' could not be included"
        }
        
        // Keep track of included notes.
        includedNotes.append(resolution.pathSlashID)
        
        let wikiLink = WikiLink()
        
        if let collection = io.collection {
            wikiLink.setFrom(path: "", item: collection.includingID)
            collection.lastInclusion = StringUtils.toCommon(item)
        }
        wikiLink.setOriginalTarget(item)
        wikiLink.targetFound = true
        let lookedUp = mkdownWikiLinkLookup(linkText: item)
        if lookedUp == nil {
            wikiLink.targetFound = false
        } else {
            wikiLink.updatedTarget = lookedUp!
            wikiLink.targetFound = true
        }
        includedLinks.addLink(wikiLink)
        
        // Vary processing and formatting based on style.
        switch style {
        case "body":
            return resolution.resolvedNote!.body.value
        case "note":
            return includeTextFromNote(note: resolution.resolvedNote!)
        case "quotebiblio", "quote-biblio":
            return includeQuoteFromBiblio(note: resolution.resolvedNote!)
        case "quotebody", "quote-body":
            return includeQuoteFromNote(note: resolution.resolvedNote!, withAttrib: false)
        case "quote":
            return includeQuoteFromNote(note: resolution.resolvedNote!)
        case "ref":
            return includeReferenceFromNote(note: resolution.resolvedNote!)
        default:
            return resolution.resolvedNote!.body.value
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
        markedUp.newLine()
        markedUp.newLine()
        markedUp.startCompacting()
        let fieldsToHTML = NoteFieldsToHTML()
        fieldsToHTML.formatQuoteWithAttribution(note: note,
                                                markedup: markedUp,
                                                parms: displayParms,
                                                io: io,
                                                bodyHTML: nil,
                                                withAttrib: withAttrib)
        return markedUp.code
    }
    
    func includeQuoteFromBiblio(note: Note) -> String? {
        
        // See if we have what we need to find this note's parents.
        guard let collection = io.collection else {
            return includeQuoteFromNote(note: note)
        }
        guard io.collectionOpen else {
            return includeQuoteFromNote(note: note)
        }
        guard collection.seqFieldDef != nil else {
            return includeQuoteFromNote(note: note)
        }
        guard collection.levelFieldDef != nil else {
            return includeQuoteFromNote(note: note)
        }
        let sortParm = collection.sortParm
        guard sortParm == .seqPlusTitle || sortParm == .custom else {
            return includeQuoteFromNote(note: note)
        }
        
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        let currentPosition = io.positionOfNote(note)
        var (priorSortedNote, priorPosition) = io.priorNote(currentPosition)
        guard priorPosition.valid && priorSortedNote != nil else {
            return includeQuoteFromNote(note: note)
        }
        
        var workNote: Note?
        var authorNote: Note?
        
        var navDone = false
        
        while priorSortedNote != nil && !navDone {
            switch priorSortedNote!.note.klass.value {
            case NotenikConstants.biblioKlass:
                navDone = true
            case NotenikConstants.workKlass:
                if workNote == nil {
                    workNote = priorSortedNote!.note
                }
            case NotenikConstants.quoteKlass:
                break
            case NotenikConstants.authorKlass:
                authorNote = priorSortedNote!.note
                navDone = true
            default:
                navDone = true
            }
            (priorSortedNote, priorPosition) = io.priorNote(priorPosition)
        }
        
        guard workNote != nil || authorNote != nil else {
            return includeQuoteFromNote(note: note)
        }
        
        let markedUp = Markedup(format: .htmlFragment)
        markedUp.newLine()
        markedUp.newLine()
        markedUp.startCompacting()
        let fieldsToHTML = NoteFieldsToHTML()
        fieldsToHTML.formatQuoteFromBiblio(note: note,
                                           authorNote: authorNote,
                                           workNote: workNote,
                                           markedup: markedUp,
                                           parms: displayParms,
                                           io: io)
        return markedUp.code
    }
    
    func includeReferenceFromNote(note: Note) -> String? {
        
        let markedUp = Markedup(format: .htmlFragment)
        
        var parent: Note? = nil
        if note.klass.value.contains("element") {
            parent = includeElementParent(note: note)
        }
    
        let link = displayParms.wikiLinks.assembleWikiLink(idBasis: note.noteID.basis)
        markedUp.startParagraph()
        markedUp.link(text: note.noteID.basis, path: link, klass: "wiki-link")
        markedUp.finishParagraph()
        
        if parent != nil {
            let parentLink = displayParms.wikiLinks.assembleWikiLink(idBasis: parent!.noteID.basis)
            markedUp.startUnorderedList()
            markedUp.startListItem()
            markedUp.write("An element of ")
            markedUp.link(text: parent!.noteID.basis, path: parentLink, klass: "wiki-link")
            markedUp.finishListItem()
            markedUp.finishUnorderedList()
        }
        return markedUp.code
    }
    
    func includeElementParent(note: Note) -> Note? {
        
        // See if we have what we need to find this note's parents.
        guard let collection = io.collection else { return nil }
        guard io.collectionOpen else { return nil }
        guard collection.seqFieldDef != nil else { return nil }
        let sortParm = collection.sortParm
        guard sortParm == .seqPlusTitle || sortParm == .custom else {
            return nil
        }
        
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        let (_, selPosition) = io.getSelectedNote()
        
        let currentPosition = io.positionOfNote(note)
        var (priorSortedNote, priorPosition) = io.priorNote(currentPosition)
        guard priorPosition.valid && priorSortedNote != nil else {
            return nil
        }
        
        var parentNote: Note?
        
        var navDone = false
        
        while priorSortedNote != nil && !navDone {
            
            if !priorSortedNote!.note.klass.value.contains("element") {
                parentNote = priorSortedNote!.note
                navDone = true
            }

            (priorSortedNote, priorPosition) = io.priorNote(priorPosition)
        }
        if selPosition.valid {
            _ = io.selectNote(at: selPosition.index)
        }
        
        return parentNote
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Calendar.
    //
    // -----------------------------------------------------------
    
    public func mkdownCalendar(mods: String) -> String {
        
        guard io.collectionOpen else { return "" }
        guard let collection = io.collection else { return "" }
        
        guard collection.sortParm == .tasksByDate || collection.sortParm == .datePlusSeq else {
            communicateError("Collection must be sorted by Date in order to generate a calendar")
            return ""
        }
        
        var lowYM = ""
        var highYM = ""
        
        if !mods.isEmpty {
            let ymStack = mods.components(separatedBy: CharacterSet(charactersIn: ",;|"))
            if ymStack.count > 0 {
                lowYM = ymStack[0]
                if ymStack.count > 1 {
                    highYM = ymStack[1]
                }
            }
        }
        
        let calendar = CalendarMaker(format: .htmlFragment, lowYM: lowYM, highYM: highYM)
        calendar.startCalendar(title: collection.title, prefs: DisplayPrefs.shared)
        
        var (sortedNote, position) = io.firstNote()
        var done = false
        while sortedNote != nil && !done {
            let link = displayParms.wikiLinks.assembleWikiLink(idBasis: sortedNote!.note.noteID.getBasis())
            done = calendar.nextNote(sortedNote!.note, link: link)
            (sortedNote, position) = io.nextNote(position)
        }
        
        let html = calendar.finishCalendar()
        return html
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Collection Table of Contents.
    //
    // -----------------------------------------------------------
    
    var levelStart = 0
    var levelEnd = 999
    var tocDetails = false
    var hasLevel = false
    var hasSeq = false
    var hasLevelAndSeq: Bool {
        return hasLevel && hasSeq
    }
    var toc = Markedup(format: .htmlFragment)
    var levelInfo: [LevelInfo] = []
    var lastLevel: LevelInfo {
        if levelInfo.count > 0 {
            return levelInfo[levelInfo.count - 1]
        } else {
            return LevelInfo(level: 0, hasChildren: false)
        }
    }
    
    public func mkdownCollectionTOC(levelStart: Int, levelEnd: Int, details: Bool) -> String {
        self.levelStart = levelStart
        self.levelEnd = levelEnd
        self.tocDetails = details
        guard io.collectionOpen else { return "" }
        guard let collection = io.collection else { return "" }
        collection.tocNoteID = collection.idToParse
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        if collection.sortParm == .datePlusSeq {
            self.levelStart = 1
            self.levelEnd = 2
            return datePlusSeqToC()
        } else if details {
            let outliner = NoteOutliner(list: io.notesList,
                                        levelStart: levelStart,
                                        levelEnd: levelEnd,
                                        skipID: collection.tocNoteID,
                                        displayParms: displayParms)
            return outliner.`genToC`(details: true).code
        } else {
            let outliner = NoteOutliner(list: io.notesList,
                                        levelStart: levelStart,
                                        levelEnd: levelEnd,
                                        skipID: collection.tocNoteID,
                                        displayParms: displayParms)
            return outliner.genToC(details: false).code
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Date plus Seq Table of Contents.
    //
    // -----------------------------------------------------------
    
    var lastDate = ""
    var itemCount = 0
    var dateStarted = false
    
    func datePlusSeqToC() -> String {
        guard io.collectionOpen else { return "" }
        guard let collection = io.collection else { return "" }
        collection.tocNoteID = collection.idToParse
        toc = Markedup(format: .htmlFragment)
        datePlusSeqStartTocUnorderedList(top: true)
        lastDate = ""
        dateStarted = false
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            if sortedNote!.note.noteID.commonID != collection.tocNoteID {
                datePlusSeqTocEntry(for: sortedNote!.note)
            }
            (sortedNote, position) = io.nextNote(position)
        }
        if dateStarted {
            finishLastDate()
        }
        toc.finishUnorderedList()
        return toc.code
    }
    
    func datePlusSeqTocEntry(for note: Note) {
        itemCount += 1
        var dateYMD = ""
        if let date = note.date.simpleDate {
            dateYMD = date.ymdDate
        }
        if dateYMD != lastDate && dateStarted {
            finishLastDate()
        }
        if dateYMD != lastDate || itemCount == 1 {
            startNewDate(dateYMD: dateYMD, note: note)
        }
        var itemText = ""
        if note.hasSeq() {
            itemText = note.seq.valueToDisplay() + " "
        }
        itemText.append(note.title.value)
        toc.startListItem()
        toc.link(text: itemText,
                 path: displayParms.wikiLinks.assembleWikiLink(idBasis: note.noteID.getBasis()),
                 klass: Markedup.htmlClassNavLink)
        toc.finishListItem()
        lastDate = dateYMD
    }
    
    func startNewDate(dateYMD: String, note: Note) {
        
        let dateValue = note.date
        var dateLabel = "n/a"
        if dateYMD.count >= 8 {
            dateLabel = dateValue.dMyWDate
        }
        toc.startListItem()
        if tocDetails {
            toc.startDetails(klass: "list-item-1-details")
            toc.startSummary()
        }
        toc.link(text: dateLabel,
                 path: displayParms.wikiLinks.assembleWikiLink(idBasis: note.noteID.getBasis()),
                 klass: Markedup.htmlClassNavLink)
        if tocDetails {
            toc.finishSummary()
        }
        datePlusSeqStartTocUnorderedList(top: false)
        dateStarted = true
    }
    
    func finishLastDate() {
        toc.finishUnorderedList()
        if tocDetails {
            toc.finishDetails()
        }
        toc.finishListItem()
        dateStarted = false
    }
    
    func datePlusSeqStartTocUnorderedList(top: Bool) {
        var ulKlass: String? = nil
        if tocDetails && top {
            ulKlass = "outline-list"
        }
        toc.startUnorderedList(klass: ulKlass)
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
    /// - Parameter mods: The index field name, if not the one and only for the collection.
    /// - Returns: Fully formatted HTML.
    public func mkdownIndex(mods: String? = nil) -> String {
        
        guard let collection = io.collection else { return "" }
        var indexFieldDef = FieldDefinition(typeCatalog: collection.typeCatalog,
                                            label: NotenikConstants.index,
                                            type: NotenikConstants.indexCommon)
        if collection.indexFieldDef != nil {
            indexFieldDef = collection.indexFieldDef!
        }
        var indexFieldName = indexFieldDef.fieldLabel.commonForm
        if mods != nil && !mods!.isEmpty {
            indexFieldName = StringUtils.toCommon(mods!)
        }
        
        // Spin through the collection and collection index terms and references.
        indexCollection  = IndexCollection()
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            let note = sortedNote!.note
            if let indexField = note.getField(common: indexFieldName) {
                let indexValue = indexField.value as? IndexValue ?? IndexValue(indexField.value.value)
                if note.hasTitle() && note.includeInBook(epub: displayParms.epub3) {
                    let pageType = sortedNote!.note.getFieldAsString(label: NotenikConstants.typeCommon)
                    indexCollection.add(page: note.title.value,
                                        pageType: pageType,
                                        pageStatus: note.status.value,
                                        index: indexValue)
                }
            }
            (sortedNote, position) = io.nextNote(position)
        }
        
        // Now sort the list of terms.
        indexCollection.sort()
        
        if let collection = io.collection {
            collection.indexPageID = collection.idToParse
            collection.indexOfCollection = indexCollection
            collection.lastIndexTermKey = ""
            collection.lastIndexTermPageIx = -1
        }
        
        // Generate an index, formatted using Markdown.
        let mkdown = Markedup(format: .htmlFragment)
        termCount = 0
        pageCount = 0
        var lastLetter = " "
        
        // Generate Index
        mkdown.startParagraph()
        for term in indexCollection.list {
            let initialLetter = term.term.prefix(1).uppercased()
            if initialLetter != lastLetter {
                mkdown.link(text: initialLetter, path: "#letter-\(initialLetter.lowercased())", klass: Markedup.htmlClassNavLink)
                mkdown.newLine()
                lastLetter = initialLetter
            }
        }
        mkdown.finishParagraph()
        
        // Generate the index
        lastLetter = " "
        for term in indexCollection.list {
            termCount += 1
            let initialLetter = term.term.prefix(1).uppercased()
            if initialLetter != lastLetter {
                if lastLetter != " " {
                    mkdown.finishDefinitionList()
                }
                mkdown.heading(level: 3, text: "&#8212; \(initialLetter) &#8212;", addID: true, idText: "letter-\(initialLetter)")
                lastLetter = initialLetter
                mkdown.startDefinitionList(klass: nil)
            }
            mkdown.startDefTerm()
            mkdown.append(term.term)
            mkdown.finishDefTerm()
            var withinCount = 0
            for ref in term.refs {
                pageCount += 1
                mkdown.startDefDef()
                var link = displayParms.wikiLinks.assembleWikiLink(idBasis: ref.page)
                link.append("?\(NotenikConstants.indexTermLabel)=\(term.term)")
                link.append("&\(NotenikConstants.indexedPageIndexLabel)=\(withinCount)")
                link.append("&\(NotenikConstants.indexedPageCountLabel)=\(term.refs.count)")
                let text = htmlConverter.convert(from: ref.page)
                mkdown.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                mkdown.finishDefDef()
                withinCount += 1
            }
        }
        mkdown.finishDefinitionList()
        return mkdown.code
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML to take user to a random note.
    //
    // -----------------------------------------------------------
    
    /// Generate a page that will randomly navigate to another page.
    public func mkdownRandomNote(klassNames: String) -> String {
        
        // See if we're limiting this to certain class names.
        var typeOfThing = "note"
        var klassList: [String] = []
        var nextName = SolidString()
        for c in klassNames {
            switch c {
            case ",", ";":
                if !nextName.isEmpty {
                    klassList.append(nextName.common)
                    nextName = SolidString()
                }
            default:
                nextName.append(c)
            }
        }
        if !nextName.isEmpty {
            klassList.append(nextName.common)
        }
        if klassList.count == 1 {
            typeOfThing = klassList[0]
        }
        
        if displayParms.wikiLinks.format == .common {
            return randomWithinNotenik(typeOfThing: typeOfThing, klassList: klassList)
        } else {
            return randomInBrowser(typeOfThing: typeOfThing, klassList: klassList)
        }
    }
    
    func randomWithinNotenik(typeOfThing: String, klassList: [String]) -> String {
        let markup = Markedup(format: .htmlFragment)
        var ok = false
        var attempts = 0
        var note: Note?
        while !ok && attempts <= 1000 {
            attempts += 1
            let i = Int.random(in: 0..<io.count)
            note = io.getNote(at: i)
            if note != nil {
                ok = isEligibleRandomNote(note: note!, klassList: klassList)
            }
        }
        markup.startParagraph()
        if ok {
            markup.append("Click to go to ")
            let link = displayParms.wikiLinks.assembleWikiLink(idBasis: note!.noteID.getBasis())
            let text = htmlConverter.convert(from: note!.noteID.text)
            markup.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
            markup.append(".")
        } else {
            markup.append("A target \(typeOfThing) could not be found!")
        }
        markup.finishParagraph()
        return markup.code
    }
    
    func randomInBrowser(typeOfThing: String, klassList: [String]) -> String {
        
        // Generate the JavaScript
        let js = BigStringWriter()
        js.open()
        js.writeLine("var fileNames = new Array();")
        js.writeLine("var ix = 0;")
        
        // Now fill the candidate array.
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            if isEligibleRandomNote(note: sortedNote!.note, klassList: klassList) {
                let fileName = StringUtils.toCommonFileName(sortedNote!.note.title.value)
                js.writeLine("fileNames[ix] = \"\(fileName).html\";")
                js.writeLine("ix++;")
            }
            (sortedNote, position) = io.nextNote(position)
        }
        let randomScript = """
        var max = ix;

        var now = new Date();
        var seed = now.getTime() % 0xffffffff;
        let results = document.querySelector('#random-note');

        randomNote();

        function rand(n) {
          seed = (0x015a4e35 * seed) % 0x7fffffff;
          return (seed >> 16) % n;
        }

        function randomNote() {
          var rq = rand(max);
          if (rq < 0) {
            rq = 0;
          }
          if (rq >= max) {
            rq = max - 1;
          }
          var fileName = fileNames[rq];
          let html = '<p>Click to go to <a href="' + fileName + '">random page</a>.</p>';
          results.innerHTML = html;
        }

        """
        js.write(randomScript)
        js.close()
        
        // Generate the HTML
        let markup = Markedup(format: .htmlFragment)
        markup.startDiv(klass: nil, id: "random-note")
        markup.finishDiv()
        if displayParms.epub3 {
            javaScript = js.bigString
            if let collection = io.collection {
                let jsFileName = collection.fileNameToParse
                markup.script(src: "js/\(jsFileName).js")
            }
        } else {
            markup.startScript()
            markup.ensureNewLine()
            markup.append(js.bigString)
            markup.finishScript()
            markup.ensureBlankLine()
        }

        return markup.code
    }
    
    /// Is this class included in the list of desired classes?
    func isEligibleRandomNote(note: Note, klassList: [String]) -> Bool {
        
        if let collection = io.collection {
            if collection.idToParse == note.noteID.commonID {
                return false
            }
        }
        
        if !note.includeInBook(epub: displayParms.epub3) { return false }
        
        guard !klassList.isEmpty else { return true }
        let klass = note.klass.value
        guard !klass.isEmpty else { return false }
        for targetKlass in klassList {
            if klass == targetKlass {
                return true
            }
        }
        return false
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Collection Search Form.
    //
    // -----------------------------------------------------------
    
    /// Return a search page for the Collection, formatted in HTML.
    public func mkdownSearch(siteURL: String) -> String {
        
        // Generate the page, formatted using HTML.
        let markup = Markedup(format: .htmlFragment)
        
        markup.startDiv(klass: "search-page")
        
        markup.startDiv(klass: "search-form")
        markup.startForm(action: "https://duckduckgo.com/", method: "get", id: "form-search")
        markup.formLabel(labelFor: "input-search", labelText: "Enter your search term:")
        markup.formInput(inputType: "text", name: "q", value: nil, id: "input-search")
        markup.formInput(inputType: "hidden", name: "sites", value: siteURL, id: nil)
        markup.formButton(buttonType: "submit", buttonText: "Search",
                          klass: "btn btn-primary", id: "submit-search")
        markup.finishForm()
        markup.finishDiv()
        
        markup.startDiv(klass: nil, id: "search-results")
        markup.finishDiv()
        markup.finishDiv()
        
        markup.startScript()
        markup.ensureNewLine()
        markup.writeLine("let searchIndex = [ ")
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            if sortedNote!.original {
                
                markup.writeLine("    { ")
                
                // Generate title
                markup.writeLine("        title: \"\(sortedNote!.note.noteID.text)\", ")
                
                // Generate date
                if sortedNote!.note.hasDate() {
                    markup.writeLine("        date: \"\(sortedNote!.note.getDateAsField()!)\", ")
                } else {
                    markup.writeLine("        date: \"\", ")
                }
                
                // Generate URL
                let resolution = NoteLinkResolution(io: io, linkText: sortedNote!.note.noteID.commonID)
                NoteLinkResolver.resolve(resolution: resolution)
                if let target = resolution.genWikiLinkTarget() {
                    let url = displayParms.wikiLinks.assembleWikiLink(target: target)
                    markup.writeLine("        url: \"\(url)\", ")
                } else {
                    markup.writeLine("        url: \"\", ")
                }
                
                // Generate summary
                var summaryText = ""
                if sortedNote!.note.hasTeaser() {
                    summaryText = sortedNote!.note.teaser.value
                } else {
                    summaryText = StringUtils.summarize(sortedNote!.note.body.value)
                }
                let mkd = MkdownParser(summaryText, options: displayParms.genMkdownOptions())
                mkd.parse()
                
                let escaped = StringUtils.prepHTMLforJSON(mkd.html)
                markup.writeLine("        summary: \"\(escaped)\", ")
                
                // Generate content
                let pureContent = StringUtils.purifyPunctuation(sortedNote!.note.body.value)
                markup.writeLine("        content: \"\(pureContent)\"")
                
                markup.writeLine("    }, ")
            }
            (sortedNote, position) = io.nextNote(position)
        }
        markup.ensureNewLine()
        markup.writeLine("]; ")
        let searchScript = """
        /**
         * Based on Go Make Things blog post at:
         * https://gomakethings.com/how-to-create-a-vanilla-js-search-page-for-a-static-website/
         */
        (function (window, document, undefined) {

            'use strict';

            //
            // Variables
            //

            let form = document.querySelector('#form-search');
            let input = document.querySelector('#input-search');
            let resultList = document.querySelector('#search-results');

            //
            // Methods
            //

            /**
             * Create the HTML for each result
             * @param  {Object} article The article
             * @param  {Number} id      The result index
             * @return {String}         The markup
             */
            let createHTML = function (article, id) {
                let html =
                    '<div id="search-result-' + id + '">' +
                        '<h4>' +
                            '<a href="' + article.url + '" class="nav-link">' +
                                article.title +
                            '</a>' +
                        '</h2>' +
                        article.summary + '<br>' +
                    '</div>';
                return html;
            };

            /**
             * Create the markup for results
             * @param  {Array} results The results to display
             * @return {String}        The results HTML
             */
            let createResultsHTML = function (results) {
                let html = '<p>Found ' + results.length + ' matching pages</p>';
                html += results.map(function (article, index) {
                    return createHTML(article, index);
                }).join('');
                return html;
            };

            /**
             * Create the markup when no results are found
             * @return {String} The markup
             */
            let createNoResultsHTML = function () {
                return '<p>Sorry, no matches were found.</p>';
            };

            /**
             * Search for matches
             * @param  {String} query The term to search for
             */
            let search = function (query) {

                // Variables
                let reg = new RegExp(query, 'gi');
                let priority1 = []
                let priority2 = []

                searchIndex.forEach(function (article) {
                    if (reg.test(article.title)) return priority1.push(article);
                    if (reg.test(article.content)) priority2.push(article);
                });

                let results = [].concat(priority1, priority2)

                // Display the results
                resultList.innerHTML = results.length < 1 ? createNoResultsHTML() : createResultsHTML(results);
            };

            /**
             * Handle submit events
             */
            let submitHandler = function (event) {
                event.preventDefault();
                search(input.value);
            };

            //
            // Inits & Event Listeners
            //

            // Make sure required content exists
            if (!form || !input || !resultList || !searchIndex) return;

            // Create a submit handler
            form.addEventListener('submit', submitHandler);

        })(window, document);
        """
        markup.append(searchScript)
        markup.finishScript()

        return markup.code
    }
    
    /// Generate javascript to sort the following table.
    public func mkdownTableSort() -> String {
        
        // Generate the JavaScript
        let js = BigStringWriter()
        js.open()
        js.writeLine(tableSortScript())
        js.close()
        
        // Generate the HTML
        let markup = Markedup(format: .htmlFragment)
        if displayParms.epub3 {
            javaScript = js.bigString
            if let collection = io.collection {
                let jsFileName = collection.fileNameToParse
                markup.script(src: "js/\(jsFileName).js")
            }
        } else {
            markup.startScript()
            markup.ensureNewLine()
            markup.append(js.bigString)
            markup.finishScript()
            markup.ensureBlankLine()
        }

        return markup.code
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
        let includeUntagged = mods.isEmpty // && displayParms.tagsIndexFilename == nil
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
    
    var countOfNotesWithinTag = 0
    var tagID: String? = ""
    
    /// Generate html code for the next node.
    func generateTagsNode(node: TagsNode, depth: Int, includeUntagged: Bool) {
        switch node.type {
        case .root:
            break
        case .tag:
            closeTagContent(downTo: depth)
            if node.description != "- untagged" || includeUntagged {
                tagsCode.startListItem()
                let text = htmlConverter.convert(from: node.description)
                tagID = StringUtils.toCommon(node.description)
                tagsCode.startDetails(summary: text, id: tagID)
                openTagsList()
            }
            countOfNotesWithinTag = 0
        case .note:
            let note = node.note!
            if includeUntagged || note.hasTags() {
                let seq = note.seq.value
                let link = displayParms.wikiLinks.assembleWikiLink(idBasis: note.noteID.getBasis())
                var listItemID: String? = nil
                if tagID != nil {
                    listItemID = "\(tagID!)-\(countOfNotesWithinTag)"
                }
                tagsCode.startListItem(id: listItemID)
                if seq.count > 0 {
                    tagsCode.write("\(seq) ")
                }
                let text = htmlConverter.convert(from: note.noteID.text)
                tagsCode.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                tagsCode.finishListItem()
                countOfNotesWithinTag += 1
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
        
        // Perform first pass to generate the cloud.
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
            
            let link = displayParms.wikiLinks.assembleWikiLink(idBasis: note.noteID.getBasis())
            let text = htmlConverter.convert(from: note.noteID.text)
            tagsCode.startListItem()
            tagsCode.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
            tagsCode.finishListItem()
        }
    }
    
    func startTagsCloudFirstPass() {
        tagsCode.startListItem()
        tagsCode.link(text: tagsConcat, path: "#tags.\(StringUtils.toCommonFileName(tagsConcat))")
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
        
        
        guard let parent = io.getNote(knownAs: collection.idToParse) else { return "" }
        let currentPosition = io.positionOfNote(parent)
        let (nextSortedNote, nextPosition) = io.nextNote(currentPosition)
        guard nextPosition.valid && nextSortedNote != nil else { return "" }
        
        var children: [SortedNote] = []
        
        let nextLevel = nextSortedNote!.note.level
        let nextSeq = nextSortedNote!.seqSingleValue

        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        var followingNote: SortedNote?
        followingNote = nextSortedNote
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
                followingLevel = followingNote!.note.level
                followingSeq = followingNote!.seqSingleValue
            }
        }
        
        let teasers = Markedup()
        let startingFormat = displayParms.format
        displayParms.format = .htmlFragment
        let mkdownOptions = displayParms.genMkdownOptions()
        
        for child in children {
            
            teasers.startParagraph()
            
            let seq = child.seqSingleValue
            if let seqStack = seq.seqStack {
                let finalSegment = seqStack.segments[seqStack.max]
                teasers.append("\(finalSegment.value). ")
            }
            let mkdown = MkdownParser(child.note.teaser.value, options: mkdownOptions)
            // mkdown.setWikiLinkFormatting(prefix: "", format: .fileName, suffix: ".html", context: workspace?.mkdownContext)
            // mkdown.setWikiLinkFormatting(prefix: "#", format: .fileName, suffix: "", context: workspace?.mkdownContext)
            mkdown.setWikiLinkFormatting(prefix: mkdownOptions.wikiLinks.prefix,
                                         format: mkdownOptions.wikiLinks.format,
                                         suffix: mkdownOptions.wikiLinks.suffix,
                                         context: self)
            mkdown.parse()
            let stripped = StringUtils.removeParagraphTags(mkdown.html)
            teasers.append(stripped)
 
            teasers.finishParagraph()
        }
        
        displayParms.format = startingFormat
        if displayedChildCount > 0 {
            collection.skipContentsForParent = true
        }
        
        return teasers.code
    }
    
    var author = ""
    
    /// Generate a bibliography from Notes following this one.
    public func mkdownBibliography() -> String {

        guard let collection = io.collection else { return "" }
        guard io.collectionOpen else { return "" }
        guard collection.seqFieldDef != nil else { return "" }
        guard collection.levelFieldDef != nil else { return "" }
        let sortParm = collection.sortParm
        guard sortParm == .seqPlusTitle || sortParm == .custom else { return "" }
        
        guard let parent = io.getNote(knownAs: collection.idToParse) else { return "" }
        
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        let currentPosition = io.positionOfNote(parent)
        var (nextSortedNote, nextPosition) = io.nextNote(currentPosition)
        guard nextPosition.valid && nextSortedNote != nil else { return "" }
        
        let biblio = Markedup(format: .htmlFragment)
        biblio.startOrderedList(klass: "notenik-biblio-list")
        let startingFormat = displayParms.format
        displayParms.format = .htmlFragment
        
        var worksCount = 0
        var authorKlassFound = false
        
        while nextSortedNote != nil
                && nextPosition.valid
                && nextSortedNote!.note.level > parent.level
                && nextSortedNote!.seqSingleValue > parent.seq.firstSeq {
            
            if nextSortedNote!.note.klass.value == NotenikConstants.authorKlass {
                author = nextSortedNote!.note.title.value
                authorKlassFound = true
            }
            
            if nextSortedNote!.note.hasAuthor() && !authorKlassFound {
                author = nextSortedNote!.note.author.lastNameFirst
            }
            
            if (nextSortedNote!.note.klass.value == NotenikConstants.workKlass || nextSortedNote!.note.hasWorkTitle()) && !author.isEmpty {
                biblio.startListItem()
                
                // Author
                if authorKlassFound {
                    let link = displayParms.wikiLinks.assembleWikiLink(idBasis: author)
                    let text = htmlConverter.convert(from: author)
                    biblio.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                    biblio.append(" ")
                } else {
                    biblio.append("\(author) ")
                }
                
                // Date
                if nextSortedNote!.note.hasDate() {
                    biblio.append("(\(nextSortedNote!.note.date.value)) ")
                }
                
                // Title of Work
                var workTitle = ""
                if nextSortedNote!.note.klass.value == NotenikConstants.workKlass {
                    workTitle = nextSortedNote!.note.title.value
                } else {
                    workTitle = nextSortedNote!.note.workTitle.value
                }
                let workType = nextSortedNote!.note.workType
                var citeKlass = ""
                if workType.isMajor {
                    citeKlass = "notenik-cite-major"
                } else {
                    citeKlass = "notenik-cite-minor"
                }
                
                biblio.startCite(klass: citeKlass)
                if !workType.isMajor {
                    biblio.leftDoubleQuote()
                }
                if nextSortedNote!.note.klass.value == NotenikConstants.workKlass {
                    let link = displayParms.wikiLinks.assembleWikiLink(idBasis: workTitle)
                    let text = htmlConverter.convert(from: workTitle)
                    biblio.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                } else {
                    biblio.append(workTitle)
                }
                
                if !workType.isMajor {
                    biblio.rightDoubleQuote()
                }
                biblio.finishCite()
                let workMajorTitle = nextSortedNote!.note.getFieldAsString(label: "workmajortitle")
                if !workMajorTitle.isEmpty {
                    biblio.append(", ")
                    biblio.startCite(klass: "notenik-cite-major")
                    biblio.append(workMajorTitle)
                    biblio.finishCite()
                }
                biblio.append(". ")
                
                let publisher = nextSortedNote!.note.getFieldAsString(label: NotenikConstants.publisherCommon)
                let pubCity = nextSortedNote!.note.getFieldAsString(label: NotenikConstants.pubCityCommon)
                if !publisher.isEmpty {
                    if !pubCity.isEmpty {
                        biblio.append("\(pubCity): ")
                    }
                    biblio.append("\(publisher). ")
                }
                
                // Web Link
                var workLink = ""
                if nextSortedNote!.note.hasLink() {
                    workLink = nextSortedNote!.note.link.value
                }
                if !workLink.isEmpty {
                    biblio.startLink(path: workLink, klass: "ext-link", blankTarget: true)
                    biblio.append("Link")
                    biblio.finishLink()
                }
                biblio.finishListItem()
                worksCount += 1
            }
            
            (nextSortedNote, nextPosition) = io.nextNote(nextPosition)
        }

        biblio.finishOrderedList()
        
        displayParms.format = startingFormat
        
        if worksCount > 0 {
            collection.skipContentsForParent = true
        }
        
        return biblio.code
    }
    
    
    /// Generate a table of authors.
    public func mkdownAuthorsTable() -> String {

        guard io.collectionOpen else { return "" }
        let authors = Markedup(format: .htmlFragment)
        
        // Generate the JavaScript
        let js = BigStringWriter()
        js.open()
        js.writeLine(tableSortScript())
        js.close()
        
        // Generate the HTML
        if displayParms.epub3 {
            javaScript = js.bigString
            if let collection = io.collection {
                let jsFileName = collection.fileNameToParse
                authors.script(src: "js/\(jsFileName).js")
            }
        } else {
            authors.startScript()
            authors.ensureNewLine()
            authors.append(js.bigString)
            authors.finishScript()
            authors.ensureBlankLine()
        }
        
        let tableID = "authors-table"
        
        authors.startTable(id: tableID)
        
        authors.startColGroup()
        authors.tableCol(style: "width:25%")
        authors.tableCol(style: "width:50%")
        authors.tableCol(style: "width:25%")
        authors.finishColGroup()
        
        authors.startTableRow()
        
        authors.startTableHeader(onclick: "sortTable(\'\(tableID)\', 0)")
        authors.write("Last Name")
        authors.finishTableHeader()
        
        authors.startTableHeader(onclick: "sortTable(\'\(tableID)\', 1)")
        authors.write("Author Name")
        authors.finishTableHeader()
        
        authors.startTableHeader(onclick: "sortTable(\'\(tableID)\', 2)")
        authors.write("Years Lived")
        authors.finishTableHeader()
        
        authors.finishTableRow()
        
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            if sortedNote!.note.klass.value == NotenikConstants.authorKlass {
                let note = sortedNote!.note
                authors.startTableRow()
                
                let author = AuthorValue(note.title.value)
                
                var lastName = author.lastName
                if lastName.isEmpty {
                    let nameBits = note.title.value.split(separator: ",")
                    if !nameBits.isEmpty {
                        lastName = String(nameBits[0])
                    }
                }
                authors.startTableData()
                authors.write(lastName)
                authors.finishTableData()
                
                authors.startTableData()
                let linkText = author.firstNameFirst
                let linkPath = displayParms.wikiLinks.assembleWikiLink(idBasis: note.noteID.getBasis())
                var linkTitle = ""
                if let authorInfo = note.getField(label: NotenikConstants.authorInfoCommon) {
                    linkTitle = authorInfo.value.value
                }
                authors.link(text: linkText, path: linkPath, title: linkTitle, klass: "implicit")
                authors.finishTableData()
                
                authors.startTableData()
                if let authorYears = note.getField(common: NotenikConstants.authorYearsCommon) {
                    authors.write(authorYears.value.value)
                }
                authors.finishTableData()
                
                authors.finishTableRow()
            }
            (sortedNote, position) = io.nextNote(position)
        }
        
        authors.finishTable()
        
        return authors.code
    }
    
    func tableSortScript() -> String {
        let sortScript = """
        function sortTable(tableID, n) {
          var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
          var firstElement = "";
          var nextElement = "";
          var firstLowered = "";
          var nextLowered = "";
          var firstNumber = 0;
          var nextNumber = 0;
          var firstValue = 0;
          var nextValue = 0;
          table = document.getElementById(tableID);
          switching = true;
          // Set the sorting direction to ascending:
          dir = "asc";
          /* Make a loop that will continue until
          no switching has been done: */
          while (switching) {
            // Start by saying: no switching is done:
            switching = false;
            rows = table.rows;
            /* Loop through all table rows (except the
            first, which contains table headers): */
            for (i = 1; i < (rows.length - 1); i++) {
              // Start by saying there should be no switching:
              shouldSwitch = false;
              /* Get the two elements you want to compare,
              one from current row and one from the next: */
              firstElement = rows[i].getElementsByTagName("TD")[n];
              nextElement = rows[i + 1].getElementsByTagName("TD")[n];
              firstLowered = firstElement.innerText.trim().toLowerCase();
              nextLowered = nextElement.innerText.trim().toLowerCase();
              firstNumber = Number(firstLowered);
              nextNumber = Number(nextLowered);
              if (isNaN(firstLowered) || isNaN(nextLowered)) {
                x = firstLowered;
                y = nextLowered;
              } else {
                x = firstNumber;
                y = nextNumber;
              }
              
              /* Check if the two rows should switch place,
              based on the direction, asc or desc: */
              if (dir == "asc") {
                if (x > y) {
                  // If so, mark as a switch and break the loop:
                  shouldSwitch = true;
                  break;
                }
              } else if (dir == "desc") {
                if (x < y) {
                  // If so, mark as a switch and break the loop:
                  shouldSwitch = true;
                  break;
                }
              }
            }
            if (shouldSwitch) {
              /* If a switch has been marked, make the switch
              and mark that a switch has been done: */
              rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
              switching = true;
              // Each time a switch is done, increase this count by 1:
              switchcount ++;
            } else {
              /* If no switching has been done AND the direction is "asc",
              set the direction to "desc" and run the while loop again. */
              if (switchcount == 0 && dir == "asc") {
                dir = "desc";
                switching = true;
              }
            }
          }
        }
        """
        return sortScript
    }
    
    /// Provide links to file attachments.
    public func mkdownAttachments() -> String {
        guard let collection = io.collection else { return "" }
        guard !collection.idToParse.isEmpty else { return "" }
        guard let note = io.getNote(knownAs: collection.idToParse) else { return "" }
        let noteLink = note.getNotenikLink(preferringTimestamp: true)
        guard !note.attachments.isEmpty else { return "" }
        let html = Markedup(format: .htmlFragment)
        html.paragraph(text: "See attached files:")
        html.startUnorderedList(klass: nil)
        for attachment in note.attachments {
            html.startListItem()
            let aLink = "\(noteLink)&attachment=\(attachment.suffix)"
            html.startLink(path: aLink)
            html.append(attachment.suffix + attachment.ext.originalExtWithDot)
            html.finishLink()
            html.finishListItem()
        }
        html.finishUnorderedList()
        return html.code
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
    
    class LevelInfo {
        var level = 0
        var hasChildren = false
        
        init(level: Int, hasChildren: Bool) {
            self.level = level
            self.hasChildren = hasChildren
        }
    }
}
