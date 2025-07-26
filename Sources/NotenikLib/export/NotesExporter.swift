//
//  NotesExporter.swift
//  Notenik
//
//  Created by Herb Bowie on 7/17/19.
//  Copyright © 2019-2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// An object capable of exporting a collection of notes to any one of several output formats.
public class NotesExporter {
    
    let appPrefs = AppPrefs.shared
    
    let pop = PopConverter.shared
    
    var tagsToSelect:   TagsValue!
    var tagsToSuppress: TagsValue!
    
    var noteIO: NotenikIO!
    var collection: NoteCollection!
    var dict = FieldDictionary()
    var format = ExportFormat.commaSeparated
    
    var split = false
    var singleSeqs = false
    var webExt = false
    var destination: URL!
    var fileExt = "txt"
    
    var mkdownContext: MkdownContext!
    
    var displayParms = DisplayParms()
    var display = NoteDisplay()
    
    var docTitle = ""
    
    var delimWriter: DelimitedWriter!
    var markup: Markedup!
    var jsonWriter: JSONWriter!
    var exportIO: NotenikIO!
    var exportCollection: NoteCollection!
    var exportDict: FieldDictionary!
    
    var exportErrors = 0
    
    var authorDef = false
    var workDef = false
    
    var notesExported = 0
    var tagsWritten = 0
    
    // -----------------------------------------------------------
    //
    // MARK: Driver
    //
    // -----------------------------------------------------------
    
    /// Initialize the Exporter.
    public init() {
        tagsToSelect = TagsValue(appPrefs.tagsToSelect)
        tagsToSuppress = TagsValue(appPrefs.tagsToSuppress)
    }
    
    /// Export the Notes to one of several possible output formats.
    public func export(noteIO: NotenikIO,
                       format: ExportFormat,
                       useTagsExportPrefs: Bool,
                       split: Bool,
                       addWebExtensions: Bool,
                       destination: URL,
                       ext: String) -> Int {
        
        self.noteIO = noteIO
        collection = noteIO.collection!
        mkdownContext = NotesMkdownContext(io: noteIO)
        self.format = format
        self.split = split
        self.singleSeqs = (collection.seqFieldDef != nil)
        self.webExt = addWebExtensions
        self.destination = destination
        self.fileExt = ext
        if format == .bookmarks {
            self.split = true
        } else if format == .notenik {
            self.split = false
            self.webExt = false
        }
        
        guard noteIO.collection != nil && noteIO.collectionOpen else { return -1 }
        
        displayParms.curlyApostrophes = collection.curlyApostrophes
        displayParms.extLinksOpenInNewWindows = collection.extLinksOpenInNewWindows
        
        exportErrors = 0
        
        dict = noteIO.collection!.dict
        
        authorDef = dict.contains(NotenikConstants.authorCommon)
        workDef = dict.contains(NotenikConstants.workTitleCommon)
        
        logNormal("Export requested to \(destination.absoluteString)")
        
        if useTagsExportPrefs {
            tagsToSelect = TagsValue(appPrefs.tagsToSelect)
            tagsToSuppress = TagsValue(appPrefs.tagsToSuppress)
            logNormal("Tags to select: \(tagsToSelect.description)")
            logNormal("Tags to suppress: \(tagsToSuppress.description)")
        } else {
            tagsToSelect = TagsValue()
            tagsToSuppress = TagsValue()
        }
        
        open()
        notesExported = 0
        
        if format == .bookmarks {
            iterateOverTags(io: noteIO)
        } else {
            iterateOverNotes(noteIO: noteIO)
        }
        
        // Now close the writer, which is when the write to disk happens
        let ok = close()
        if ok {
            logNormal("\(notesExported) notes exported")
            return notesExported
        } else {
            logError("Problems closing output export file")
            return -1
        }
    }
    
    // --------------------------------------------------------------
    //
    // Open Methods follow.
    //
    // --------------------------------------------------------------
    
