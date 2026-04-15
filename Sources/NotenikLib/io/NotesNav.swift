//
//  NotesNav.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/14/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A collection of static functions that can be used to provide common navigation aids.
public class NotesNav {
    
    // The passed variable name must start with this literal.
    public static let navLit = "nav"
    
    // The next portion of the variable name must indicate the desired
    // navigation direction, using one of the followng literals.
    public static let nextLit   = "next"
    public static let prevLit   = "prev"
    public static let priorLit  = "prior"
    public static let homeLit   = "home"
    public static let topLit    = "top"
    public static let parentLit = "parent"
    
    // The third portion of the variable name should describe the
    // data that is desired to be returned.
    public static let titleLit  = "title"
    public static let linkLit   = "link"
    public static let bookLit   = "book"
    public static let slidesLit = "slides"
    
    // The last, optional, portion of the variable name indicates a
    // desired format/variant. This is generally meaningful only with
    // the title data descriptor.
    public static let commonLit      = "common"
    public static let htmlLit        = "html"
    public static let macFilenameLit = "macfilename"
    public static let plainLit       = "plain"
    public static let trimmedLit     = "trimmed"
    public static let webFilenameLit = "webfilename"
    
    private init() {
        
    }
    
    /// Generate link text and/or URL, or both combined with some helpful HTML. Note that this function
    /// makes calls to the other functions included in this class.
    /// - Parameters:
    ///   - varName: The variable name to be expanded.
    ///   - fromNote: The starting point for the navigation.
    ///   - startingIndex: An index pointer to the starting positon in trhe notes list.
    ///   - notesList: Thesorted  list of notes that makes up the collection.
    ///   - parms: Desired display parms, used for formatting links.
    /// - Returns: The requested info, in string form, suitable for insertion into a text-based template.
    public static func genNavSlug(varName: String,
                                  fromNote: Note,
                                  startingIndex: Int,
                                  notesList: NotesList,
                                  parms: DisplayParms) -> String? {
        
        // Make sure we have the expected sort of variable name.
        let nameSegments = getNavParms(varName: varName)
        guard nameSegments.count > 0 else { return nil }
        
        // Now try to get the desired note to which navigation is desired.
        let navDirection = String(nameSegments[0])
        let (navPosition, navSortedNote) = navToNote(navDirection: navDirection,
                                                     fromNote: fromNote,
                                                     startingIndex: startingIndex,
                                                     notesList: notesList)
        if navPosition < 0 || navSortedNote == nil {
            return nil
        }
        
        // Now see what sort of data caller is looking for.
        var descriptor = ""
        if nameSegments.count > 1 {
            descriptor = String(nameSegments[1])
        }
        
        var format = ""
        if nameSegments.count > 2 {
            format = String(nameSegments[2])
        }

        if descriptor == linkLit {
            return getNavData(descriptor: descriptor, format: format, note: navSortedNote!.note, parms: parms)
        }
        
        if descriptor == titleLit {
            return getNavData(descriptor: descriptor, format: format, note: navSortedNote!.note, parms: parms)
        }
        
        let text = NotesNav.getNavData(descriptor: titleLit, format: htmlLit, note: navSortedNote!.note, parms: parms)
        let path = NotesNav.getNavData(descriptor: linkLit, format: "", note: navSortedNote!.note, parms: parms)
        
        return NotesNav.layOutNavData(navDirection: navDirection,
                                      descriptor: descriptor,
                                      text: text,
                                      path: path,
                                      navPosition: navPosition,
                                      notesList: notesList,
                                      withinParagraph: true)
    }
    
    /// Breaks the variable name down into  meaningful segments.
    /// - Parameters:
    ///   - varName: The variable name to be expanded.
    /// - Returns: The meaningful parts of the variable name — see literals above.
    public static func getNavParms(varName: String) -> [String] {
        
        var parms: [String] = []
        
        // Should start with nav
        let (navLit, remaining1) = getFrontAndTrim(remainingVarName: varName, validStarts: [navLit])
        guard !navLit.isEmpty else { return [] }
        
        let (navDirection, remaining2) = getFrontAndTrim(remainingVarName: remaining1,
                                                         validStarts: [nextLit, prevLit, priorLit, homeLit, topLit, parentLit])
        guard !navDirection.isEmpty else { return [] }
        parms.append(navDirection)
        
        if remaining2.isEmpty {
            parms.append("")
            parms.append("")
            return parms
        }
        
        let (navDescriptor, remaining3) = getFrontAndTrim(remainingVarName: remaining2, validStarts: [titleLit, linkLit, bookLit, slidesLit])
        parms.append(navDescriptor)
        
        if remaining3.isEmpty {
            parms.append("")
            return parms
        }
        
        var formats: [String] = []
        for format in TitleFormat.allCases {
            formats.append(format.rawValue)
        }
        let (navFormat, _) = getFrontAndTrim(remainingVarName: remaining3, validStarts: formats)
        parms.append(navFormat)
        
        return parms
    }
    
