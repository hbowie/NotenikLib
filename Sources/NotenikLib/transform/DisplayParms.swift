//
//  DisplayParms.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/7/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// All of the parameters used to control the way a Note is converted to HTML. 
public class DisplayParms {
    
    let htmlConverter = StringConverter()
    
    public var cssString = ""
    public var cssLinkToFile = false
    public var displayTemplate = ""
    public var format: MarkedupFormat = .htmlDoc
    public var epub3 = false
    public var sortParm: NoteSortParm = .seqPlusTitle
    public var displayMode: DisplayMode = .normal
    public var concatenated = false
    public var wikiLinks = WikiLinkDisplay()
    public var mathJax = false
    public var localMj = true
    public var localMjUrl: URL?
    public var curlyApostrophes = true
    public var extLinksOpenInNewWindows = false
    public var imagesPath = ""
    public var header = ""
    public var included = IncludeChildrenValue()
    public var includedList = ""
    public var checkBoxMessageHandlerName = ""
    public var inlineHashtags = false
    public var addins: [String] = []
    
    public init() {
        htmlConverter.addHTML()
    }
    
    /// Set various values that are taken from the Note's Collection.
    public func setFrom(note: Note) {
        setFrom(collection: note.collection)
    }
    
    /// Set various values that are taken from metadata about the Collection.
    public func setFrom(collection: NoteCollection) {
        if !collection.selCSSfile.isEmpty {
            cssLinkToFile = true
            cssString = NotenikConstants.cssFolderName + "/" + collection.selCSSfile + ".css"
        } else {
            cssLinkToFile = false
            setCSS(useFirst: collection.displayCSS, useSecond: DisplayPrefs.shared.displayCSS)
        }
        displayTemplate = collection.displayTemplate
        format = .htmlDoc
        sortParm = collection.sortParm
        displayMode = collection.displayMode
        mathJax = collection.mathJax
        curlyApostrophes = collection.curlyApostrophes
        extLinksOpenInNewWindows = collection.extLinksOpenInNewWindows
        if collection.hashTagsOption == .inlineHashtags {
            inlineHashtags = true
        }
        for addInURL in collection.addins {
            addins.append(NotenikConstants.addinsFolderName + "/" + addInURL.lastPathComponent)
        }
    }
    
    public func genMkdownOptions() -> MkdownOptions {
        let options = MkdownOptions()
        setMkdownOptions(options)
        return options
    }
    
    public func setMkdownOptions(_ options: MkdownOptions) {
        self.wikiLinks.copyTo(another: options.wikiLinks)
        options.mathJax = mathJax
        options.localMj = localMj
        options.localMjUrl = localMjUrl
        options.curlyApostrophes = curlyApostrophes
        options.extLinksOpenInNewWindows = extLinksOpenInNewWindows
        options.checkBoxMessageHandlerName = checkBoxMessageHandlerName
        options.inlineHashtags = inlineHashtags
    }
    
    public var formatIsHTML: Bool {
        switch format {
        case .htmlDoc, .xhtmlDoc, .htmlFragment:
            return true
        default:
            return false
        }
    }
    
    public var fullDisplay: Bool {
        switch displayMode {
        case .normal:
            return true
        case .presentation:
            return false
        case .streamlinedReading:
            return false
        case .quotations:
            return false
        case .custom:
            return false
        case .continuous:
            return false
        }
    }
    
    public var displayTags: Bool {
        switch displayMode {
        case .normal:
            return true
        case .presentation:
            return false
        case .streamlinedReading:
            return false
        case .continuous:
            return false
        case .quotations:
            return false
        case .custom:
            return false
        }
    }
    
    public var reducedDisplay: Bool {
        switch displayMode {
        case .normal:
            return false
        case .presentation:
            return true
        case .streamlinedReading:
            return true
        case .quotations:
            return true
        case .continuous:
            return true
        case .custom:
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
    
    public func streamlinedTitleWithLink(markedup: Markedup, note: Note, klass: String?) {

        let idBasis = note.noteID.getBasis()
        var seqPrefix = ""
        if note.klass.frontOrBack || note.klass.quote {
            // no need for a preceding number
        } else if note.hasDisplaySeq() {
            seqPrefix = note.formattedDisplaySeq + " "
        } else {
            seqPrefix = note.getFormattedSeq() + " "
        }
        if !seqPrefix.isEmpty {
            markedup.append(seqPrefix)
        }
        var idToUse = ""
        if wikiLinks.prefix == "#" {
            idToUse = seqPrefix + idBasis
        } else {
            idToUse = idBasis
        }
        var text = note.noteID.text
        if note.noteID.seqBeforeTitle {
            text = note.title.value
        }
        let htmlText = htmlConverter.convert(from: text)
        let wikiLink = wikiLinks.assembleWikiLink(idBasis: idToUse)
        markedup.link(text: htmlText,
                      path: wikiLink,
                      klass: klass)
    }
    
    
    /// Format the title with a possible preceding sequence number, when
    /// engaged in Streamlined Reading.
    /// - Parameter note: The Note whose title is to be formatted.
    /// - Returns: The title of the Note, possibly preceded by a
    ///   Sequence number of one kind or another. 
    public func compoundTitle(note: Note) -> String {
        let simpleTitle = note.title.value
        guard displayMode != .normal else { return simpleTitle }
        guard !included.asList else { return simpleTitle }
        guard !note.klass.frontOrBack else { return simpleTitle }
        guard !note.klass.quote else { return simpleTitle }
        if note.collection.sortParm == .seqPlusTitle {
            if note.hasDisplaySeq() {
                return note.formattedDisplaySeq + simpleTitle
            } else if note.hasSeq() {
                return note.getFormattedSeq() + " " + simpleTitle
            } else {
                return simpleTitle
            }
        } else {
            return simpleTitle
        }
    }
    
    public func display(by: String) {
        print ("DisplayParms.display requested by \(by)")
        print("  - css string = \(cssString)")
        print("  - css link to file = \(cssLinkToFile)")
        print("  - display template = \(displayTemplate)")
        print("  - marked up format = \(format)")
        print("  - sort parm = \(sortParm)")
        print("  - display mode = \(displayMode)")
        print("  - wiki link format = \(wikiLinks.format)")
        print("  - wiki link prefix = \(wikiLinks.prefix)")
        print("  - wiki link suffix = \(wikiLinks.suffix)")
    }
}