    /// Open an output file for the export. 
    func open () {
        switch format {
        case .commaSeparated:
            delimWriter = DelimitedWriter(destination: destination, format: .commaSeparated)
            delimOpen()
        case .tabDelimited:
            delimWriter = DelimitedWriter(destination: destination, format: .tabDelimited)
            delimOpen()
        case .bookmarks:
            markup = Markedup(format: .netscapeBookmarks)
            markup.startDoc(withTitle: "Bookmarks", withCSS: nil)
        case .json:
            jsonOpen()
        case .notenik:
            notenikOpen()
        case .yaml:
            yamlOpen()
        case .opml:
            markup = Markedup(format: .opml)
            markup.startDoc(withTitle: noteIO.collection!.title, withCSS: nil)
        case .concatHtml, .outlineHtml, .concatMarkdown, .continuousMarkdown:
            concatOpen(exportFormat: format)
            break
        case .continuousHtml:
            break
        case .webBookEPUB, .webBookSite, .webBookEPUBFolder:
            break
        case .exportScript:
            break
        }
    }
    
    /// Open an output delimited text file.
    func delimOpen() {
        
        delimWriter.open()
        
        // Write out column headers
        if split {
            delimWriter.write(value: NotenikConstants.tag)
        }
        if singleSeqs {
            delimWriter.write(value: NotenikConstants.singleSeq)
        }
        for def in dict.list {
            delimWriter.write(value: def.fieldLabel.properForm)
        }
        
        // Now add optional derived fields
        if webExt {
            delimWriter.write(value: "Body as HTML")
            if authorDef {
                delimWriter.write(value: "Author Last Name First")
                delimWriter.write(value: "Author File Name")
                delimWriter.write(value: "Author Wikimedia Page")
            }
            
            if workDef {
                delimWriter.write(value: "Work HTML Line")
                delimWriter.write(value: "Work Rights HTML Line")
            }
        }
        
        // Finish up the heading line
        delimWriter.endLine()
    }
    
    func jsonOpen() {
        jsonWriter = JSONWriter()
        jsonWriter.lineByLine = true
        jsonWriter.writer = BigStringWriter()
        jsonWriter.open()
        jsonWriter.startObject()
    }
    
    func notenikOpen() {
        exportIO = FileIO()
        let realm = exportIO.getDefaultRealm()
        realm.path = ""
        
        let initOK = exportIO.initCollection(realm: realm,
                                             collectionPath: destination.path,
                                             readOnly: false)
        guard initOK else {
            logError("Could not open requested output folder at \(destination.path) as a new Notenik collection")
            exportErrors += 1
            return
        }
        let collection = noteIO.collection!
        
        exportCollection = exportIO.collection!
        exportDict = exportCollection.dict
        
        exportCollection.noteType = collection.noteType
        exportCollection.idFieldDef = collection.idFieldDef.copy()
        exportCollection.sortParm = collection.sortParm
        exportCollection.sortDescending = collection.sortDescending
        exportCollection.statusConfig = collection.statusConfig
        exportCollection.preferredExt = fileExt
        exportCollection.otherFields = collection.otherFields
        let caseMods = ["u", "u", "l"]
        for def in dict.list {
            let proper = def.fieldLabel.properForm
            let exportProper = StringUtils.wordDemarcation(proper, caseMods: caseMods, delimiter: " ")
            let exportLabel = FieldLabel(exportProper)
            let exportDef = FieldDefinition()
            exportDef.fieldLabel = exportLabel
            exportDef.typeCatalog = def.typeCatalog
            exportDef.fieldType = def.fieldType
            _ = exportDict.addDef(exportDef)
        }
        let ok = exportIO.newCollection(collection: exportCollection, withFirstNote: false)
        guard ok else {
            logError("Could not open requested output folder at \(destination.path) as a new Notenik collection")
            exportErrors += 1
            return
        }
        
        logNormal("New Collection successfully initialized at \(exportCollection.lib.getPath(type: .collection))")
        
    }
    
