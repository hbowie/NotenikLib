//
//  NotenikIO.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// Read and write notes from/to some sort of data store. 
public protocol NotenikIO {
    
    // -----------------------------------------------------------
    //
    // MARK: Variables required by NotenikIO
    //
    // -----------------------------------------------------------
    
    /// The currently open collection, if any
    var collection: NoteCollection? { get }
    
    /// The position of the selected note, if any, in the current collection
    var position:   NotePosition? { get }
    
    /// An indicator of the status of the Collection: open or closed
    var collectionOpen: Bool { get }
    
    /// A list of reports available for the currently open Collection. 
    var reports: [MergeReport] { get }
    
    /// A list of export scripts availabe for the currently open Collection.
    var exportScripts: [ExportScript] { get }
    
    /// A list of notes in the Collection.
    var notesList: NotesList { get }
    
    /// The number of notes in the current collection
    var notesCount: Int { get }
    
    var pickLists: ValuePickLists { get }
    
    /// Get or Set the NoteSortParm for this collection.
    var sortParm: NoteSortParm { get set }
    
    /// Should the list be in descending sequence?
    var sortDescending: Bool { get set }
    
    /// Should blank dates be sorted last, or first?
    var sortBlankDatesLast: Bool { get set }
    
    var aliasList: AliasList { get }
    
    // -----------------------------------------------------------
    //
    // MARK: Initializers
    //
    // -----------------------------------------------------------
    
    /// Provide an inspector that will be passed each Note as a Collection is opened.
    func setInspector(_ inspector: NoteOpenInspector)
    
    /// Attempt to initialize the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: True if successful, false otherwise.
    func initCollection(realm: Realm, collectionPath: String, readOnly: Bool) -> Bool
    
    /// Add the default definitions to the Collection's dictionary:
    /// Title, Tags, Link and Body
    func addDefaultDefinitions()
    
    // -----------------------------------------------------------
    //
    // MARK: Accessors providing info to other classes
    //
    // -----------------------------------------------------------
    
    /// Get information about the provider.
    func getProvider() -> Provider
    
    /// Get the default realm.
    func getDefaultRealm() -> Realm
    
    // -----------------------------------------------------------
    //
    // MARK: Create and Save Routines
    //
    // -----------------------------------------------------------

    /// Open a New Collection
    func newCollection(collection: NoteCollection, withFirstNote: Bool) -> Bool
    
    /// Stash Notenik special files into a special subfolder.
    func stashNotenikFilesInSubfolder() 
    
    /// Save some of the collection info to make it persistent
    func persistCollectionInfo()
    
    // -----------------------------------------------------------
    //
    // MARK: Open and Close routines
    //
    // -----------------------------------------------------------
    
    /// Attempt to open the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened. 
    /// - Parameter path: The path identifying the collection within this
    /// - Returns: A NoteCollection object, if the collection was opened successfully;
    ///            otherwise nil.
    func openCollection(realm: Realm,
                        collectionPath: String,
                        readOnly: Bool,
                        multiRequests: MultiFileRequestStack?) -> NoteCollection?
    
    /// Close the currently collection, if one is open
    func closeCollection()
    
    /// Open a Collection to be used as an archive for another Collection. This will
    /// be a normal open, if the archive has already been created, or will create
    /// a new Collection, if the Archive is being accessed for the first time.
    ///
    /// - Parameters:
    ///   - primeIO: The I/O module for the primary collection.
    ///   - archivePath: The location of the archive collection.
    /// - Returns: The Archive Note Collection, if collection opened successfully.
    func openArchive(primeIO: NotenikIO, archivePath: String) -> NoteCollection?
    
    // -----------------------------------------------------------
    //
    // MARK: Attachments
    //
    // -----------------------------------------------------------
    
    /// Add the specified attachment to the given note.
    ///
    /// - Parameters:
    ///   - from: The location of the file to be attached.
    ///   - to: The Note to which the file is to be attached.
    ///   - with: The unique identifier for this attachment for this note.
    ///   - move: Should the file be moved instead of copied?
    /// - Returns: True if attachment added successfully, false if any sort of failure.
    func addAttachment(from: URL, to: Note, with: String, move: Bool) -> Bool
    
    /// Reattach the attachments for this note to make sure they are attached
    /// to the new note.
    ///
    /// - Parameters:
    ///   - note1: The Note to which the files were previously attached.
    ///   - note2: The Note to wich the files should now be attached.
    /// - Returns: True if successful, false otherwise.
    func reattach(from: Note, to: Note) -> Bool
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(attachmentName: AttachmentName) -> URL?
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(fileName: String) -> URL?
    
    // -----------------------------------------------------------
    //
    // MARK: Load Reports.
    //
    // -----------------------------------------------------------
    
    /// Load the list of reports available for this collection. 
    func loadReports()
    
    // -----------------------------------------------------------
    //
    // MARK: Load Export Scripts.
    //
    // -----------------------------------------------------------
    
    /// Load the list of export scripts available for this collection.
    func loadExportScripts()
    
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
    func modNote(oldNote: Note, newNote: Note) -> (Note?, NotePosition)
    
    /// Add a new Note to the Collection
    ///
    /// - Parameter newNote: The Note to be added
    /// - Returns: The added Note and its position, if added successfully;
    ///            otherwise nil and -1.
    func addNote(newNote: Note) -> (Note?, NotePosition)
    
    /// Write a note to its data store within its collection.
    ///
    /// - Parameter note: The Note to be saved.
    /// - Returns: True if saved successfully, false otherwise.
    func writeNote(_ note: Note) -> Bool
    
