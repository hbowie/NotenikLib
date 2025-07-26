//
//  BunchIO.swift
//  Notenik
//
//  Created by Herb Bowie on 5/17/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A NotenikIO module that stores all information in memory, without any persistent
/// backing. Used by RealmIO.
class BunchIO: NotenikIO, RowConsumer  {
    
    var provider       : Provider = Provider()
    var realm          : Realm
    var collection     : NoteCollection?
    var collectionFullPath: String?
    var collectionOpen = false
    
    var reports: [MergeReport] = []
    var reportsFullPath: String? = nil
    
    /// A list of export scripts availabe for the currently open Collection.
    public var exportScripts: [ExportScript] = []
    
    var pickLists = ValuePickLists()
    
    var bunch          : BunchOfNotes?
    
    var notesList: NotesList {
        if bunch != nil {
            return bunch!.notesList
        } else {
            return NotesList()
        }
    }
    
    var notePosition   = NotePosition(index: -1)
    
    var notesImported  = 0
    var noteToImport:    Note?
    
    var aliasList      = AliasList()
    
    /// Default initialization
    init() {
        provider.providerType = .memory
        realm = Realm(provider: provider)
        collection = NoteCollection(realm: realm)
        realm.name = NSUserName()
        realm.path = NSHomeDirectory()
        closeCollection()
    }
    
    /// Return the number of notes in the current collection.
    ///
    /// - Returns: The number of notes in the current collection
    var notesCount: Int {
        guard bunch != nil else { return 0 }
        return bunch!.count
    }
    
    /// Return the total number of Notes in the Collection.
    public var count: Int {
        guard bunch != nil else { return 0 }
        return bunch!.count
    }
    
    /// The position of the selected note, if any, in the current collection
    var position:   NotePosition? {
        if !collectionOpen || collection == nil || bunch == nil {
            return nil
        } else {
            notePosition.index = bunch!.listIndex
            return notePosition
        }
    }
    
    /// Get or Set the NoteSortParm for the current collection.
    var sortParm: NoteSortParm {
        get {
            return collection!.sortParm
        }
        set {
            if newValue != collection!.sortParm {
                collection!.sortParm = newValue
                bunch!.sortParm = newValue
            }
        }
    }
    
    /// Should the list be in descending sequence?
    var sortDescending: Bool {
        get {
            return collection!.sortDescending
        }
        set {
            if newValue != collection!.sortDescending {
                collection!.sortDescending = newValue
                bunch!.sortDescending = newValue
            }
        }
    }
    
    var sortBlankDatesLast: Bool {
        get {
            return collection!.sortBlankDatesLast
        }
        set {
            if newValue != collection!.sortBlankDatesLast {
                collection!.sortBlankDatesLast = newValue
                bunch!.sortBlankDatesLast = newValue
            }
        }
    }
    
    /// Open a Collection to be used as an archive for another Collection. This will
    /// be a normal open, if the archive has already been created, or will create
    /// a new Collection, if the Archive is being accessed for the first time.
    ///
    /// - Parameters:
    ///   - primeIO: The I/O module for the primary collection.
    ///   - archivePath: The location of the archive collection.
    /// - Returns: The Archive Note Collection, if collection opened successfully.
    func openArchive(primeIO: NotenikIO, archivePath: String) -> NoteCollection? {
        
        let primeCollection = primeIO.collection!
        let primeRealm = primeCollection.lib.realm
        var newOK = initCollection(realm: primeRealm, collectionPath: archivePath, readOnly: false)
        guard newOK else { return nil }
        let archiveCollection = collection
        archiveCollection!.sortParm = primeCollection.sortParm
        archiveCollection!.dict = primeCollection.dict
        newOK = newCollection(collection: archiveCollection!)
        guard newOK else { return nil }
        return collection
    }
    
