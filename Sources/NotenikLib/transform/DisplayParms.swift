//
//  DisplayParms.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/7/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// All of the parameters used to control the way a Note is converted to HTML. 
public class DisplayParms {
    
    public var cssString = ""
    public var cssLinkToFile = false
    public var displayTemplate = ""
    public var format: MarkedupFormat = .htmlDoc
    public var epub3 = false
    public var sortParm: NoteSortParm = .seqPlusTitle
    public var streamlined = false
    public var fullDisplay: Bool { return !streamlined }
    public var concatenated = false
    public var wikiLinkFormat: WikiLinkFormat = .common
    public var wikiLinkPrefix = "https://ntnk.app/"
    public var wikiLinkSuffix = ""
    public var mathJax = false
    public var localMj = true
    public var localMjUrl: URL?
    public var curlyApostrophes = true
    public var extLinksOpenInNewWindows = false
    public var imagesPath = ""
    public var header = ""
    public var included = IncludeChildrenValue()
    public var includedList = ""
    
    public init() {
        
    }
    
    public func initWikiLinkFormatting() {
        wikiLinkFormat = .common
        wikiLinkPrefix = "https://ntnk.app/"
        wikiLinkSuffix = ""
    }
    
    /// Set various values that are taken from the Note's Collection.
    public func setFrom(note: Note) {
        setFrom(collection: note.collection)
    }
    
    /// Set various values that are taken from metadata about the Collection.
    public func setFrom(collection: NoteCollection) {
        setCSS(useFirst: collection.displayCSS, useSecond: DisplayPrefs.shared.displayCSS)
        displayTemplate = collection.displayTemplate
        format = .htmlDoc
        sortParm = collection.sortParm
        streamlined = collection.streamlined
        mathJax = collection.mathJax
        curlyApostrophes = collection.curlyApostrophes
        extLinksOpenInNewWindows = collection.extLinksOpenInNewWindows
    }
    
    public func genMkdownOptions() -> MkdownOptions {
        let options = MkdownOptions()
        setMkdownOptions(options)
        return options
    }
    
    public func setMkdownOptions(_ options: MkdownOptions) {
        options.wikiLinkPrefix = wikiLinkPrefix
        options.wikiLinkSuffix = wikiLinkSuffix
        options.wikiLinkFormatting = wikiLinkFormat
        options.mathJax = mathJax
        options.localMj = localMj
        options.localMjUrl = localMjUrl
        options.curlyApostrophes = curlyApostrophes
        options.extLinksOpenInNewWindows = extLinksOpenInNewWindows
    }
    
    public var formatIsHTML: Bool {
        switch format {
        case .htmlDoc, .xhtmlDoc, .htmlFragment:
            return true
        default:
            return false
        }
    }
    
    /// Set the CSS string from one of two sources, giving preference to the first.
    public func setCSS(useFirst: String, useSecond: String?) {
        if useFirst.count > 0 {
            cssString = useFirst
        } else if useSecond != nil {
            cssString = useSecond!
        } else {
            cssString = ""
        }
    }
    
    func assembleWikiLink(target: WikiLinkTarget) -> String {
        return wikiLinkPrefix + target.formatWikiLink(format: wikiLinkFormat) + wikiLinkSuffix
    }
    
    /// Create a wiki link, based on the wiki parms.
    func assembleWikiLink(title: String) -> String {
        return wikiLinkPrefix + formatWikiLink(title) + wikiLinkSuffix
    }
    
    /// Convert a title to something that can be used in a link.
    func formatWikiLink(_ title: String) -> String {
        switch wikiLinkFormat {
        case .common:
            return StringUtils.toCommon(title)
        case .fileName:
            return StringUtils.toCommonFileName(title)
        }
    }
    
    public func streamlinedTitleWithLink(markedup: Markedup, note: Note, klass: String?) {
        let simpleTitle = note.title.value
        if note.klass.frontOrBack || note.klass.quote {
            // no need for a preceding number
        } else if note.hasDisplaySeq() {
            markedup.append(note.formattedDisplaySeq + " ")
        } else {
            markedup.append(note.formattedSeq + " ")
        }
        markedup.link(text: simpleTitle, path: assembleWikiLink(title: simpleTitle), klass: klass)
    }
    
    
    /// Format the title with a possible preceding sequence number, when
    /// engaged in Streamlined Reading.
    /// - Parameter note: The Note whose title is to be formatted.
    /// - Returns: The title of the Note, possibly preceded by a
    ///   Sequence number of one kind or another. 
    public func streamlinedTitle(note: Note) -> String {
        let simpleTitle = note.title.value
        guard streamlined else { return simpleTitle }
        guard !included.asList else { return simpleTitle }
        guard !note.klass.frontOrBack else { return simpleTitle }
        guard !note.klass.quote else { return simpleTitle }
        if note.hasDisplaySeq() {
            return note.formattedDisplaySeq + simpleTitle
        } else if note.hasSeq() {
            return note.formattedSeq + " " + simpleTitle
        } else {
            return simpleTitle
        }
    }
    
    public func displayWikiLinkFields() {
        print("DisplayParms wiki link format: \(wikiLinkPrefix) + \(wikiLinkFormat) + \(wikiLinkSuffix)")
    }
    
    public func display(by: String) {
        print ("DisplayParms.display requested by \(by)")
        print("  - css string = \(cssString)")
        print("  - display template = \(displayTemplate)")
        print("  - marked up format = \(format)")
        print("  - sort parm = \(sortParm)")
        print("  - streamlined? \(streamlined)")
        print("  - wiki link format = \(wikiLinkFormat)")
        print("  - wiki link prefix = \(wikiLinkPrefix)")
        print("  - wiki link suffix = \(wikiLinkSuffix)")
    }
}
