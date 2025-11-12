//
//  QuotesToBiblio.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/03/2025.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A class that transform quotations in quotes format into a Bibliography format.
public class QuotesToBiblio {
    
    var quotesIO: NotenikIO!
    var biblioIO: NotenikIO!
    var existingIO: NotenikIO? = nil
    
    var biblioCollection: NoteCollection?
    
    var quotesAdded = 0
    
    var authorSeq: SeqValue!
    var workSeq: SeqValue!
    var quoteSeq: SeqValue!
    var authorSeqLevel = 0
    var workSeqLevel = 1
    var quoteSeqLevel = 2
    
    var lastAuthor = ""
    var lastWork = ""
    
    public init?(quotesURL: URL, biblioURL: URL, existingURL: URL? = nil) {
        
        quotesIO = FileIO()
        let realm = quotesIO.getDefaultRealm()
        realm.path = ""
        let quotesCollection = quotesIO.openCollection(realm: realm,
                                                       collectionPath: quotesURL.path,
                                                       readOnly: true,
                                                       multiRequests: nil)
        if quotesCollection == nil {
            logError("Problems opening the quotes collection at " + quotesURL.path)
            return nil
        }

        biblioIO = FileIO()
        biblioCollection = biblioIO.openCollection(realm: realm,
                                                   collectionPath: biblioURL.path,
                                                   readOnly: false,
                                                   multiRequests: nil)!
        if biblioCollection == nil {
            logError("Problems opening the biblio collection at " + biblioURL.path)
            return nil
        }
        
        if existingURL != nil {
            existingIO = FileIO()
            let existingCollection = existingIO!.openCollection(realm: realm,
                                                                collectionPath: existingURL!.path,
                                                                readOnly: true,
                                                                multiRequests: nil)
            if existingCollection == nil {
                logError("Problems opening the existing collection at " + existingURL!.path)
                return nil
            }
        }
    }
    
    public init(quotesIO: NotenikIO!, biblioIO: NotenikIO!, existingIO: NotenikIO? = nil) {
        self.quotesIO = quotesIO
        self.biblioIO = biblioIO
        self.existingIO = existingIO
        
        biblioCollection = biblioIO.collection!
    }
    
    public func transform() {
        quotesAdded = 0
        let seqParms = SeqParms()
        authorSeq = SeqValue("3.4.0", seqParms: seqParms)
        workSeq = SeqValue("3.4.0.0", seqParms: seqParms)
        quoteSeq = SeqValue("3.4.0.0.0", seqParms: seqParms)
        authorSeqLevel = 2
        workSeqLevel = 3
        quoteSeqLevel = 4
        
        var (quote, position) = quotesIO.firstNote()
        while quote != nil {
            let quoteTitle = quote!.note.title.value
            let biblioNote = biblioIO.getNote(knownAs: quoteTitle)
            var existingNote: Note? = nil
            if existingIO != nil {
                existingNote = existingIO!.getNote(knownAs: quoteTitle)
            }
            if biblioNote == nil && existingNote == nil {
                transformOneNote(quote: quote!)
            }
            (quote, position) = quotesIO.nextNote(position)
        }
        
        logInfo("Added \(quotesAdded) biblio quotes")
    }
    
    func transformOneNote(quote: SortedNote) {
        
        print("  - transformOneNote titled \(quote.note.title.value)")
        // Generate the Author note
        let author = quote.note.author.value
        print("    + author = \(author)")
        if !author.isEmpty {
            genAuthor(quote: quote, author: author)
        }
        
        // Generate the work note
        let work = quote.note.workTitle.value
        print("    + work = \(work)")
        if !work.isEmpty && work.lowercased() != "unknown" {
            genWork(quote: quote, author: author, work: work)
        }
        
        genQuote(quote: quote)
        
        lastAuthor = author
        lastWork = work
    }
    
