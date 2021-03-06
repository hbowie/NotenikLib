//
//  FileIO.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// Retrieve and save Notes from and to files stored locally.
public class FileIO: NotenikIO, RowConsumer {
    
    // -----------------------------------------------------------
    //
    // MARK: Variables required by NotenikIO
    //
    // -----------------------------------------------------------
    
    /// The currently open collection, if any
    public var collection   : NoteCollection?
    
    /// The position of the selected note, if any, in the current collection
    public var position:   NotePosition? {
        if !collectionOpen || collection == nil || bunch == nil {
            return nil
        } else {
            notePosition.index = bunch!.listIndex
            return notePosition
        }
    }
    
    /// An indicator of the status of the Collection: open or closed
    public var collectionOpen = false
    
    /// A list of reports available for the currently open Collection.
    public var reports: [MergeReport] = []
    
    /// A list of notes in the Collection.
    public var notesList: NotesList {
        if bunch != nil {
            return bunch!.notesList
        } else {
            return NotesList()
        }
    }
    
    /// The number of notes in the current collection
    public var notesCount: Int {
        guard bunch != nil else { return 0 }
        return bunch!.count
    }
    
    /// Pick lists maintained for the Collection.
    public var pickLists = ValuePickLists()
    
    /// Get or Set the NoteSortParm for the current collection.
    public var sortParm: NoteSortParm {
        get { return collection!.sortParm }
        set {
            if newValue != collection!.sortParm {
                collection!.sortParm = newValue
                bunch!.sortParm = newValue
            }
        }
    }
    
    /// Should the list be in descending sequence?
    public var sortDescending: Bool {
        get { return collection!.sortDescending }
        set {
            if newValue != collection!.sortDescending {
                collection!.sortDescending = newValue
                bunch!.sortDescending = newValue
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Constants and other Variables
    //
    // -----------------------------------------------------------
    
    let mergeTemplateID          = "template"
    
    var inspectors: [NoteOpenInspector] = []
    
    var attachments: [ResourceFileSys]?
    
    var provider            : Provider = Provider()
    var realm               : Realm
    
    var lastIndexSelected = -1
    
    var bunch          : BunchOfNotes?
    var aliasList      = AliasList()
    var templateFound  = false
    var infoFound      = false
    var notePosition   = NotePosition(index: -1)
    
    // -----------------------------------------------------------
    //
    // MARK: Initializers
    //
    // -----------------------------------------------------------
    
    /// Initialize without any real data, so meaningful initialization is deferred until later.
    public init() {
        provider.providerType = .file
        realm = Realm(provider: provider)
        collection = NoteCollection(realm: realm)
        pickLists.statusConfig = collection!.statusConfig
        realm.name = NSUserName()
        realm.path = NSHomeDirectory()
        closeCollection()
    }
    
    /// Provide an inspector that will be passed each Note as a Collection is opened.
    public func setInspector(_ inspector: NoteOpenInspector) {
        inspectors.append(inspector)
    }
    
    /// Attempt to initialize the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: True if successful, false otherwise.
    public func initCollection(realm: Realm, collectionPath: String, readOnly: Bool) -> Bool {
        closeCollection()
        logInfo("Initializing Collection")
        self.realm = realm
        self.provider = realm.provider
        if realm.path.count > 0 {
            logInfo("Realm:      " + realm.path)
        }
        logInfo("Collection: " + collectionPath)
        
        collection = NoteCollection(realm: realm)
        collection!.path = collectionPath
        collection!.readOnly = readOnly
        
        guard collection!.lib.hasAvailable(type: .collection) else { return false }
        guard let url = collection!.lib.getURL(type: .collection) else { return false }
        if collection!.lib.itemsFound == 0 {
            collection!.setTitleFromURL(url)
            return true
        } else if collection!.lib.hasAvailable(type: .info) {
            collection!.setTitleFromURL(url)
            return true
        } else if collection!.lib.notesFound > 0 {
            collection!.setTitleFromURL(url)
            return true
        } else {
            logError("This path does not point to a Notenik Collection")
            return false
        }
    }
    
    /// Add the default definitions to the Collection's dictionary:
    /// Title, Tags, Link and Body
    public func addDefaultDefinitions() {
        guard collection != nil else { return }
        let dict = collection!.dict
        let types = collection!.typeCatalog
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.title)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.tags)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.link)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.body)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Accessors providing info to other classes
    //
    // -----------------------------------------------------------
    
    /// Get information about the provider.
    public func getProvider() -> Provider {
        return provider
    }
    