    /// Extracts the next meaningful bit from the variable name.
    /// - Parameters:
    ///   - remainingVarName: The portion of the varialble name still to be examined.
    ///   - validStarts: A list of valid strings that might be found on the front of the remaining variable name.
    /// - Returns: The match that was found, if any; and what remains after the match has been removed.
    public static func getFrontAndTrim(remainingVarName: String,
                                       validStarts: [String]) -> (String, String) {
        var matchingStart = ""
        var remaining = remainingVarName
        for possibleStart in validStarts {
            if remainingVarName.starts(with: possibleStart) {
                matchingStart = possibleStart
                remaining.removeFirst(matchingStart.count)
                break
            }
        }
        return (matchingStart, remaining)
    }
    
    /// Perform the requested navigation.
    /// - Parameters:
    ///   - navDirection: The direction of the navigation (see literals defined above).
    ///   - startingIndex: The notes list index pointing to the starting point.
    ///   - notesList: The complete list of notes to be navigated.
    /// - Returns: The index pointing to the destination found after the navigation,; and the sorted note at that position.
    public static func navToNote(navDirection: String,
                                 fromNote: Note,
                                 startingIndex: Int,
                                 notesList: NotesList) -> (Int, SortedNote?) {
        // Now try to get the desired note to which navigation is desired.
        var navIndex = startingIndex
        switch navDirection {
        case nextLit:
            navIndex += 1
            while navIndex < notesList.count && notesList[navIndex].note.excludeFromBook(epub: false) {
                navIndex += 1
            }
        case prevLit, priorLit:
            navIndex -= 1
            while navIndex > 0 && notesList[navIndex].note.excludeFromBook(epub: false) {
                navIndex -= 1
            }
        case homeLit, topLit:
            navIndex = 0
        case parentLit:
             guard fromNote.hasSeq() || fromNote.hasLevel() else {
                 return (-1, nil)
             }
             guard startingIndex > 0 else { return (-1, nil) }
             
             let depth = fromNote.depth
             navIndex -= 1
             var aboveDepth = depth
             while navIndex >= 0 && aboveDepth >= depth {
                 let aboveNote = notesList[navIndex].note
                 aboveDepth = aboveNote.depth
                 if aboveDepth >= depth {
                     navIndex -= 1
                 }
             }
             
             guard navIndex >= 0 && aboveDepth < depth else {
                 return (-1, nil)
             }
        default:
            return (-1, nil)
        }
        
        if navIndex >= notesList.count {
            navIndex = 0
        }
        if navIndex < 0 {
            navIndex = 0
        }
        
        let navSortedNote = notesList[navIndex]
        return (navIndex, navSortedNote)
    }
    
    /// Once we have the desination for the navigation, return whatever associated data is being requested.
    /// - Parameters:
    ///   - descriptor: The descriptor identifying the data to be retrieved.
    ///   - format: The desired format, if any.
    ///   - note: The  note from which the data is to be extracted.
    ///   - parms: The display parms controlling the formatting of links.
    /// - Returns: A string containing the desired data.
    public static func getNavData(descriptor: String,
                                  format: String,
                                  note: Note,
                                  parms: DisplayParms) -> String {
        // Now format as requested.
        switch descriptor {
        case titleLit:
            var titleFormat: TitleFormat = .plain
            if let fmt = TitleFormat(rawValue: format) {
                titleFormat = fmt
            }
            return note.title.getTitle(format: titleFormat)
        case linkLit:
            return parms.wikiLinks.assembleWikiLink(idBasis: note.noteID.basis)
        default:
            return note.title.getTitle(format: .plain)
        }
    }
    
    /// Generate appropriate HTML for the navigation link.
    /// - Parameters:
    ///   - navDirection: The direction of the navigation (see literals defined above).
    ///   - descriptor: The descriptor identifying the data to be retrieved.
    ///   - text: The text to be placed in a link.
    ///   - path: The path (aka link) to be included.
    ///   - navPosition: The index pointing to the destination.
    ///   - withinParagraph: Should the result be enclosed within paragraph tags?
    /// - Returns: HTML for the desired link.
    public static func layOutNavData(navDirection: String,
                                     descriptor: String,
                                     text: String,
                                     path: String,
                                     navPosition: Int,
                                     notesList: NotesList,
                                     withinParagraph: Bool) -> String {
        
        var navLabel = navDirection.capitalized
        var navSeq = ""
        var navText = text
        var navSuffix = ""
        switch descriptor {
        case bookLit:
            if navDirection == nextLit && navPosition == 0 {
                navLabel = "Back to Top"
            }
            navLabel.append(": ")
            if navDirection == parentLit {
                navLabel = ""
                let parent = notesList[navPosition].note
                let parentSeq = parent.seq
                if parentSeq.count > 0 {
                    if !parent.klass.frontOrBack {
                        navSeq = ("\(parentSeq) ")
                        navSuffix.append("&nbsp;")
                        navSuffix.append("&#8593;")
                    }
                }
            }
        case slidesLit:
            navText = navLabel
            navLabel = ""
        default:
            break
        }
        
        let navHTML = Markedup()
        if withinParagraph {
            navHTML.startParagraph()
        }
        navHTML.append(navLabel)
        navHTML.append(navSeq)
        navHTML.link(text: navText,
                      path: path,
                      klass: Markedup.htmlClassNavLink)
        navHTML.append(navSuffix)
        if withinParagraph {
            navHTML.finishParagraph()
        }
        return navHTML.code
    }
}