    /// Purge closed notes from the collection, optionally writing them
    /// to an archive collection.
    ///
    /// - Parameter archiveIO: An optional I/O module already set up
    ///                        for an archive collection.
    /// - Returns: The number of notes purged.
    func purgeClosed(archiveIO: NotenikIO?) -> Int {
        guard collection != nil && collectionOpen else { return 0 }
        guard let sortedNotes = bunch?.notesList else { return 0 }
        
        // Now look for closed notes
        var notesToDelete: [Note] = []
        for sortedNote in sortedNotes {
            if sortedNote.isDone {
                var okToDelete = true
                if archiveIO != nil {
                    let (archiveNote, _) = archiveIO!.addNote(newNote: sortedNote.note)
                    if archiveNote == nil {
                        okToDelete = false
                        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                          category: "BunchIO",
                                          level: .error,
                                          message: "Could not add note titled '\(sortedNote.note.title.value)' to archive")
                    }
                } // end of optional archive operation
                if okToDelete {
                    notesToDelete.append(sortedNote.note)
                }
            } // end if note is done
        } // end for each note in the collection
        
        // Now do the actual deletes
        for note in notesToDelete {
            let deleted = deleteNote(note, preserveAttachments: false)
            if !deleted {
                print ("Problems deleting note!")
            }
        }
        