    /// Get the default realm.
    public func getDefaultRealm() -> Realm {
        return realm
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Create and Save Routines
    //
    // -----------------------------------------------------------
    
    /// Open a New Collection.
    ///
    /// The passed collection should already have been initialized
    /// via a call to initCollection above.
    public func newCollection(collection: NoteCollection, withFirstNote: Bool = true) -> Bool {
        
        self.collection = collection
        
        var ok = false
        
        guard let lib = collection.lib else { return false }
        guard lib.hasAvailable(type: .collection) else {
            logError("Collection folder does not exist")
            return false
        }
        
        let notesFolder = lib.getResource(type: .notes)
        guard notesFolder.ensureExistence() else { return false }
        
        ok = saveReadMe()
        guard ok else { return ok }
        
        ok = saveInfoFile()
        guard ok else { return ok }
        
        ok = saveTemplateFile()
        guard ok else { return ok }
        
        bunch = BunchOfNotes(collection: collection)
        
        if withFirstNote {
            ok = writeFirstNote()
        } else {
            collectionOpen = true
        }
        
        guard ok else { return ok }
        
        bunch!.sortParm = collection.sortParm
        bunch!.sortDescending = collection.sortDescending
        
        return ok
    }
    
    /// Save some of the collection info to make it persistent
    public func persistCollectionInfo() {
        guard collection != nil else { return }
        guard !collection!.readOnly else { return }
        _ = saveInfoFile()
        _ = saveTemplateFile()
        _ = aliasList.saveToDisk()
    }
    
    func saveReadMe() -> Bool {
        guard let lib = collection?.lib else { return false }
        guard lib.hasAvailable(type: .notes) else { return false }
        guard !collection!.readOnly else { return false }
        return lib.saveReadMe()
    }
    
    /// Save the INFO file into the current collection
    func saveInfoFile() -> Bool {
        guard let lib = collection?.lib else { return false }
        guard lib.hasAvailable(type: .notes) else { return false }
        guard !collection!.readOnly else { return false }
        
        let str = NoteString(title: collection!.title)
        str.appendLink(lib.getPath(type: .collection))
        str.append(label: "Sort Parm", value: collection!.sortParm.str)
        str.append(label: "Sort Descending", value: "\(collection!.sortDescending)")
        str.append(label: "Other Fields Allowed", value: String(collection!.otherFields))
        if bunch != nil {
            str.append(label: NotenikConstants.lastIndexSelected, value: "\(bunch!.listIndex)")
        }
        str.append(label: NotenikConstants.mirrorAutoIndex,   value: "\(collection!.mirrorAutoIndex)")
        str.append(label: NotenikConstants.bodyLabelDisplay,  value: "\(collection!.bodyLabel)")
        str.append(label: NotenikConstants.h1TitlesDisplay,   value: "\(collection!.h1Titles)")
        if collection!.lastStartupDate.count > 0 {
            str.append(label: NotenikConstants.lastStartupDate, value: collection!.lastStartupDate)
        }

        return lib.saveInfo(str: str.str)
    }
    
    /// Save the template file into the current collection
    func saveTemplateFile() -> Bool {
        guard let lib = collection?.lib else { return false }
        guard lib.hasAvailable(type: .notes) else { return false }
        guard !collection!.readOnly else { return false }
        
        let dict = collection!.dict
        var str = ""
        for def in dict.list {
            var value = ""
            if def.fieldLabel.commonForm == NotenikConstants.timestampCommon {
                collection!.hasTimestamp = true
            } else if def.fieldLabel.commonForm == NotenikConstants.statusCommon {
                value = collection!.statusConfig.statusOptionsAsString
            } else if def.pickList != nil && def.fieldType.typeString != NotenikConstants.authorCommon {
                value = def.pickList!.valueString
            } else if def.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                value = ""
            } else if def.fieldType is LongTextType {
                value = "<longtext>"
            } else if def.fieldType.typeString != NotenikConstants.stringType {
                value = "<\(def.fieldType.typeString)>"
            }
            str.append("\(def.fieldLabel.properForm): \(value) \n\n")
        }
        
        return lib.saveTemplate(str: str, ext: collection!.preferredExt)
    }
    
    /// It's always good to have at least one Note in a Collection. 
    func writeFirstNote() -> Bool {
        
        guard collection != nil else { return false }
        guard bunch != nil else { return false }
        
        let firstNote = Note(collection: collection!)
        _ = firstNote.setTitle("Notenik")
        _ = firstNote.setLink("https://notenik.net")
        _ = firstNote.setTags("Software.Groovy")
        _ = firstNote.setBody("A note-taking system cunningly devised by Herb Bowie")
        
        let added = bunch!.add(note: firstNote)
        guard added else {
            logError("Couldn't add first note to internal storage")
            return false
        }
        
        firstNote.fileInfo.genFileName()
        collectionOpen = true
        let ok = writeNote(firstNote)
        guard ok else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Couldn't write first note to disk!")
            collectionOpen = false
            return ok
        }
        return true
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Open and Close routines
    //
    // -----------------------------------------------------------
    
