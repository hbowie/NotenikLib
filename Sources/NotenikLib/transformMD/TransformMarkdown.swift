//
//  TransformMarkdown.swift
//  NotenikLib
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 9/7/23.
//

import Foundation

import NotenikMkdown
import NotenikUtils

import Down
import Ink

/// Transform Markdown to HTML, using/producing special Notenik data.
///
/// If Collection Prefs request creation of missing wiki link targets, then create those if found. 
public class TransformMarkdown {
    
    /// Convert Markdown to HTML.
    /// - Parameters:
    ///   - parserID: Indicated which parser to use: down, ink or notenik.
    ///   - fieldType: The field type: generally body, but also longtext & teaser.
    ///   - markdown: The string of Markdown text to be converted.
    ///   - io: The I/O module for the Collection containing the Markdown text.
    ///   - parms: The Display Parms to be used.
    ///   - results: The object in which to store the results of the parsing.
    ///   - noteTitle: The title of the Note containing the Markdown to be parsed. .
    ///   - shortID: The Short ID for the Note, if it has one.
    public static func mdToHtml(parserID: String,
                                fieldType: String,
                                markdown: String,
                                io: NotenikIO?,
                                parms: DisplayParms,
                                results: TransformMdResults,
                                noteID: String = "",
                                noteText: String = "",
                                noteFileName: String = "",
                                note: Note? = nil) {
                
        // Transform using Down, if requested.
        if parserID == NotenikConstants.downParser {
            let down = Down(markdownString: markdown)
            do {
                results.html = try down.toHTML(DownOptions.smartUnsafe)
                results.ok = true
            } catch {
                Logger.shared.log(subsystem: "com.powersurgepub.noteniklib",
                                  category: "TransformMarkdown",
                                  level: .error,
                                  message: "Down parser threw an error")
                results.ok = false
            }
            return
        }
        
        // Transform using Ink, if requested.
        if parserID == NotenikConstants.inkParser {
            let ink = MarkdownParser()
            results.html = ink.html(from: markdown)
            return
        }

        let mkdownOptions = MkdownOptions()
        parms.setMkdownOptions(mkdownOptions)
        if fieldType != NotenikConstants.bodyCommon {
            mkdownOptions.checkBoxMessageHandlerName = ""
        }
        
        var noteShortID = ""
        if note != nil && note!.hasShortID() {
            noteShortID = note!.shortID.value
        }
        
        if io == nil {
            results.mkdownContext = nil
        } else {
            results.mkdownContext = NotesMkdownContext(io: io!, displayParms: parms)
            results.mkdownContext!.identifyNoteToParse(id: noteID,
                                                       text: noteText,
                                                       fileName: noteFileName,
                                                       shortID: noteShortID)
            results.mkdownContext!.clearIncludedNotes()
            io!.collection!.skipContentsForParent = false
        }
        
        mkdownOptions.shortID = noteShortID
        
        let mdParser = MkdownParser(markdown, options: mkdownOptions)
        mdParser.setWikiLinkFormatting(prefix: parms.wikiLinks.prefix,
                                       format: parms.wikiLinks.format,
                                       suffix: parms.wikiLinks.suffix,
                                       context: results.mkdownContext)
        mdParser.parse()
        results.html = mdParser.html
        
        if fieldType == NotenikConstants.bodyCommon {
            results.bodyHTML = mdParser.html
            results.counts = mdParser.counts
            if io?.collection?.minutesToReadDef != nil {
                results.minutesToRead = MinutesToReadValue(with: results.counts)
            }
        }
        
        results.wikiLinks.addList(moreLinks: mdParser.wikiLinkList)
        if let collection = io?.collection {
            if collection.missingTargets {
                for link in mdParser.wikiLinkList.links {
                    if !link.targetFound {
                        let target = link.originalTarget
                        let multi = MultiFileIO.shared
                        var targetIO = io!
                        if target.hasPath {
                            let (targetCollection, maybeIO) = multi.provision(shortcut: target.path, inspector: nil, readOnly: false)
                            if targetCollection != nil {
                                targetIO = maybeIO
                            }
                        }
                        let newNote = Note(collection: targetIO.collection!)
                        _ = newNote.setTitle(target.item)
                        
                        if collection.levelFieldDef != nil && note != nil && note!.hasLevel() {
                            _ = newNote.setLevel(note!.level.value)
                        }
                        if collection.klassFieldDef != nil && note != nil && note!.hasKlass() {
                            _ = newNote.setKlass(note!.klass.value)
                        }
                        if collection.seqFieldDef != nil && note != nil && note!.hasSeq() {
                            let seq = note!.seq
                            seq.increment()
                            _ = newNote.setSeq(seq.value)
                            
                        }
                        newNote.identify()
                        if collection.backlinksDef == nil && !target.hasPath {
                            _ = newNote.setBody("Created by Wiki-style Link found in the Markdown code for the Note identified as [[\(noteID)]].")
                        } else {
                            _ = newNote.setBacklinks(noteID)
                            _ = newNote.setBody("Created by Wiki-style Link found in the Markdown code for the Note identified as \(noteText).")
                        }
                        _ = targetIO.addNote(newNote: newNote)
                        results.wikiAdds = true
                    }
                }
            }
        }
        return
    }
    
}