    func yamlOpen() {
        exportIO = FileIO()
        let realm = exportIO.getDefaultRealm()
        realm.path = ""
        
        let initOK = exportIO.initCollection(realm: realm,
                                             collectionPath: destination.path,
                                             readOnly: false)
        guard initOK else {
            logError("Could not open requested output folder at \(destination.path)")
            exportErrors += 1
            return
        }
        let collection = noteIO.collection!
        
        exportCollection = exportIO.collection!
        exportDict = exportCollection.dict
        
        exportCollection.noteType = collection.noteType
        exportCollection.idFieldDef = collection.idFieldDef.copy()
        exportCollection.sortParm = collection.sortParm
        exportCollection.sortDescending = collection.sortDescending
        exportCollection.statusConfig = collection.statusConfig
        exportCollection.preferredExt = fileExt
        exportCollection.otherFields = collection.otherFields
        exportCollection.noteFileFormat = .yaml
        
        for def in dict.list {
            let proper = def.fieldLabel.properForm
            let exportLabel = FieldLabel(proper)
            let exportDef = FieldDefinition()
            exportDef.fieldLabel = exportLabel
            exportDef.typeCatalog = def.typeCatalog
            exportDef.fieldType = def.fieldType
            _ = exportDict.addDef(exportDef)
        }
        let ok = exportIO.newCollection(collection: exportCollection, withFirstNote: false)
        guard ok else {
            logError("Could not open requested output folder at \(destination.path)")
            exportErrors += 1
            return
        }
        
        logNormal("YAML Collection successfully initialized at \(exportCollection.lib.getPath(type: .collection))")
        
    }
    
    // --------------------------------------------------------------
    //
    // Write Methods follow.
    //
    // --------------------------------------------------------------
    
    func iterateOverNotes(noteIO: NotenikIO) {
        // Now export each Note
        var (nextNote, position) = noteIO.firstNote()
        while nextNote != nil {
            let note = nextNote!.note
            // Let's see if the next Note meets Tags Selection Criteria
            var noteSelected = true
            if tagsToSelect.tags.count > 0 {
                noteSelected = false
                for noteTag in note.tags.tags {
                    for selTag in tagsToSelect.tags {
                        if noteTag == selTag {
                            noteSelected = true
                        }
                    }
                }
            }
            
            if noteSelected {
                exportSelectedNote(nextNote!)
            }
            
            (nextNote, position) = noteIO.nextNote(position)
        }
    }
    
    /// Export a Note that has met the selection criteria. 
    func exportSelectedNote(_ sortedNote: SortedNote) {
        
        // Check each tag on the selected note
        let note = sortedNote.note
        let cleanTags = TagsValue()
        for tag in note.tags.tags {
            var tagSelected = true
            for supTag in tagsToSuppress.tags {
                if tag == supTag {
                    tagSelected = false
                }
            }
            if tagSelected {
                cleanTags.tags.append(tag)
            }
        }
        cleanTags.sort()
        
        tagsWritten = 0
        if split {
            for tag in cleanTags.tags {
                writeNote(splitTag: tag.description, cleanTags: cleanTags.description, sortedNote: sortedNote)
            }
        }
        if tagsWritten == 0 {
            writeNote(splitTag: "", cleanTags: cleanTags.description, sortedNote: sortedNote)
        }
        
    }
    
    /// Write output containing data from a single Note.
    ///
    /// - Parameters:
    ///   - splitTag: If we're splitting by tag, then the tag to write for this line; otherwise blank.
    ///   - cleanTags: The cleaned tags for this note, with any suppressed tags removed.
    ///   - note: The Note to be written.
    func writeNote(splitTag: String, cleanTags: String, sortedNote: SortedNote) {
        let note = sortedNote.note
        switch format {
        case .commaSeparated, .tabDelimited:
            writeLine(splitTag: splitTag, cleanTags: cleanTags, sortedNote: sortedNote)
        case .json:
            writeObject(splitTag: splitTag, cleanTags: cleanTags, sortedNote: sortedNote)
        case .notenik:
            writeNotenik(splitTag: splitTag, cleanTags: cleanTags, note: note)
        case .yaml:
            writeYAML(splitTag: splitTag, cleanTags: cleanTags, note: note)
        case .opml:
            writeOutline(splitTag: splitTag, cleanTags: cleanTags, note: note)
        case .concatHtml, .concatMarkdown, .continuousMarkdown:
            writeConcat(splitTag: splitTag, cleanTags: cleanTags, sortedNote: sortedNote)
        case .outlineHtml:
            writeOutlineHtml(note: note)
        default:
            writeLine(splitTag: splitTag, cleanTags: cleanTags, sortedNote: sortedNote)
        }
    }

    
    /// Write a single output line containing data from a single Note.
    ///
    /// - Parameters:
    ///   - splitTag: If we're splitting by tag, then the tag to write for this line; otherwise blank.
    ///   - cleanTags: The cleaned tags for this note, with any suppressed tags removed.
    ///   - note: The Note to be written.
    func writeLine(splitTag: String, cleanTags: String, sortedNote: SortedNote) {
        if split {
            writeField(value: splitTag)
        }
        if singleSeqs {
            writeField(value: sortedNote.seqSingleValue.value)
        }
        for def in dict.list {
            if def.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                writeField(value: cleanTags)
            } else {
                writeField(value: sortedNote.note.getFieldAsString(label: def.fieldLabel.commonForm))
            }
        }
        