    /// Attempt to open the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: A NoteCollection object, if the collection was opened successfully;
    ///            otherwise nil.
    public func openCollection(realm: Realm, collectionPath: String, readOnly: Bool) -> NoteCollection? {
        
        let initOK = initCollection(realm: realm, collectionPath: collectionPath, readOnly: readOnly)
        guard initOK else { return nil }
        guard let resourceLib = collection!.lib else { return nil }
        
        resourceLib.prepareForUse()
        
        aliasList = AliasList(io: self)
        
        // Let's read the directory contents
        bunch = BunchOfNotes(collection: collection!)
        
        loadAttachments()
        
        var notesRead = 0
        
        _ = loadInfoFile()
        _ = loadTemplateFile()
        if resourceLib.reportsFolder.isAvailable {
            loadReports()
        }
        
        let notesContents = collection!.lib.notesFolder.getResourceContents(preferredNoteExt: collection!.preferredExt)
        guard notesContents != nil else { return nil }
        for item in notesContents! {
            if item.type == .note {
                let note = item.readNote(collection: collection!, reportErrors: true)
                if note != nil && note!.hasTitle() {
                    addAttachments(to: note!)
                    pickLists.registerNote(note: note!)
                    let noteAdded = bunch!.add(note: note!)
                    if noteAdded {
                        notesRead += 1
                        for inspector in inspectors {
                            inspector.inspect(note!)
                        }
                    } else {
                        logError("Note titled '\(note!.title.value)' appears to be a duplicate and could not be accessed")
                    }
                } else {
                    logError("No title for Note read from \(item)")
                }
            }
        }
        
        if (notesRead == 0 && !infoFound && !templateFound) {
            logError("This folder does not seem to contain a valid Collection")
            return nil
        } else {
            logInfo("\(notesRead) Notes loaded for the Collection")
            collectionOpen = true
            bunch!.sortParm = collection!.sortParm
            bunch!.sortDescending = collection!.sortDescending
            if pickLists.tagsPickList.values.count > 0 {
                AppPrefs.shared.pickLists = pickLists
            }
            if !infoFound {
                _ = saveInfoFile()
            }
            let transformer = NoteTransformer(io: self)
            collection!.mirror = transformer
            if collection!.mirror != nil {
                logInfo("Mirroring Engaged")
            }
            aliasList.loadFromDisk()
            if lastIndexSelected > 0 {
                _ = selectNote(at: lastIndexSelected)
            } else {
                _ = firstNote()
            }
            return collection
        }
    }
    
    /// Attempt to load the info file.
    func loadInfoFile() -> Note? {
        
        guard let infoNote = collection!.lib.getNote(type: .info) else { return nil }

        collection!.title = infoNote.title.value
        
        let otherFieldsField = infoNote.getField(label: NotenikConstants.otherFields)
        if otherFieldsField != nil {
            let otherFields = BooleanValue(otherFieldsField!.value.value)
            collection!.otherFields = otherFields.isTrue
            if collection!.otherFields {
                collection!.dict.unlock()
            }
        }
        
        let sortParmStr = infoNote.getFieldAsString(label: NotenikConstants.sortParmCommon)
        var nsp: NoteSortParm = sortParm
        nsp.str = sortParmStr
        sortParm = nsp
        
        let sortDescField = infoNote.getField(label: NotenikConstants.sortDescending)
        if sortDescField != nil {
            let sortDescending = BooleanValue(sortDescField!.value.value)
            collection!.sortDescending = sortDescending.isTrue
        }
        
        let mirrorAutoIndexField = infoNote.getField(label: NotenikConstants.mirrorAutoIndexCommon)
        if mirrorAutoIndexField != nil {
            let mirrorAutoIndex = BooleanValue(mirrorAutoIndexField!.value.value)
            collection!.mirrorAutoIndex = mirrorAutoIndex.isTrue
        }
        
        let bodyLabelField = infoNote.getField(label: NotenikConstants.bodyLabelDisplayCommon)
        if bodyLabelField != nil {
            let bodyLabel = BooleanValue(bodyLabelField!.value.value)
            collection!.bodyLabel = bodyLabel.isTrue
        }
        
        let h1TitlesField = infoNote.getField(label: NotenikConstants.h1TitlesDisplayCommon)
        if h1TitlesField != nil {
            let h1Titles = BooleanValue(h1TitlesField!.value.value)
            collection!.h1Titles = h1Titles.isTrue
        }
        
        let noteFileFormatField = infoNote.getField(label: NotenikConstants.noteFileFormat)
        if noteFileFormatField != nil {
            let noteFileFormat = NoteFileFormat(rawValue: noteFileFormatField!.value.value)
            if noteFileFormat != nil {
                collection!.noteFileFormat = noteFileFormat!
            } else {
                logError("\(noteFileFormatField!.value.value) is an invalid INFO file value for the key \(NotenikConstants.noteFileFormat).")
            }
        }
        
        let lastStartupDate = infoNote.getFieldAsString(label: NotenikConstants.lastStartupDateCommon)
        collection!.lastStartupDate = lastStartupDate
        
        let lastSelIndexStr = infoNote.getFieldAsString(label: NotenikConstants.lastIndexSelected)
        let lastSelIndex = Int(lastSelIndexStr) ?? -1
        lastIndexSelected = lastSelIndex
        
        infoFound = true
        return infoNote
    }
    