        return notesToDelete.count
    }
    
    /// Provide an inspector that will be passed each Note as a Collection is opened.
    func setInspector(_ inspector: NoteOpenInspector) {
        // Ignore for BunchIO
    }
    
    /// Open the collection.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: A NoteCollection object, if the collection was opened successfully;
    ///            otherwise nil.
    func openCollection(realm: Realm, collectionPath: String, readOnly: Bool,
                        multiRequests: MultiFileRequestStack? = nil) -> NoteCollection? {
        
        let initOK = initCollection(realm: realm, collectionPath: collectionPath, readOnly: readOnly)
        guard initOK else { return nil }
        bunch = BunchOfNotes(collection: collection!)
        collectionOpen = true
        return collection
    }
    
    /// Initialize the collection.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: True if successful, false otherwise.
    func initCollection(realm: Realm, collectionPath: String, readOnly: Bool) -> Bool {
        closeCollection()
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "BunchIO",
                          level: .info,
                          message: "Initializing Collection")
        self.realm = realm
        self.provider = realm.provider
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "BunchIO",
                          level: .info,
                          message: "Realm:      " + realm.path)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "BunchIO",
                          level: .info,
                          message: "Collection: " + collectionPath)
        
        // Let's see if we have an actual path to a usable directory
        var collectionURL : URL
        if realm.path == "" || realm.path == " " {
            collectionURL = URL(fileURLWithPath: collectionPath)
        } else if collectionPath == "" || collectionPath == " " {
            collectionURL = URL(fileURLWithPath: realm.path)
        } else {
            let realmURL = URL(fileURLWithPath: realm.path)
            collectionURL = realmURL.appendingPathComponent(collectionPath)
        }
        collectionFullPath = collectionURL.path
        collection = NoteCollection(realm: realm)
        collection!.path = collectionPath
        collection!.setTitleFromURL(collectionURL)
        
        return true
    }
    
    /// Open a New Collection.
    ///
    /// The passed collection should already have been initialized
    /// via a call to initCollection above.
    func newCollection(collection: NoteCollection, withFirstNote: Bool = true) -> Bool {
        self.collection = collection
        bunch = BunchOfNotes(collection: collection)
        collectionOpen = true
        return true
    }
    
    /// Get information about the provider.
    func getProvider() -> Provider {
        return provider
    }
    
    /// Get the default realm.
    func getDefaultRealm() -> Realm {
        return realm
    }
    
    /// Add the default definitions to the Collection's dictionary:
    /// Title, Tags, Link and Body
    func addDefaultDefinitions() {
        guard collection != nil else { return }
        let dict = collection!.dict
        let types = collection!.typeCatalog
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.title)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.tags)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.link)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.body)
    }
    
    /// Load the list of reports available for this collection.
    func loadReports() {
        // Nothing to do here. 
    }
    
    /// Load the list of export scripts available for this collection.
    func loadExportScripts() {
        // Nothing to do here. 
    }
    
    /// Import Notes from a CSV or tab-delimited file
    ///
    /// - Parameter fileURL: The URL of the file to be imported.
    /// - Returns: The number of notes imported.
    func importRows(importer: RowImporter, fileURL: URL, importParms: ImportParms) -> (Int, Int) {
        notesImported = 0
        guard collection != nil && collectionOpen else { return (0, 0) }
        importer.setContext(consumer: self)
        noteToImport = Note(collection: collection!)
        _ = importer.read(fileURL: fileURL)
        return (notesImported, 0)
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String, rule: FieldUpdateRule = .always) {
        _ = noteToImport!.setField(label: label, value: value)
    }
    
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    func consumeRow(labels: [String], fields: [String]) {
        let (newNote, _) = addNote(newNote: noteToImport!)
        if newNote != nil {
            notesImported += 1
        }
        noteToImport = Note(collection: collection!)
    }
    
    /// Reload the note in memory from the backing data store.
    func reloadNote(_ noteToReload: Note) -> Note? {
        return nil
    }
    
    /// Register modifications to the old note to make the new note.
    ///
    /// - Parameters:
    ///   - oldNote: The old version of the note.
    ///   - newNote: The new version of the note.
    /// - Returns: The modified note and its position.
    func modNote(oldNote: Note, newNote: Note) -> (Note?, NotePosition) {
        let modOK = deleteNote(oldNote, preserveAttachments: false)
        guard modOK else { return (nil, NotePosition(index: -1)) }
        return addNote(newNote: newNote)
    }
    
    /// Add a new Note to the Collection
    ///
    /// - Parameter newNote: The Note to be added
    /// - Returns: The added Note and its position, if added successfully;
    ///            otherwise nil and -1.
    func addNote(newNote: Note) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else {
            print("No collection available")
            return (nil, NotePosition(index: -1))
        }
        guard newNote.hasTitle() else {
            print("Note does not have a title")
            return (nil, NotePosition(index: -1))
        }
        
        let added = bunch!.add(note: newNote)
        guard added else {
            print("Trouble adding to bunch of notes")
            return (nil, NotePosition(index: -1))
        }
        pickLists.registerNote(note: newNote)
        if newNote.hasSeq() {
            collection!.registerSeq(newNote.seq)
        }
        let (_, position) = bunch!.selectNote(newNote)
        return (newNote, position)
    }
    
    /// Check for uniqueness and, if necessary, Increment the suffix
    /// for this Note's ID until it becomes unique.
    func ensureUniqueID(for note: Note) {
        var dupeCounter = 1
        let originalTitle = note.title.value
        var existingNote = bunch!.getNote(forID: note.noteID)
        while existingNote != nil {
            dupeCounter += 1
            _ = note.setTitle("\(originalTitle) \(dupeCounter)")
            note.identify()
            existingNote = bunch!.getNote(forID: note.noteID)
        }
    }
    
    /// Delete the given note
    ///
    /// - Parameter noteToDelete: The note to be deleted.
    /// - Returns: True if delete was successful, false otherwise.
    func deleteNote(_ noteToDelete: Note, preserveAttachments: Bool) -> Bool {
        guard collection != nil && collectionOpen else { return false }
        let deleted = bunch!.delete(note: noteToDelete)
        return deleted
    }
    
    /// Register a new Combo Value. 
    public func registerComboValue(comboDef: FieldDefinition, value: String) {
        guard bunch != nil else { return }
        bunch!.registerComboValue(comboDef: comboDef, value: value)
    }
    
    /// Select the given note and return its index, if it can be found in the sorted list, using its current sort key.
    ///
    /// - Parameter note: The note we're looking for.
    /// - Returns: The note as it was found in the list, along with its position.
    ///            If not found, return nil and -1.
    func selectNote(note: Note) -> (SortedNote?, NotePosition) {
        return bunch!.selectNote(note)
    }
    
    /// Select the note at the given position in the sorted list.
    ///
    /// - Parameter index: An index value pointing to a position in the list.
    /// - Returns: A tuple containing the indicated note, along with its index position.
    ///            - If the list is empty, return nil and -1.
    ///            - If the index is too high, return the last note.
    ///            - If the index is too low, return the first note.
    func selectNote(at index: Int) -> (SortedNote?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.selectNote(at: index)
    }
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at index: Int) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(at: index)
    }
    
    /// Return the Sorted Note  at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getSortedNote(at index: Int) -> SortedNote? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getSortedNote(at: index)
    }
    
    /// Get the Note that is known by the passed identifier, one way or another.
    /// - Returns: The matching Note, if one could be found.
    public func getNote(knownAs: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        
        // Check for first possible case: title within the wiki link
        // points directly to another note having that same title.
        let commonID = StringUtils.toCommon(knownAs)
        var knownNote = getNote(forID: commonID)
        if knownNote != nil {
            aliasList.add(titleID: commonID, timestamp: knownNote!.timestampAsString)
            return knownNote!
        }
        
        // Check for second possible case: title within the wiki link
        // uses the singular form of a word, but the word appears in its
        // plural form within the target note's title.
        knownNote = getNote(forID: commonID + "s")
        if knownNote != nil {
            return knownNote!
        }
        
        // Check for third possible case: title within the wiki link
        // refers to an alias by which a Note is also known.
        if collection!.akaFieldDef != nil {
            knownNote = getNote(alsoKnownAs: commonID)
            if knownNote != nil {
                return knownNote!
            }
        }
        
        guard collection!.hasTimestamp else { return nil }
        
        // Check for fourth possible case: title within the wiki link
        // used to point directly to another note having that same title,
        // but the target note's title has since been modified.
        let timestamp = aliasList.get(titleID: commonID)
        if timestamp != nil {
            knownNote = getNote(forTimestamp: timestamp!)
            if knownNote != nil {
                return knownNote!
            }
        }
        
        // Check for fifth possible case: string within the wiki link
        // is already a timestamp pointing to another note.
        guard knownAs.count < 15 && knownAs.count > 11 else { return nil }
        knownNote = getNote(forTimestamp: knownAs)
        if knownNote != nil {
            return knownNote!
        }
        
        // Nothing worked, so return nada / zilch.
        return nil
    }
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    func getNote(forID noteID: NoteIdentification) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forID: noteID)
    }
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    func getNote(forID id: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forID: id)
    }
    
    /// Get the existing Note with the specified AKA value, if one exists.
    /// - Parameter alsoKnownAs: The AKA value we are looking for.
    /// - Returns: The Note having this aka value, if one exists; otherwise nil.
    func getNote(alsoKnownAs aka: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(alsoKnownAs: aka)
    }
    
    /// Return the Alias entries for the Collection.
    /// - Returns: All of the AKA aliases, plus the Notes to which they point.
    public func getAKAEntries() -> AKAentries {
        guard collection != nil && collectionOpen else { return AKAentries() }
        return bunch!.getAKAEntries()
    }
    
    /// In conformance with MkdownWikiLinkLookup protocol, lookup a title given a timestamp.
    /// - Parameter title: A wiki link target that is possibly a timestamp instead of a title.
    /// - Returns: The corresponding title, if the lookup was successful, otherwise the title
    ///            that was passed as input.
    func mkdownWikiLinkLookup(linkText: String) -> String {
        guard collection != nil && collectionOpen else { return linkText }
        guard linkText.count < 15 && linkText.count > 11 else { return linkText }
        let target = getNote(forTimestamp: linkText)
        guard target != nil else { return linkText }
        return target!.title.value
    }
    
    /// Get the existing note with the specified timestamp, if one exists.
    /// - Parameter stamp: The timestamp we are looking for.
    /// - Returns: The Note with this timestamp, if one exists; otherwise nil.
    func getNote(forTimestamp stamp: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forTimestamp: stamp)
    }
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    func firstNote() -> (SortedNote?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.firstNote()
    }
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    func lastNote() -> (SortedNote?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.lastNote()
    }
    
    
    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then return a nil Note and an index of -1.
    func nextNote(_ position : NotePosition) -> (SortedNote?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.nextNote(position)
    }
    
    /// Return the prior note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The index position of the last note accessed.
    /// - Returns: A tuple containing the prior note, along with its index position.
    ///            if we're outside the bounds of the list, then return a nil Note and an index of -1.
    func priorNote(_ position : NotePosition) -> (SortedNote?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.priorNote(position)
    }
    
    /// Return the position of a given note.
    ///
    /// - Parameter note: The note to find.
    /// - Returns: A Note Position
    func positionOfNote(_ note: Note) -> NotePosition {
        guard collection != nil && collectionOpen else { return NotePosition(index: -1) }
        let (_, position) = bunch!.selectNote(note)
        return position
    }
    
    /// Return the position of a given sorted note.
    /// - Parameter note: A Sorted Note entry.
    /// - Returns: The position within the master list.
    func positionOfNote(_ sortedNote: SortedNote) -> NotePosition {
        guard collection != nil && collectionOpen else { return NotePosition(index: -1) }
        return bunch!.positionOfNote(sortedNote)
    }
    
    /// Return the note currently selected.
    ///
    /// If the list index is out of range, return a nil Note and an index posiiton of -1.
    func getSelectedNote() -> (SortedNote?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.getSelectedNote()
    }
    
    /// Delete the currently selected Note
    ///
    /// - Returns: The new Note on which the collection should be positioned.
    func deleteSelectedNote(preserveAttachments: Bool) -> (SortedNote?, NotePosition) {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        
        // Make sure we have a selected note
        let (noteToDelete, oldPosition) = bunch!.getSelectedNote()
        guard noteToDelete != nil && oldPosition.index >= 0 else { return (nil, NotePosition(index: -1)) }
        
        let (priorNote, priorPosition) = bunch!.priorNote(oldPosition)
        var nextNote = priorNote
        var nextPosition = priorPosition
        
        let deleted = bunch!.delete(note: noteToDelete!.note)
        guard deleted else { return (nil, NotePosition(index: -1))}
        var positioned = false
        if priorNote != nil {
            (nextNote, nextPosition) = bunch!.nextNote(priorPosition)
            if nextNote != nil {
                positioned = true
            }
        }
        if !positioned {
            _ = bunch!.firstNote()
        }
        
        return (nextNote, nextPosition)
    }
    
    func getTagsNodeRoot() -> TagsNode? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.notesTree.root
    }
    
    /// Create an iterator for the tags nodes.
    func makeTagsNodeIterator() -> TagsNodeIterator {
        return TagsNodeIterator(noteIO: self)
    }
    
    /// Return the root of the Tags tree
    public func getOutlineNodeRoot() -> OutlineNode2? {
        guard collection != nil && collectionOpen && bunch?.outlineTree != nil else {
            return nil
        }
        return bunch!.outlineTree.root
    }
    
    /// Create an iterator for the tags nodes.
    public func makeOutlineNodeIterator() -> OutlineNodeIterator {
        return bunch!.outlineTree.makeIterator()
    }
    
    /// Close the current collection, if one is open.
    func closeCollection() {
        collection = nil
        collectionOpen = false
        if bunch != nil {
            bunch!.close()
        }
    }
    
    /// Stash Notenik special files into a special subfolder.
    func stashNotenikFilesInSubfolder()  {
        // Does nothing for this particular implementation of NotenikIO
    }
    
    /// Save some of the collection info to make it persistent
    func persistCollectionInfo() {
        // Does nothing for this particular implementation of NotenikIO
    }
    
    /// Write a note to disk within its collection.
    ///
    /// - Parameter note: The Note to be saved to disk.
    /// - Returns: True if saved successfully, false otherwise.
    func writeNote(_ note: Note) -> Bool {
        // Does nothing for this particular implementation of NotenikIO
        return false
    }
    
    /// Add the specified attachment to the given note.
    ///
    /// - Parameters:
    ///   - from: The location of the file to be attached.
    ///   - to: The Note to which the file is to be attached.
    ///   - with: The unique identifier for this attachment for this note.
    ///   - move: Should the file be moved instead of copied?
    /// - Returns: True if attachment added successfully, false if any sort of failure.
    func addAttachment(from: URL, to: Note, with: String, move: Bool) -> Bool {
        return false
    }
    
    /// Reattach the attachments for this note to make sure they are attached
    /// to the new note.
    ///
    /// - Parameters:
    ///   - note1: The Note to which the files were previously attached.
    ///   - note2: The Note to wich the files should now be attached.
    /// - Returns: True if successful, false otherwise.
    func reattach(from: Note, to: Note) -> Bool {
        if from.attachments.count == 0 { return true}
        return false
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(attachmentName: AttachmentName) -> URL? {
        return getURLforAttachment(fileName: attachmentName.fullName)
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(fileName: String) -> URL? {
        return nil
    }
    
    /// Return a path to the storage location for attachments.
    func getAttachmentsLocation() -> String? {
        return nil
    }
}