        if webExt {
            // Now add derived fields
            let code = Markedup(format: .htmlFragment)
            let mkdownOptions = MkdownOptions()
            Markdown.markdownToMarkedup(markdown: sortedNote.note.getFieldAsString(label: NotenikConstants.bodyCommon),
                                            options: mkdownOptions, mkdownContext: mkdownContext, writer: code)
            writeField(value: String(describing: code))
            
            if authorDef {
                let author = sortedNote.note.author
                writeField(value: author.lastNameFirst)
                writeField(value: StringUtils.toCommonFileName(author.firstNameFirst))
                writeField(value: StringUtils.wikiMediaPage(author.firstNameFirst))
            }
            
            if workDef {
                writeField(value: workToHTML(note: sortedNote.note))
                writeField(value: workRightsToHTML(note: sortedNote.note))
            }
        }
        
        // Finish up the line
        endLine()
        tagsWritten += 1
        notesExported += 1
    }
    
    /// Write a single field value to the output line.
    func writeField(value: String) {
        switch format {
        case .tabDelimited:
            delimWriter.write(value: value)
        case .commaSeparated:
            delimWriter.write(value: value)
        default:
            break
        }
    }
    
    /// End an output line containing the data from one Note.
    func endLine() {
        switch format {
        case .tabDelimited, .commaSeparated:
            delimWriter.endLine()
        default:
            break
        }
    }
    
    /// Write a JSON object for a single note.
    ///
    /// - Parameters:
    ///   - splitTag: If we're splitting by tag, then the tag to write for this line; otherwise blank.
    ///   - cleanTags: The cleaned tags for this note, with any suppressed tags removed.
    ///   - note: The Note to be written.
    func writeObject(splitTag: String, cleanTags: String, sortedNote: SortedNote) {
        let note = sortedNote.note
        jsonWriter.writeKey(note.noteID.commonID)
        jsonWriter.startObject()
        if split {
            jsonWriter.write(key: NotenikConstants.tag, value: splitTag)
        }
        if singleSeqs {
            jsonWriter.write(key: NotenikConstants.singleSeq, value: sortedNote.seqSingleValue.value)
        }
        for def in dict.list {
            if def.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                jsonWriter.write(key: def.fieldLabel.properForm, value: cleanTags)
            } else {
                jsonWriter.write(key: def.fieldLabel.properForm, value: note.getFieldAsString(label: def.fieldLabel.commonForm))
            }
        }
        
        if webExt {
            
            // Now add derived fields
            let code = Markedup(format: .htmlFragment)
            let mkdownOptions = MkdownOptions()
            Markdown.markdownToMarkedup(markdown: note.getFieldAsString(label: NotenikConstants.bodyCommon),
                                            options: mkdownOptions, mkdownContext: mkdownContext, writer: code)
            jsonWriter.write(key: "Body as HTML", value: String(describing: code))
            
            if authorDef {
                let author = note.author
                jsonWriter.write(key: "Author Last Name First", value: author.lastNameFirst)
                jsonWriter.write(key: "Author File Name", value: StringUtils.toCommonFileName(author.firstNameFirst))
                jsonWriter.write(key: "Author Wikimedia Page", value: StringUtils.wikiMediaPage(author.firstNameFirst))
            }
            
            if workDef {
                jsonWriter.write(key: "Work HTML Line", value: workToHTML(note: note))
                jsonWriter.write(key: "Work Rights HTML Line", value: workRightsToHTML(note: note))
            }
        }
        
        // Finish up the object
        jsonWriter.endObject()
        tagsWritten += 1
        notesExported += 1
    }
    
    var outlineLevels: [Int] = []
    var lastLevel: Int {
        if outlineLevels.count > 0 {
            return outlineLevels[outlineLevels.count - 1]
        } else {
            return 0
        }
    }
    
    /// Write an OPML outline object for a single note.
    ///
    /// - Parameters:
    ///   - splitTag: If we're splitting by tag, then the tag to write for this line; otherwise blank.
    ///   - cleanTags: The cleaned tags for this note, with any suppressed tags removed.
    ///   - note: The Note to be written.
    func writeOutline(splitTag: String, cleanTags: String, note: Note) {
        
        // Close any open Outline elements that are at a lower or equal level.
        let level = note.level.getInt()
        while lastLevel >= level && outlineLevels.count > 0 {
            markup.finishOutline()
            outlineLevels.removeLast()
        }
        
        // Now let's create an Outline element for this Note.
        markup.startOutlineOpen(note.title.value)
        for def in dict.list {
            if def.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                addOutlineAttribute(label: def.fieldLabel.properForm, value: cleanTags)
            } else if def.fieldLabel.commonForm == NotenikConstants.titleCommon {
                // We've already handled the title
            } else if def.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                // We'll handle the body below
            } else {
                addOutlineAttribute(label: def.fieldLabel.properForm,
                                    value: note.getFieldAsString(label: def.fieldLabel.commonForm))
            }
        }
        
        if webExt {
            
            // Now add derived fields
            let code = Markedup(format: .htmlFragment)
            let mkdownOptions = MkdownOptions()
            Markdown.markdownToMarkedup(markdown: note.getFieldAsString(label: NotenikConstants.bodyCommon),
                                            options: mkdownOptions, mkdownContext: mkdownContext, writer: code)
            addOutlineAttribute(label: "Body as HTML", value: String(describing: code))
            
            if authorDef {
                let author = note.author
                addOutlineAttribute(label: "Author Last Name First", value: author.lastNameFirst)
                addOutlineAttribute(label: "Author File Name", value: StringUtils.toCommonFileName(author.firstNameFirst))
                addOutlineAttribute(label: "Author Wikimedia Page", value: StringUtils.wikiMediaPage(author.firstNameFirst))
            }
            
            if workDef {
                addOutlineAttribute(label: "Work HTML Line", value: workToHTML(note: note))
                addOutlineAttribute(label: "Work Rights HTML Line", value: workRightsToHTML(note: note))
            }
        }
        
        // Finish up the object
        addOutlineAttribute(label: "_note", value: note.body.value)
        markup.startOutlineClose(finishToo: false)
        tagsWritten += 1
        notesExported += 1
        outlineLevels.append(level)
    }
    
    func addOutlineAttribute(label: String, value: String) {
        var labelOut = label
        if label != "_note" {
            labelOut = StringUtils.wordDemarcation(label,
                                                   caseMods: ["l", "u", "l"],
                                                   delimiter: "")
        }
        let trimmed = StringUtils.trim(value)
        guard trimmed.count > 0 else { return }
        markup.addOutlineAttribute(label: labelOut, value: trimmed)
    }
    
    func workToHTML(note: Note) -> String {
        let html = Markedup(format: .htmlFragment)
        let workType = note.getFieldAsString(label: NotenikConstants.workTypeCommon)
        html.spanConditional(value: workType, klass: "sourcetype", prefix: "the ", suffix: " ")
        let workTitle = note.getFieldAsString(label: NotenikConstants.workTitleCommon)
        html.spanConditional(value: workTitle, klass: "majortitle", prefix: "", suffix: "", tag: "cite")
        let pubCity = note.getFieldAsString(label: NotenikConstants.pubCityCommon)
        html.spanConditional(value: pubCity, klass: "city", prefix: ", ", suffix: ":")
        let publisher = note.getFieldAsString(label: NotenikConstants.publisherCommon)
        html.spanConditional(value: publisher, klass: "publisher", prefix: " ", suffix: "")
        let date = String(describing: note.date)
        html.spanConditional(value: date, klass: "datepublished", prefix: ", ", suffix: "")
        let pages = note.getFieldAsString(label: NotenikConstants.workPagesCommon)
        html.spanConditional(value: pages, klass: "pages", prefix: ", pages&nbsp;", suffix: "")
        let workID = note.getFieldAsString(label: NotenikConstants.workIDcommon)
        html.spanConditional(value: workID, klass: "isbn", prefix: ", ISBN&nbsp;", suffix: "")
        return String(describing: html)
    }
    
    func workRightsToHTML(note: Note) -> String {
        let html = Markedup(format: .htmlFragment)
        let rights = note.getFieldAsString(label: NotenikConstants.workRightsCommon)
        var symbol = ""
        if rights.lowercased() == "copyright" {
            symbol = " &copy;"
        }
        html.spanConditional(value: rights, klass: "rights", prefix: "", suffix: symbol)
        let date = String(describing: note.date)
        html.spanConditional(value: date, klass: "datepublished", prefix: " ", suffix: "")
        let owner = note.getFieldAsString(label: NotenikConstants.workRightsHolderCommon)
        html.spanConditional(value: owner, klass: "rightsowner", prefix: " by ", suffix: "")
        return String(describing: html)
    }
    
    /// Write a Notenik Note  for a single note.
    ///
    /// - Parameters:
    ///   - splitTag: If we're splitting by tag, then the tag to write for this line; otherwise blank.
    ///   - cleanTags: The cleaned tags for this note, with any suppressed tags removed.
    ///   - note: The Note to be written.
    func writeNotenik(splitTag: String, cleanTags: String, note: Note) {
        
        let exportNote = Note(collection: exportCollection)
        
        for def in dict.list {
            let exportDef = exportDict.getDef(def.fieldLabel.commonForm)
            if exportDef != nil {
                let field = note.getField(def: def)
                if field != nil && field!.value.count > 0 {
                    let exportField = NoteField()
                    exportField.def = exportDef!
                    if def.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                        _ = exportNote.setTags(cleanTags)
                    } else {
                        exportField.value = field!.value
                        _ = exportNote.addField(exportField)
                    }
                }
            }
        }
        
        exportNote.identify()
        exportNote.noteID.changeFileExt(to: fileExt)
        exportNote.noteID.setNoteFileFormat(newFormat: .notenik)
        let (added, position) = exportIO.addNote(newNote: exportNote)
        if added == nil || position.index < 0 {
            exportErrors += 1
            logError("Note titled \(exportNote.title.value) could not be saved to the exported collection")
        } else {
            tagsWritten += 1
            notesExported += 1
        }
    }
    
    /// Write a YAML Note  for a single note.
    ///
    /// - Parameters:
    ///   - splitTag: If we're splitting by tag, then the tag to write for this line; otherwise blank.
    ///   - cleanTags: The cleaned tags for this note, with any suppressed tags removed.
    ///   - note: The Note to be written.
    func writeYAML(splitTag: String, cleanTags: String, note: Note) {
        
        let exportNote = Note(collection: exportCollection)
        
        for def in dict.list {
            let exportDef = exportDict.getDef(def.fieldLabel.commonForm)
            if exportDef != nil {
                let field = note.getField(def: def)
                if field != nil && field!.value.count > 0 {
                    let exportField = NoteField()
                    exportField.def = exportDef!
                    if def.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                        _ = exportNote.setTags(cleanTags)
                    } else {
                        exportField.value = field!.value
                        _ = exportNote.addField(exportField)
                    }
                }
            }
        }
        
        exportNote.identify()
        exportNote.noteID.changeFileExt(to: fileExt)
        exportNote.noteID.setNoteFileFormat(newFormat: .yaml)
        let (added, position) = exportIO.addNote(newNote: exportNote)
        if added == nil || position.index < 0 {
            exportErrors += 1
            logError("Note titled \(exportNote.title.value) could not be saved to the exported YAML folder")
        } else {
            tagsWritten += 1
            notesExported += 1
        }
    }
    
    // --------------------------------------------------------------
    //
    // Close Methods follow.
    //
    // --------------------------------------------------------------
    
    /// Close the output file, and return result.
    func close() -> Bool {
        switch format {
        case .tabDelimited:
            return delimClose()
        case .commaSeparated:
            return delimClose()
        case .bookmarks:
            return markupClose()
        case .json:
            return jsonClose()
        case .notenik:
            return notenikClose()
        case .yaml:
            return yamlClose()
        case .opml:
            return outlineClose()
        case .concatHtml, .outlineHtml, .concatMarkdown, .continuousMarkdown:
            return concatClose(exportFormat: format)
        case .continuousHtml:
            return true
        case .webBookEPUB, .webBookSite, .webBookEPUBFolder:
            return false
        case .exportScript:
            return false
        }
    }
    
    /// Close the Delimited Writer
    func delimClose() -> Bool {
        return delimWriter.close()
    }
    
    /// Close the JSON generator.
    func jsonClose() -> Bool {
        jsonWriter.endObject()
        jsonWriter.close()
        return jsonWriter.save(destination: destination)
    }
    
    /// Generate output organized by tag.
    func iterateOverTags(io: NotenikIO) {
        var depth = 0
        let iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        while tagsNode != nil {
            while depth > iterator.depth {
                markup.decreaseIndent()
                markup.writeLine("</DL><p>")
                depth -= 1
            }
            if tagsNode!.type == .tag {
                markup.writeLine("<DT><H3 FOLDED>\(tagsNode!.tag!)</H3>")
                markup.writeLine("<DL><p>")
                markup.increaseIndent()
            } else if tagsNode!.type == .note {
                guard let note = tagsNode!.note else { break }
                markup.writeLine("<DT><A HREF=\"\(note.link.value)\">\(note.title.value)</A>")
                notesExported += 1
            }
            depth = iterator.depth
            tagsNode = iterator.next()
        }
        while depth > iterator.depth {
            markup.decreaseIndent()
            markup.writeLine("</DL><p>")
            depth -= 1
        }
    }
    
    // Close the markup writer.
    func markupClose() -> Bool {
        markup.finishDoc()
        do {
            try markup.code.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "NotesExporter",
                              level: .error,
                              message: "Problem writing export file to disk!")
            return false
        }
        return true
    }
    
    // Close the markup writer.
    func outlineClose() -> Bool {
        while outlineLevels.count > 0 {
            markup.finishOutline()
            outlineLevels.removeLast()
        }
        markup.finishDoc()
        do {
            try markup.code.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "NotesExporter",
                              level: .error,
                              message: "Problem writing export file to disk!")
            return false
        }
        return true
    }
    
    func notenikClose() -> Bool {
        exportIO.closeCollection()
        return exportErrors == 0
    }
    
    func yamlClose() -> Bool {
        exportIO.closeCollection()
        return exportErrors == 0
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Concatenate functions.
    //
    // -----------------------------------------------------------
    
    func concatOpen(exportFormat: ExportFormat) {
        var markupFormat: MarkedupFormat = .markdown
        if exportFormat == .concatHtml || exportFormat == .outlineHtml {
            markupFormat = .htmlDoc
        }
        
        docTitle = ""
        
        displayParms = DisplayParms()
        displayParms.setCSS(useFirst: collection.displayCSS, useSecond: DisplayPrefs.shared.displayCSS)
        switch exportFormat {
        case .concatHtml, .outlineHtml:
            displayParms.format = .htmlFragment
        case .concatMarkdown, .continuousMarkdown:
            displayParms.format = .markdown
        default:
            break
        }
        displayParms.sortParm = collection.sortParm
        displayParms.displayMode = collection.displayMode
        displayParms.wikiLinks.prefix = "#"
        displayParms.wikiLinks.format = .mmdID
        displayParms.wikiLinks.suffix = ""
        displayParms.mathJax = collection.mathJax
        displayParms.localMj = false
        displayParms.curlyApostrophes = collection.curlyApostrophes
        displayParms.extLinksOpenInNewWindows = collection.extLinksOpenInNewWindows
        displayParms.concatenated = true
        
        markup = Markedup(format: markupFormat)
        print("concatOpen markup formatted with \(markupFormat)")
    }
    
    func writeConcat(splitTag: String, cleanTags: String, sortedNote: SortedNote) {
        
        if docTitle.count == 0 {
            if sortedNote.note.seq.isEmpty && sortedNote.note.level.getInt() == 1 {
                docTitle = sortedNote.note.title.value
            } else {
                docTitle = collection.title
            }
            markup.startDoc(withTitle: docTitle,
                            withCSS: sortedNote.note.getCombinedCSS(cssString: displayParms.cssString))
        }
        
        var expMD: String?
        
        switch format {
        case .concatHtml:
            displayParms.format = .htmlFragment
        case .concatMarkdown, .continuousMarkdown:
            displayParms.format = .markdown
            let expander = MkdownExpander()
            expMD = expander.expand(md: sortedNote.note.body.value,
                                    note: sortedNote.note,
                                    io: noteIO,
                                    parms: displayParms)
        default:
            break
        }
        
        
        let mdResults = TransformMdResults()
        if format == .continuousMarkdown {
            // print("  - writeConcat")
            let titleToDisplay = pop.toXML(displayParms.compoundTitle(note: sortedNote.note))
            print("    - title to display = \(titleToDisplay)")
            markup.displayLine(opt: sortedNote.note.collection.titleDisplayOption,
                                 text: titleToDisplay,
                                 depth: sortedNote.depth,
                                 addID: false,
                               idText: sortedNote.note.title.value)
            print("    - Expanded Markdown: \(expMD!)")
            markup.append(expMD!)
        } else {
            let code = display.display(sortedNote, io: noteIO, parms: displayParms, mdResults: mdResults, expandedMarkdown: expMD)
            markup.append(code)
        }
        
        // markup.writeLine(" ")
        notesExported += 1
    }
    
    var mkdownOptions = MkdownOptions()
    var mdBodyParser: MkdownParser?
    var openParm: String? = "true"
    
    func writeOutlineHtml(note: Note) {
        
        if docTitle.isEmpty {
            if note.seq.isEmpty && note.level.getInt() == 1 {
                docTitle = note.title.value
            } else {
                docTitle = collection.title
            }
            markup.startDoc(withTitle: docTitle,
                            withCSS: note.getCombinedCSS(cssString: displayParms.cssString))
            openParm = "true"
        } else {
            openParm = nil
        }

        displayParms.format = .htmlFragment
        
        // Close any open Details elements that are at a lower or equal level.
        let level = note.level.getInt()
        while lastLevel >= level && outlineLevels.count > 0 {
            markup.finishDetails()
            outlineLevels.removeLast()
        }
        
        // Now let's open a Details element and write a summary for this Note.
        markup.startDetails(openParm: openParm)
        markup.startSummary()
        if note.hasSeq() {
            markup.append("\(note.getFormattedSeq()) ")
        }
        markup.append(note.title.value)
        
        if note.hasTags() {
            markup.append(" ")
            markup.startEmphasis()
            markup.append("(")
            markup.append(note.tags.value)
            markup.append(")")
            markup.finishEmphasis()
        }
        
        markup.finishSummary()
        
        displayParms.setMkdownOptions(mkdownOptions)
        mkdownContext = NotesMkdownContext(io: noteIO, displayParms: displayParms)
        if note.hasShortID() {
            mkdownOptions.shortID = note.shortID.value
        } else {
            mkdownOptions.shortID = ""
        }

        mkdownContext.identifyNoteToParse(id: note.noteID.commonID,
                                      text: note.noteID.text,
                                      fileName: note.noteID.commonFileName,
                                      shortID: note.shortID.value)
        let collection = note.collection
        collection.skipContentsForParent = false
        mdBodyParser = nil
        
        for def in dict.list {
            switch def.fieldType.typeString {
            case NotenikConstants.titleCommon:
                break
            case NotenikConstants.seqCommon:
                break
            case NotenikConstants.tagsCommon:
                break
            case NotenikConstants.levelCommon:
                break
            case NotenikConstants.bodyCommon:
                break
            default:
                let field = note.getField(def: def)
                if field != nil && field!.value.hasData {
                    markup.startParagraph()
                    markup.append("\(def.fieldLabel.properForm): ")
                    markup.append(field!.value.value)
                    markup.finishParagraph()
                }
            }
        }
        
        // Format the body field.
        if note.hasBody() {
            mdBodyParser = MkdownParser(note.body.value, options: mkdownOptions)
            mdBodyParser!.setWikiLinkFormatting(prefix: displayParms.wikiLinks.prefix,
                                                format: displayParms.wikiLinks.format,
                                                suffix: displayParms.wikiLinks.suffix,
                                                context: mkdownContext)
            mdBodyParser!.parse()
            markup.append(mdBodyParser!.html)
        }
        
        notesExported += 1
        outlineLevels.append(level)
    }
    
    // Close the markup writer.
    func concatClose(exportFormat: ExportFormat) -> Bool {
        
        if exportFormat == .outlineHtml {
            while outlineLevels.count > 0 {
                markup.finishDetails()
                outlineLevels.removeLast()
            }
        }
        markup.finishDoc()
        do {
            print("concatClose writing markup code to \(destination!)")
            try markup.code.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "NotesExporter",
                              level: .error,
                              message: "Problem writing export file to disk!")
            return false
        }
        return true
    }
    
    /// Log a normal message
    func logNormal(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NotesExporter", level: .info, message: msg)
    }
    
    /// Log a normal message
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NotesExporter", level: .error, message: msg)
    }
}