    /// Attempt to load the template file.
    func loadTemplateFile() -> Note? {

        guard let templateNote = collection!.lib.getNote(type: .template, collection: collection!) else { return nil }
        guard templateNote.fields.count > 0 else { return nil }
        guard collection!.dict.count > 0 else { return nil }

        templateFound = true
        
        let applyTemplateValues = ApplyTemplateValues(templateNote: templateNote)
        applyTemplateValues.applyValuesToDict(collection: collection!)
        
        let dict = collection!.dict
        let types = collection!.typeCatalog
        
        let bodyDef = dict.getDef(collection!.bodyFieldDef)
        if bodyDef == nil {
            _ = dict.addDef(typeCatalog: types, label: NotenikConstants.body)
        }
        
        if !collection!.otherFields {
            collection!.dict.lock()
        }
        
        collection!.preferredExt = collection!.lib.templateExt
        collection!.finalize()
        return templateNote
    }
    
    /// Close the current collection, if one is open
    public func closeCollection() {

        guard collection != nil else { return }
        if !collection!.readOnly {
            _ = saveInfoFile()
            _ = aliasList.saveToDisk()
        }

        collection = nil
        collectionOpen = false
        if bunch != nil {
            bunch!.close()
        }
        templateFound = false
        infoFound = false
        reports = []
    }
    