    func genAuthor(quote: SortedNote, author: String) {
        print("      * generating author")
        guard author != lastAuthor else {
            print("        > Same author - skip")
            return
        }
        let authorValue = AuthorValue(author)
        let authorForBiblio = authorValue.lastNameFirst
        var authorNote: Note? = biblioIO.getNote(knownAs: authorForBiblio)
        if authorNote == nil {
            authorNote = Note(collection: biblioCollection!)
            _ = authorNote!.setTitle(authorForBiblio)
            
            print("        > Incrementing author seq")
            print("        > author seq level = \(authorSeqLevel)")
            print("        > starting author seq = \(authorSeq.value)")
            authorSeq.incAtLevel(level: authorSeqLevel, removingDeeperLevels: true)
            print("        > author seq after inc = \(authorSeq.value)")
            workSeq = authorSeq.dupe()
            quoteSeq = workSeq.dupe()
            print("        > Setting seq for author note titled \(authorForBiblio) to \(authorSeq.value)")
            _ = authorNote!.setSeq(authorSeq.value)
            _ = authorNote!.setLevel(3)
            _ = authorNote!.setKlass("author")
            if let quoteLinkField = FieldGrabber.getField(note: quote.note, label: "Author Link") {
                _ = authorNote!.setLink(quoteLinkField.value.value)
            }
            if let quoteAuthorInfoField = FieldGrabber.getField(note: quote.note, label: "Author Info") {
                _ = authorNote!.setField(label: "Author Info", value: quoteAuthorInfoField.value.value)
            }
            if let quoteAuthorYearsField = FieldGrabber.getField(note: quote.note, label: "Author Years") {
                _ = authorNote!.setField(label: "Author Years", value: quoteAuthorYearsField.value.value)
            }
            _ = biblioIO.addNote(newNote: authorNote!)
        } else {
            print("        > author already exists with seq of \(authorNote!.seq.value)")
            authorSeq = authorNote!.seq.dupe()
            authorSeqLevel = authorSeq.numberOfLevels - 1
            workSeq = authorSeq.dupe()
            workSeqLevel = authorSeq.numberOfLevels
            quoteSeq = workSeq.dupe()
            quoteSeqLevel = authorSeq.numberOfLevels + 1
        }
    }
    
    func genWork(quote: SortedNote, author: String, work: String) {
        print("      * generating work")
        guard work != lastWork else {
            print("        > Same work - skip")
            return
        }
        var workNote: Note? = biblioIO.getNote(knownAs: work)
        if workNote == nil {
            workNote = Note(collection: biblioCollection!)
            _ = workNote!.setTitle(work)
            print("        > Work seq before inc = \(workSeq.value)")
            print("        > Work seq level = \(workSeqLevel)")
            workSeq.incAtLevel(level: workSeqLevel, removingDeeperLevels: true)
            print("        > Work seq after  inc = \(workSeq.value)")
            _ = workNote!.setSeq(workSeq.value)
            quoteSeq = workSeq.dupe()
            _ = workNote!.setLevel(4)
            _ = workNote!.setKlass("work")
            _ = workNote!.setAuthor(author)
            if let quoteLinkField = FieldGrabber.getField(note: quote.note, label: "Work Link") {
                _ = workNote!.setLink(quoteLinkField.value.value)
            }
            if let workTypeField = FieldGrabber.getField(note: quote.note, label: "Work Type") {
                _ = workNote!.setField(label: "Work Type", value: workTypeField.value.value)
            }
            if let workDateField = FieldGrabber.getField(note: quote.note, label: "Work Date") {
                _ = workNote!.setDate(workDateField.value.value)
            }
            _ = biblioIO.addNote(newNote: workNote!)
        } else {
            print("        > work already exists with seq of \(workNote!.seq.value)")
            workSeq = workNote!.seq.dupe()
            workSeqLevel = workSeq.numberOfLevels - 1
            quoteSeq = workSeq.dupe()
            quoteSeqLevel = workSeqLevel + 1
        }
    }
    
    func genQuote(quote: SortedNote) {
        print("      * generating quote")
        let quoteNote = Note(collection: biblioCollection!)
        _ = quoteNote.setTitle(quote.note.title.value)
        print("        > Quote seq before inc = \(quoteSeq.value)")
        print("        > Quote seq level = \(quoteSeqLevel)")
        quoteSeq.incAtLevel(level: quoteSeqLevel, removingDeeperLevels: true)
        print("        > Quote seq after  inc = \(quoteSeq.value)")
        _ = quoteNote.setSeq(quoteSeq.value)
        _ = quoteNote.setLevel(5)
        _ = quoteNote.setKlass("quote")
        _ = quoteNote.setTags(quote.note.tags.value)
        _ = quoteNote.setBody(quote.note.body.value)
        let (addedNote, _) = biblioIO.addNote(newNote: quoteNote)
        if addedNote != nil {
            quotesAdded += 1
        } else {
            logError("Could not add biblio quote titled \(quoteNote.title.value)")
        }
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "QuotesToBiblio",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "QuotesToBiblio",
                          level: .error,
                          message: msg)
    }
    
}
