//
//  NotesMkdownContext.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/12/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
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
    // var collection = NoteCollection()
    var displayParms = DisplayParms()
    
    let htmlConverter = StringConverter()
    
    public init(io: NotenikIO, displayParms: DisplayParms? = nil) {
        self.io = io
        if displayParms != nil {
            self.displayParms = displayParms!
        }
        htmlConverter.addHTML()
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
    public func mkdownWikiLinkLookup(linkText: String) -> String {
        guard io.collection != nil else { return linkText }
        guard io.collectionOpen else { return linkText }
        guard io.collection!.hasTimestamp else { return linkText }
        
        // Check for first possible case: title within the wiki link
        // points directly to another note having that same title.
        let titleID = StringUtils.toCommon(linkText)
        var linkedNote = io.getNote(forID: titleID)
        if linkedNote != nil {
            io.aliasList.add(titleID: titleID, timestamp: linkedNote!.timestamp.value)
            return linkText
        }
        
        // Check for second possible case: title within the wiki link
        // used to point directly to another note having that same title,
        // but the target note's title has since been modified.
        let timestamp = io.aliasList.get(titleID: titleID)
        if timestamp != nil {
            linkedNote = io.getNote(forTimestamp: timestamp!)
            if linkedNote != nil {
                return linkedNote!.title.value
            }
        }
        
        // Check for third possible case: string within the wiki link
        // is already a timestamp pointing to another note.
        guard linkText.count < 15 && linkText.count > 11 else { return linkText }
        linkedNote = io.getNote(forTimestamp: linkText)
        if linkedNote != nil {
            return linkedNote!.title.value
        }
        
        // Nothing worked, so just return the linkText.
        return linkText
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
        guard io.collection != nil else { return "" }
        guard io.collectionOpen else { return "" }
        let collection = io.collection!
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        levels = []
        toc = Markedup(format: .htmlFragment)
        var (note, position) = io.firstNote()
        while note != nil {
            genTocEntry(for: note!)
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
        if seq.count > 0 {
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
    public func mkdownTagsOutline() -> String {
        guard io.collection != nil else { return "" }
        guard io.collectionOpen else { return "" }
        tagsCode = Markedup(format: .htmlFragment)
        tagsListLevel = 0
        openTagsList()
        let iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        while tagsNode != nil {
            generateTagsNode(node: tagsNode!, depth: iterator.depth)
            tagsNode = iterator.next()
        }
        closeTagContent(downTo: 0)
        return tagsCode.code
    }
    
    /// Generate html code for the next node.
    func generateTagsNode(node: TagsNode, depth: Int) {
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
    
    func openTagsList() {
        tagsCode.startUnorderedList(klass: nil)
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