    /// Open a Collection to be used as an archive for another Collection. This will
    /// be a normal open, if the archive has already been created, or will create
    /// a new Collection, if the Archive is being accessed for the first time.
    ///
    /// - Parameters:
    ///   - primeIO: The I/O module for the primary collection.
    ///   - archivePath: The location of the archive collection.
    /// - Returns: The Archive Note Collection, if collection opened successfully.
    public func openArchive(primeIO: NotenikIO, archivePath: String) -> NoteCollection? {
        
        // See if the archive already exists
        let primeCollection = primeIO.collection!
        let primeRealm = primeCollection.lib.realm
        var archiveCollection = openCollection(realm: primeRealm, collectionPath: archivePath, readOnly: false)
        guard archiveCollection == nil else { return archiveCollection }
        
        // If not, then create a new one
        var newOK = initCollection(realm: primeRealm, collectionPath: archivePath, readOnly: false)
        guard newOK else { return nil }
        archiveCollection = collection
        archiveCollection!.sortParm = primeCollection.sortParm
        archiveCollection!.sortDescending = primeCollection.sortDescending
        archiveCollection!.dict = primeCollection.dict
        archiveCollection!.preferredExt = primeCollection.preferredExt
        newOK = newCollection(collection: archiveCollection!)
        guard newOK else { return nil }
        return collection
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Load Attachments and attach them to Notes. 
    //
    // -----------------------------------------------------------
    
    /// Load attachments from the files folder.
    func loadAttachments() {
        attachments = collection!.lib.getContents(type: .attachments)
        guard attachments != nil else { return }
        attachments!.sort()
        logInfo("\(attachments!.count) Attachments loaded for the Collection")
    }
    
    /// Add matching attachments to a Note. 
    func addAttachments(to note: Note) {
        guard let base = note.fileInfo.base else { return }
        guard attachments != nil else { return }
        var i = 0
        var looking = true
        while i < attachments!.count && looking {
            if attachments![i].fileName.hasPrefix(base) {
                let attachmentName = AttachmentName()
                attachmentName.setName(note: note, fullName: attachments![i].fileName)
                note.attachments.append(attachmentName)
                attachments!.remove(at: i)
            } else if base < attachments![i].fileName {
                looking = false
            } else {
                i += 1
            }
        }
    }
    
    /// Add the specified attachment to the given note.
    ///
    /// - Parameters:
    ///   - from: The location of the file to be attached.
    ///   - to: The Note to which the file is to be attached.
    ///   - with: The unique identifier for this attachment for this note.
    /// - Returns: True if attachment added successfully, false if any sort of failure.
    public func addAttachment(from: URL, to: Note, with: String) -> Bool {
        let attachmentName = AttachmentName()
        attachmentName.setName(fromFile: from, note: to, suffix: with)
        let attachmentResource = collection!.lib.storeAttachment(fromURL: from, attachmentName: attachmentName.fullName)
        guard attachmentResource != nil else { return false }
        to.attachments.append(attachmentName)
        return true
    }
    
    /// Reattach the attachments for this note to make sure they are attached
    /// to the new note.
    ///
    /// - Parameters:
    ///   - note1: The Note to which the files were previously attached.
    ///   - note2: The Note to wich the files should now be attached.
    /// - Returns: True if successful, false otherwise.
    public func reattach(from: Note, to: Note) -> Bool {
        guard from.attachments.count > 0 else { return true }
        guard let fromNoteName = from.fileInfo.base else { return false }
        guard let toNoteName = to.fileInfo.base else { return false }
        guard let lib = collection?.lib else { return false }
        guard lib.hasAvailable(type: .attachments) else { return false }
        if fromNoteName == toNoteName { return true }
        let attachmentsPath = lib.getPath(type: .attachments)
        to.attachments = []
        var allOK = true
        for attachment in from.attachments {
            let newAttachmentName = attachment.copy() as! AttachmentName
            newAttachmentName.changeNote(note: to)
            
            let fromResource = ResourceFileSys(folderPath: attachmentsPath, fileName: attachment.fullName)
            guard fromResource.isAvailable else {
                logError("Attachment not available at \(fromResource.actualPath)")
                allOK = false
                continue
            }
            
            let toResource = ResourceFileSys(folderPath: attachmentsPath, fileName: newAttachmentName.fullName)
            guard !toResource.exists else {
                logError("Attachment already exists at \(toResource.actualPath)")
                allOK = false
                continue
            }
            
            let newResource = lib.storeAttachment(fromURL: fromResource.url!, attachmentName: newAttachmentName.fullName)
            guard newResource != nil else {
                logError("Problems copying attachment to new name at: \(toResource.actualPath)")
                allOK = false
                continue
            }
            
            let ok = fromResource.remove()
            if !ok {
                allOK = false
            }
            
        }
        return allOK
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    public func getURLforAttachment(attachmentName: AttachmentName) -> URL? {
        return getURLforAttachment(fileName: attachmentName.fullName)
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    public func getURLforAttachment(fileName: String) -> URL? {
        guard let lib = collection?.lib else { return nil }
        guard lib.hasAvailable(type: .attachments) else { return nil }
        let attachmentResource = lib.getAttachmentResource(fileName: fileName)
        guard attachmentResource != nil else { return nil }
        return attachmentResource!.url
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Load Reports.
    //
    // -----------------------------------------------------------
    
    /// Load A list of available reports from the reports folder.
    public func loadReports() {
        reports = []
        guard let lib = collection?.lib else { return }
        guard lib.hasAvailable(type: .reports) else { return }
        
        guard let contents = lib.getContents(type: .reports) else { return }
            
        var scriptsFound = false
        for content in contents {
            if content.type == .script {
                scriptsFound = true
            }
        }
        
        for content in contents {
            if content.type == .script {
                let report = MergeReport()
                report.reportName = content.base
                report.reportType = content.extLower
                reports.append(report)
            } else if !scriptsFound && content.baseLower.contains(mergeTemplateID) {
                let report = MergeReport()
                report.reportName = content.base
                report.reportType = content.extLower
                reports.append(report)
            }
        }

    }
    
    // -----------------------------------------------------------
    //
    // MARK: Read, write and update notes. 
    //
    // -----------------------------------------------------------
    
    /// Register modifications to the old note to make the new note.
    ///
    /// - Parameters:
    ///   - oldNote: The old version of the note.
    ///   - newNote: The new version of the note.
    /// - Returns: The modified note and its position.
    public func modNote(oldNote: Note, newNote: Note) -> (Note?, NotePosition) {
        let modOK = deleteNote(oldNote)
        guard modOK else { return (nil, NotePosition(index: -1)) }
        return addNote(newNote: newNote)
    }
    
    /// Add a new Note to the Collection
    ///
    /// - Parameter newNote: The Note to be added
    /// - Returns: The added Note and its position, if added successfully;
    ///            otherwise nil and -1.
    public func addNote(newNote: Note) -> (Note?, NotePosition) {
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        guard newNote.hasTitle() else { return (nil, NotePosition(index: -1)) }
        if collection!.hasTimestamp {
            if !newNote.hasTimestamp() {
                _ = newNote.setTimestamp("")
            }
        }
        ensureUniqueID(for: newNote)
        let added = bunch!.add(note: newNote)
        guard added else { return (nil, NotePosition(index: -1)) }
        newNote.fileInfo.genFileName()
        let written = writeNote(newNote)
        if !written {
            return (nil, NotePosition(index: -1))
        } else {
            let (_, position) = bunch!.selectNote(newNote)
            return (newNote, position)
        }
    }
    
    /// Write a note to disk within its collection.
    ///
    /// - Parameter note: The Note to be saved to disk.
    /// - Returns: True if saved successfully, false otherwise.
    public func writeNote(_ note: Note) -> Bool {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return false }
        guard !note.fileInfo.isEmpty else { return false }
        
        note.setDateModNow()
        pickLists.registerNote(note: note)
        
        return collection!.lib.saveNote(note: note)
    }
    
    /// Check for uniqueness and, if necessary, Increment the suffix
    /// for this Note's ID until it becomes unique.
    public func ensureUniqueID(for newNote: Note) {
        var existingNote = bunch!.getNote(forID: newNote.noteID)
        var inc = false
        while existingNote != nil {
            _ = newNote.incrementID()
            existingNote = bunch!.getNote(forID: newNote.noteID)
            inc = true
        }
        if inc {
            newNote.updateIDSource()
        }
    }
    
    /// Delete the currently selected Note, plus any attachments it might have.
    ///
    /// - Returns: The new Note on which the collection should be positioned.
    public func deleteSelectedNote() -> (Note?, NotePosition) {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        guard let lib = collection?.lib else { return (nil, NotePosition(index: -1)) }
        
        // Make sure we have a selected note
        let (noteToDelete, oldPosition) = bunch!.getSelectedNote()
        guard noteToDelete != nil && oldPosition.index >= 0 else { return (nil, NotePosition(index: -1)) }
        
        let (priorNote, priorPosition) = bunch!.priorNote(oldPosition)
        var returnNote = priorNote
        var returnPosition = priorPosition
 
        _ = bunch!.delete(note: noteToDelete!)
        if priorNote != nil {
            let (nextNote, nextPosition) = bunch!.nextNote(priorPosition)
            if nextNote != nil {
                returnNote = nextNote
                returnPosition = nextPosition
            }
        }
        if returnNote == nil {
            (returnNote, returnPosition) = bunch!.firstNote()
        }
        
        let noteResource = lib.getNoteResource(note: noteToDelete!)
        guard noteResource != nil && noteResource!.isAvailable else { return (nil, NotePosition(index: -1)) }
        
        for attachment in noteToDelete!.attachments {
            let attachmentResource = lib.getAttachmentResource(fileName: attachment.fullName)
            if attachmentResource == nil {
                logError("Problems deleting attachment named \(attachment.fullName)")
            } else {
                let deleted = attachmentResource!.remove()
                if !deleted {
                    logError("Problems deleting attachment named \(attachment.fullName)")
                }
            }
        }
        
        let deleted = noteResource!.remove()
        if !deleted {
            logError("Could not delete selected note at: \(noteResource!.actualPath)")
            return (nil, NotePosition(index: -1))
        }
        
        return (returnNote, returnPosition)
    }
    
    /// Delete the given note
    ///
    /// - Parameter noteToDelete: The note to be deleted.
    /// - Returns: True if delete was successful, false otherwise.
    public func deleteNote(_ noteToDelete: Note) -> Bool {
        
        guard collection != nil && collectionOpen else { return false }
        
        var deleted = false
        deleted = bunch!.delete(note: noteToDelete)
        guard deleted else { return false }

        let noteURL = noteToDelete.fileInfo.url
        deleted = FileUtils.removeItem(at: noteURL)
        if !deleted {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Could not delete note file at '\(noteURL!.path)'")
        }
        return deleted
    }
    
    /// Read a note from disk.
    ///
    /// - Parameter noteURL: The complete URL pointing to the note file to be read.
    /// - Returns: A note composed from the contents of the indicated file,
    ///            or nil, if problems reading file.
    func readNote(fileName: String, reportErrors: Bool = true) -> Note? {
        
        guard let lib = collection?.lib else { return nil }
        return lib.getNote(type: .note, collection: collection!, fileName: fileName, reportErrors: reportErrors)
    }
    
    /// Reload the note in memory from the backing data store.
    public func reloadNote(_ noteToReload: Note) -> Note? {

        guard collection != nil && collectionOpen else { return nil }
        guard let lib = collection?.lib else { return nil }
        guard let fileName = noteToReload.fileInfo.baseDotExt else { return nil }
        let reloaded = lib.getNote(type: .note, collection: collection!, fileName: fileName, reportErrors: true)
        guard reloaded != nil && reloaded!.hasTitle() else { return nil }
        var ok = false
        ok = bunch!.delete(note: noteToReload)
        guard ok else { return nil }
        ok = bunch!.add(note: reloaded!)

        if ok {
            return reloaded
        } else {
            return nil
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Access Notes
    //
    // -----------------------------------------------------------
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    public func firstNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.firstNote()
    }
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    public func lastNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.lastNote()
    }

    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then return a nil Note and an index of -1.
    public func nextNote(_ position : NotePosition) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.nextNote(position)
    }
    
    /// Return the prior note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The index position of the last note accessed.
    /// - Returns: A tuple containing the prior note, along with its index position.
    ///            if we're outside the bounds of the list, then return a nil Note and an index of -1.
    public func priorNote(_ position : NotePosition) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.priorNote(position)
    }
    
    /// Return the position of a given note.
    ///
    /// - Parameter note: The note to find.
    /// - Returns: A Note Position
    public func positionOfNote(_ note: Note) -> NotePosition {
        guard collection != nil && collectionOpen else { return NotePosition(index: -1) }
        let (_, position) = bunch!.selectNote(note)
        return position
    }
    
    /// Select the note at the given position in the sorted list.
    ///
    /// - Parameter index: An index value pointing to a position in the list.
    /// - Returns: A tuple containing the indicated note, along with its index position.
    ///            - If the list is empty, return nil and -1.
    ///            - If the index is too high, return the last note.
    ///            - If the index is too low, return the first note.
    public func selectNote(at index: Int) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.selectNote(at: index)
    }
    