    /// Check for uniqueness and, if necessary, Increment the suffix
    /// for this Note's ID until it becomes unique.
    func ensureUniqueID(for note: Note)
    
    /// Delete the currently selected Note, plus any attachments it might have.
    ///
    /// - Returns: The new Note on which the collection should be positioned.
    func deleteSelectedNote(preserveAttachments: Bool) -> (SortedNote?, NotePosition)
    
    /// Delete the given note
    ///
    /// - Parameter oldNote: The note to be deleted.
    /// - Returns: True if delete was successful, false otherwise.
    func deleteNote(_ oldNote: Note, preserveAttachments: Bool) -> Bool
    
    /// Reload the note in memory from the backing data store.
    func reloadNote(_ noteToReload: Note) -> Note?
    
    /// Register a new Combo Value. 
    func registerComboValue(comboDef: FieldDefinition, value: String)
    
    // -----------------------------------------------------------
    //
    // MARK: Access Notes
    //
    // -----------------------------------------------------------
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    func firstNote() -> (SortedNote?, NotePosition)
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    func lastNote() -> (SortedNote?, NotePosition)
    
    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the next note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then return a nil Note and an index of -1.
    func nextNote(_ position: NotePosition) -> (SortedNote?, NotePosition)
    
    /// Return the prior note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note accessed.
    /// - Returns: A tuple containing the prior note, along with its index position.
    ///            if we're outside the bounds of the list, then return a nil Note and an index of -1.
    func priorNote(_ position: NotePosition) -> (SortedNote?, NotePosition)
    
    /// Return the position of a given note.
    ///
    /// - Parameter note: The note to find.
    /// - Returns: A Note Position
    func positionOfNote(_ note: Note) -> NotePosition
    
    
    /// Return the position of a given sorted note.
    /// - Parameter note: A Sorted Note entry.
    /// - Returns: The position within the master list. 
    func positionOfNote(_ sortedNote: SortedNote) -> NotePosition
    
    /// Select the note at the given position in the sorted list.
    ///
    /// - Parameter index: An index value pointing to a position in the list.
    /// - Returns: A tuple containing the indicated note, along with its index position.
    ///            - If the list is empty, return nil and -1.
    ///            - If the index is too high, return the last note.
    ///            - If the index is too low, return the first note.
    func selectNote(at index: Int) -> (SortedNote?, NotePosition)
    
    /// Return the note currently selected.
    ///
    /// If no note is selected, return a nil Note and an index posiiton of -1.
    func getSelectedNote() -> (SortedNote?, NotePosition)
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at: Int) -> Note?
    
    /// Return the Sorted Note  at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getSortedNote(at: Int) -> SortedNote?
    
    /// Get the Note that is known by the passed identifier, one way or another.
    /// - Returns: The matching Note, if one could be found. 
    func getNote(knownAs: String) -> Note?
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    func getNote(forID noteID: NoteIdentification) -> Note?
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    func getNote(forID id: String) -> Note?
    
    /// Get the existing note with the specified timestamp, if one exists.
    /// - Parameter stamp: The timestamp we are looking for.
    /// - Returns: The Note with this timestamp, if one exists; otherwise nil.
    func getNote(forTimestamp stamp: String) -> Note?
    
    /// Get the existing Note with the specified AKA value, if one exists.
    /// - Parameter alsoKnownAs: The AKA value we are looking for. 
    /// - Returns: The Note having this aka value, if one exists; otherwise nil.
    func getNote(alsoKnownAs: String) -> Note?
    
    /// Return the Alias entries for the Collection.
    /// - Returns: All of the AKA aliases, plus the Notes to which they point. 
    func getAKAEntries() -> AKAentries
    
    // -----------------------------------------------------------
    //
    // MARK: Obtain info about the Collection.
    //
    // -----------------------------------------------------------
    
    /// Return the total number of Notes in the Collection.
    var count: Int { get }
    
    // -----------------------------------------------------------
    //
    // MARK: Import new Notes into the Collection
    //
    // -----------------------------------------------------------
    
    /// Import Notes from a CSV or tab-delimited file
    ///
    /// - Parameter importer: A Row importer that will return rows and columns.
    /// - Parameter fileURL: The URL of the file to be imported.
    /// - Parameter importParms: Parameters to control the operation of the import. 
    /// - Returns: The number of rows added, the number of rows modified.
    func importRows(importer: RowImporter, fileURL: URL, importParms: ImportParms) -> (Int, Int)
    
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
    func purgeClosed(archiveIO: NotenikIO?) -> Int
    
    // -----------------------------------------------------------
    //
    // MARK: Access the Tags
    //
    // -----------------------------------------------------------
    
    /// Return the root of the Tags tree
    func getTagsNodeRoot() -> TagsNode?
    
    /// Create an iterator for the tags nodes.
    func makeTagsNodeIterator() -> TagsNodeIterator
    
    // -----------------------------------------------------------
    //
    // MARK: Access the Outline based on Seq values. 
    //
    // -----------------------------------------------------------
    
    /// Return the root of the Tags tree
    func getOutlineNodeRoot() -> OutlineNode2?
    
    /// Create an iterator for the tags nodes.
    func makeOutlineNodeIterator() -> OutlineNodeIterator
    
    // -----------------------------------------------------------
    //
    // MARK: Lookup Class based on Level
    //
    // -----------------------------------------------------------
    
    func klassForLevel(_ level: Int) -> String?
    
    func levelForKlass(_ klass: String) -> Int?
}