    /// Return the note currently selected.
    ///
    /// If the list index is out of range, return a nil Note and an index posiiton of -1.
    public func getSelectedNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.getSelectedNote()
    }
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    public func getNote(at index: Int) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(at: index)
    }
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    public func getNote(forID id: NoteID) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forID: id)
    }
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    public func getNote(forID id: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forID: id)
    }
    
    /// In conformance with MkdownWikiLinkLookup protocol, lookup a title given a timestamp.
    /// - Parameter title: A wiki link target that is possibly a timestamp instead of a title.
    /// - Returns: The corresponding title, if the lookup was successful, otherwise the title
    ///            that was passed as input.
    public func mkdownWikiLinkLookup(linkText: String) -> String {
        guard collection != nil && collectionOpen else { return linkText }
        guard collection!.hasTimestamp else { return linkText }
        
        // Check for first possible case: title within the wiki link
        // points directly to another note having that same title.
        let titleID = StringUtils.toCommon(linkText)
        var linkedNote = getNote(forID: titleID)
        if linkedNote != nil {
            aliasList.add(titleID: titleID, timestamp: linkedNote!.timestamp.value)
            return linkText
        }
        
        // Check for second possible case: title within the wiki link
        // used to point directly to another note having that same title,
        // but the target note's title has since been modified.
        let timestamp = aliasList.get(titleID: titleID)
        if timestamp != nil {
            linkedNote = getNote(forTimestamp: timestamp!)
            if linkedNote != nil {
                return linkedNote!.title.value
            }
        }
        
        // Check for third possible case: string within the wiki link
        // is already a timestamp pointing to another note.
        guard linkText.count < 15 && linkText.count > 11 else { return linkText }
        linkedNote = getNote(forTimestamp: linkText)
        if linkedNote != nil {
            return linkedNote!.title.value
        }
        
        // Nothing worked, so just return the linkText.
        return linkText
    }
    
    /// Get the existing note with the specified timestamp, if one exists.
    /// - Parameter stamp: The timestamp we are looking for.
    /// - Returns: The Note with this timestamp, if one exists; otherwise nil.
    public func getNote(forTimestamp stamp: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forTimestamp: stamp)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Import new Notes into the Collection
    //
    // -----------------------------------------------------------
    
    var notesImported = 0
    var noteToImport: Note?
    
    /// Import Notes from a CSV or tab-delimited file
    ///
    /// - Parameter importer: A Row importer that will return rows and columns.
    /// - Parameter fileURL: The URL of the file to be imported.
    /// - Returns: The number of rows imported.
    public func importRows(importer: RowImporter, fileURL: URL) -> Int {
        importer.setContext(consumer: self)
        notesImported = 0
        guard collection != nil && collectionOpen else { return 0 }
        noteToImport = Note(collection: collection!)
        importer.read(fileURL: fileURL)
        return notesImported
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    public func consumeField(label: String, value: String) {
        let ok = noteToImport!.setField(label: label, value: value)
        if !ok {
            logError("Could not set note field \(label) to value of \(value)")
        }
    }
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    public func consumeRow(labels: [String], fields: [String]) {
        noteToImport!.setID()
        let (newNote, _) = addNote(newNote: noteToImport!)
        if newNote != nil {
            notesImported += 1
        }
        noteToImport = Note(collection: collection!)
    }
    
    /// Import an alias list from a second instance of FileIO.
    public func importAliasList(from: FileIO) {
        aliasList.importFrom(from.aliasList)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Bulk Functions
    //
    // -----------------------------------------------------------
    
    /// Purge closed notes from the collection, optionally writing them
    /// to an archive collection.
    ///
    /// - Parameter archiveIO: An optional I/O module already set up
    ///                        for an archive collection.
    /// - Returns: The number of notes purged. 
    public func purgeClosed(archiveIO: NotenikIO?) -> Int {

        guard collection != nil && collectionOpen else { return 0 }
        guard let notes = bunch?.notesList else { return 0 }
        
        // Now look for closed notes
        var notesToDelete: [Note] = []
        for note in notes {
            if note.isDone {
                var okToDelete = true
                if archiveIO != nil {
                    let noteCopy = note.copy() as! Note
                    noteCopy.collection = archiveIO!.collection!
                    let (archiveNote, _) = archiveIO!.addNote(newNote: noteCopy)
                    if archiveNote == nil {
                        okToDelete = false
                        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                          category: "FileIO",
                                          level: .error,
                                          message: "Could not add note titled '\(note.title.value)' to archive")
                    }
                } // end of optional archive operation
                if okToDelete {
                    notesToDelete.append(note)
                }
            } // end if note is done
        } // end for each note in the collection
        
        // Now do the actual deletes
        for note in notesToDelete {
            _ = deleteNote(note)
        }
        
        return notesToDelete.count
    }
    
    /// Change the preferred file extension for the Collection.
    public func changePreferredExt(from: String, to: String) -> Bool {
        guard let lib = collection?.lib else { return false }
        
        var ok = true
        ok = lib.changeTemplateExt(to: to)
        if !ok { return false }
        
        let errors = changeAllNoteExtensions(to: to)
        if ok && errors > 0 {
            ok = false
        }
        return ok
    }
    
    func changeAllNoteExtensions(to newFileExt: String) -> Int {
        guard collection != nil && collectionOpen else { return 0 }
        guard let lib = collection?.lib else { return 0 }
        var (note, position) = firstNote()
        var errors = 0
        while note != nil {
            let noteResource = lib.getNoteResource(note: note!)
            let noteResourceMod = noteResource?.changeExt(to: newFileExt)
            if noteResourceMod != nil && noteResourceMod!.isAvailable {
                note!.fileInfo.ext = newFileExt
            } else {
                errors += 1
            }
            
            // more to do here ???
            
            let (nextNt, nextPos) = nextNote(position)
            note = nextNt
            position = nextPos
        }
        return errors
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Access the Tags
    //
    // -----------------------------------------------------------
    
    public func getTagsNodeRoot() -> TagsNode? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.notesTree.root
    }
    
    /// Create an iterator for the tags nodes.
    public func makeTagsNodeIterator() -> TagsNodeIterator {
        return TagsNodeIterator(noteIO: self)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Logging and Debugging
    //
    // -----------------------------------------------------------
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FileIO",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FileIO",
                          level: .error,
                          message: msg)
    }
    
    // Used for debugging. 
    public func displayWebInfo(_ when: String) {
        print(" ")
        print("FileIO.displayWebInfo \(when)")
        guard collection != nil else {
            print("NoteCollection is nil!")
            return
        }
        print("Collection Full Path: \(collection!.lib.getPath(type: .collection))")
        print("Collection Notes Path: \(collection!.lib.getPath(type: .notes))")
        print("Collection has notes subfolder? \(collection!.lib.notesSubFolder.isAvailable)")
        if collection!.mirror != nil {
            print("Collection has a Notes Transformer")
        }
    }
    
}
