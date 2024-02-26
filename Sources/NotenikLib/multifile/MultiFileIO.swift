//
//  MultiFileIO.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/19/21.

//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Used to manage interactions between two or more collections.
public class MultiFileIO {
    
    /// The singleton instance to be used in all cases.
    public static let shared = MultiFileIO()
    
    var requests = MultiFileRequestStack()
    
    /// Use a Collection's shorthand identifier as the key for the dictionary.
    var shortcutDict: [String: MultiFileEntry] = [:]
    
    /// Use a Collection's folder location as the key for the dictionary.
    var linkDict: [FilePathKey: MultiFileEntry] = [:]
    
    var bookmarks: [MultiFileBookmark] = []
    
    var lookBackTree = LookBackTree()
    
    private init() {

    }
    
    var requestsWorking = false
    
    private func processRequests() {
        guard !requestsWorking else { return }
        requestsWorking = true
        while requests.count > 0 {
            let request = requests[0]!
            switch request.requestType {
            case .populateLookBacks:
                populateLookBacks(request.io)
            case .prepForLookup:
                prepareForLookup(shortcut: request.shortcut, collectionPath: request.collectionPath, realm: request.realm)
            case .undefined:
                break
            }
            requests.removeFirst()
        }
        requestsWorking = false
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Register/Provision/Release Multi File Entries.
    //
    // -----------------------------------------------------------
    
    /// Prepare for later lookups referencing the given collection shortcut.
    public func prepareForLookup(shortcut: String, collectionPath: String, realm: Realm) {

        let entry = shortcutDict[shortcut]
        if entry == nil {
            scanForLookupCollection(shortcut: shortcut, collectionPath: collectionPath, realm: realm)
        } else {
            (_, _) = provision(shortcut: shortcut, inspector: nil, readOnly: false)
        }
    }
    
    public func provision(shortcut: String,
                          inspector: NoteOpenInspector?,
                          readOnly: Bool) -> (NoteCollection?, FileIO) {
        
        guard let entry = shortcutDict[shortcut] else {
            return (nil, FileIO())
        }
        return provision(collectionPath: entry.linkStr,
                         inspector: inspector,
                         readOnly: readOnly)
    }
    
    public func provision(fileURL: URL,
                          inspector: NoteOpenInspector?,
                          readOnly: Bool) -> (NoteCollection?, FileIO) {
        
        var collectionURL: URL?
        if FileUtils.isDir(fileURL.path) {
            collectionURL = fileURL
        } else {
            collectionURL = fileURL.deletingLastPathComponent()
        }
        
        return provision(collectionPath: collectionURL!.path,
                         inspector: inspector,
                         readOnly: readOnly)
    }
    
    /// Return a functioning I/O module for this Collection.
    /// - Parameters:
    ///   - collectionPath: The path to the Collection.
    ///   - inspector: Any desired Note inspector.
    ///   - readOnly: Read-only access?
    /// - Returns: The Collection, if successfully opened, and the I/O module.
    public func provision(collectionPath: String,
                          inspector: NoteOpenInspector?,
                          readOnly: Bool) -> (NoteCollection?, FileIO) {
        
        let io = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        
        if readOnly {
            return (io.openCollection(realm: realm, collectionPath: collectionPath, readOnly: readOnly), io)
        }
        
        let filePathKey = FilePathKey(str: collectionPath)
        
        if linkDict.keys.contains(filePathKey) {
            if let existingIO = linkDict[filePathKey]!.io {
                if existingIO.collectionOpen && existingIO.collection != nil {
                    return (existingIO.collection, existingIO)
                } else {
                    // print("  - I/O module found but not opened")
                }
            } else {
                // print("  - Existing I/O module not found!")
            }
        } else {
            // print("  - File Path Key could not be found!")
        }
        

        if inspector != nil {
            io.setInspector(inspector!)
        }
        let collection: NoteCollection? = io.openCollection(realm: realm,
                                                            collectionPath: filePathKey.key,
                                                            readOnly: readOnly,
                                                            multiRequests: requests)
        
        if collection != nil {
            if let url = collection!.fullPathURL {
                let link = NotenikLink(url: url, isCollection: true)
                let entry = MultiFileEntry(link: link, io: io)
                entry.establishCollectionID()
                entry.filePathKey = FilePathKey(str: collectionPath)
                register(entry: entry)
            }
        }
        
        processRequests()
        
        return (collection, io)
    }
    
    /// Register a known Collection with an assigned shortcut.
    public func register(link: NotenikLink) {
        
        let entry = MultiFileEntry(link: link)
        entry.establishCollectionID()
        entry.filePathKey = FilePathKey(str: entry.linkStr)
        
        if linkDict.keys.contains(entry.filePathKey) {
            linkDict[entry.filePathKey]!.link = link
            if entry.hasCollectionID {
                linkDict[entry.filePathKey]!.collectionID = entry.collectionID
            }
        } else {
            linkDict[entry.filePathKey] = entry
        }
        
        if entry.hasCollectionID {
            shortcutDict[entry.collectionID] = linkDict[entry.filePathKey]
        }
    }
    
    /// Register an I/O module for a Collection.
    public func register(link: NotenikLink, io: FileIO) {
        
        let entry = MultiFileEntry(link: link, io: io)
        entry.establishCollectionID()
        entry.filePathKey = FilePathKey(str: entry.linkStr)
        
        if linkDict.keys.contains(entry.filePathKey) {
            linkDict[entry.filePathKey]!.io = io
            if entry.hasCollectionID && entry.collectionID != linkDict[entry.filePathKey]!.collectionID {
                linkDict[entry.filePathKey]!.collectionID = entry.collectionID
            }
        } else {
            register(entry: entry)
        }
    }
    
    private func register(entry: MultiFileEntry) {
        if entry.hasCollectionID {
            shortcutDict[entry.collectionID] = entry
        }
        linkDict[entry.filePathKey] = entry
    }
    
    /// Close the collection if it appears not to be used anywhere else;
    /// if it might be in use elsewhere then save some files but
    /// leave the I/O module open.
    /// - Parameter io: The I/O module in question.
    public func closeCollection(io: FileIO) {
        guard let collection = io.collection else { return }
        guard io.collectionOpen else { return }
        guard !collection.readOnly else {
            io.closeCollection()
            return
        }
        let filePathKey = FilePathKey(str: collection.path)
        guard let entry = linkDict[filePathKey] else {
            io.closeCollection()
            return
        }
        guard entry.hasCollectionID else {
            io.closeCollection()
            return
        }
        
        _ = io.saveInfoFile()
        _ = io.aliasList.saveToDisk()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Manage multi-file entries.
    //
    // -----------------------------------------------------------
    
    /// Look for the given shortcut, first in collection subfolders, then in collection peers, beneath the same parent. 
    func scanForLookupCollection(shortcut: String, collectionPath: String, realm: Realm) {
        var shortcutFound = scanFolder(shortcut: shortcut, folderPath: collectionPath, realm: realm)
        if !shortcutFound {
            let collectionURL = URL(fileURLWithPath: collectionPath)
            let parentURL = collectionURL.deletingLastPathComponent()
            shortcutFound = scanFolder(shortcut: shortcut, folderPath: parentURL.path, realm: realm)
        }
    }
    
    /// Scan folders recursively looking for signs that they are Notenik Collections
    private func scanFolder(shortcut: String, folderPath: String, realm: Realm) -> Bool {
        var shortcutFound = false
        do {
            let dirContents = try FileManager.default.contentsOfDirectory(atPath: folderPath)
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: folderPath,
                                                       path2: itemPath)
                if itemPath == ResourceFileSys.infoFileName {
                    shortcutFound = infoFileFound(shortcut: shortcut, folderPath: folderPath, itemFullPath: itemFullPath, realm: realm)
                    if shortcutFound {
                        break
                    }
                } else if itemPath == ResourceFileSys.infoParentFileName {
                    // No action needed
                } else if itemPath.hasPrefix(".") {
                    // Ignore invisible files
                } else if itemPath.hasSuffix(".app") {
                    // Ignore application bundles
                } else if itemPath.hasSuffix(".dmg") {
                    // Ignore disk image bundles
                } else if FileUtils.isDir(itemFullPath) {
                    shortcutFound = scanFolder(shortcut: shortcut, folderPath: itemFullPath, realm: realm)
                }
            }
        } catch {
            communicateError("Failed reading contents of folder at '\(folderPath)'")
        }
        return shortcutFound
    }
    
    /// See if the collection containing the info file is one identified by the given shortcut.
    func infoFileFound(shortcut: String, folderPath: String, itemFullPath: String, realm: Realm) -> Bool {
        var shortcutFound = false
        let folderURL = URL(fileURLWithPath: folderPath)
        let infoIO = FileIO()
        let initOK = infoIO.initCollection(realm: realm, collectionPath: folderPath, readOnly: true)
        if initOK {
            if infoIO.collection != nil {
                _ = infoIO.loadInfoFile()
                if infoIO.collection!.shortcut == shortcut {
                    let folderLink = NotenikLink(url: folderURL, isCollection: true)
                    register(link: folderLink)
                    shortcutFound = true
                } else if infoIO.collection!.shortcut.isEmpty && folderURL.lastPathComponent == shortcut {
                    let folderLink = NotenikLink(url: folderURL, isCollection: true)
                    register(link: folderLink)
                    shortcutFound = true
                }
            } else {
                communicateError("Unable to initialize Collection located at \(folderPath)")
            }
        } else {
            communicateError("Unable to initialize Collection located at \(folderPath)")
        }
        return shortcutFound
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Manage lookbacks.
    //
    // -----------------------------------------------------------
    
    /// See if the passed I/O module is for a Collection with any fields of type lookback.
    /// If it is, then build the list of lookbacks from the lookups in another collection.
    /// - Parameter io: The I/O module for the Collection to be looked back from. 
    public func populateLookBacks(_ lkBkIO: FileIO) {
        guard let lkBkCollection = lkBkIO.collection else { return }
        let lkBkCollectionID = lkBkCollection.collectionID
        guard !lkBkCollection.lookBackDefs.isEmpty else { return }
        logInfo(msg: "Populating \(lkBkCollection.lookBackDefs.count) lookbacks for Collection identified as \(lkBkCollectionID)")
        for lkBkDef in lkBkCollection.lookBackDefs {
            let lkUpCollectionID = lkBkDef.lookupFrom
            lookBackTree.requestLookbacks(collectionID: lkUpCollectionID)
            let (lkUpCollection, lkUpIO) = provision(shortcut: lkUpCollectionID, inspector: nil, readOnly: false)
            if lkUpCollection != nil {
                let lkUpDict = lkUpCollection!.dict
                var lkUpDef: FieldDefinition?
                var i = 0
                var found = false
                while i < lkUpDict.count && !found {
                    if let checkDef = lkUpDict[i] {
                        if checkDef.fieldType.typeString == NotenikConstants.lookupType
                            && checkDef.lookupFrom == lkBkCollectionID {
                            lookBackTree.requestLookbacks(lkUpCollectionID: lkUpCollectionID,
                                                          lkUpFieldLabel: checkDef.fieldLabel.commonForm,
                                                          lkBkCollectionID: lkBkCollectionID,
                                                          lkBkFieldLabel: lkBkDef.fieldLabel.commonForm)
                            lkUpDef = checkDef
                            found = true
                        } else {
                            i += 1
                        }
                    }
                }
                
                if found {
                    for lkUpNote in lkUpIO.notesList {
                        if let lkUpField = lkUpNote.getField(def: lkUpDef!) {
                            let lkUpValue = StringUtils.toCommon(lkUpField.value.value)
                            lookBackTree.registerLookup(lkUpCollectionID: lkUpCollectionID, 
                                                        lkUpNoteIdCommon: lkUpNote.noteID.commonID,
                                                        lkUpNoteIdText: lkUpNote.noteID.text,
                                                        lkUpFieldLabel: lkUpDef!.fieldLabel.commonForm,
                                                        lkBkCollectionID: lkBkCollectionID,
                                                        lkBkFieldLabel: lkBkDef.fieldLabel.commonForm,
                                                        lkUpValue: lkUpValue)
                        }
                    }
                }
            } else {
                communicateError("Look back collection identified by \(lkBkDef.lookupFrom) could not be found")
            }
        }
    }
    
    /// Register all the lookups in this note, for use by lookbacks in another collection.
    /// - Parameter lkUpNote: A new note whose lookups are to be registered for later lookbacks.
    func registerLookBacks(lkUpNote: Note) {
        lookBackTree.registerLookBacks(lkUpNote: lkUpNote)
    }
    
    /// Cancel all the lookups in this note
    /// - Parameter lkUpNote: The note containing the lookbacks to be canceled. 
    func cancelLookBacks(lkUpNote: Note) {
        lookBackTree.cancelLookBacks(lkUpNote: lkUpNote)
    }
    
    /// Get all the lookback lines for this Note and the indicated field.
    /// - Parameters:
    ///   - collectionID: Identifying the lookback collection.
    ///   - noteID: Identifying the lookback note.
    ///   - lkBkCommonLabel: Identifying the lookback field.
    /// - Returns: An array of lookback lines. 
    func getLookBackLines(collectionID: String, noteID: String, lkBkCommonLabel: String) -> [LookBackLine] {
        return lookBackTree.getLookBackLines(collectionID: collectionID,
                                             noteID: noteID,
                                             lkBkCommonLabel: lkBkCommonLabel)
    }
    
    
    
    public func getEntry(shortcut: String) -> MultiFileEntry? {
        return shortcutDict[shortcut]
    }
    
    /// Attempt to get a Note from the indicated lookup Collection.
    public func getNote(shortcut: String, knownAs vagueID: String) -> Note? {
        let (collection, io) = provision(shortcut: shortcut, inspector: nil, readOnly: false)
        guard collection != nil else { return nil }
        return io.getNote(knownAs: vagueID)
    }
    
    public func getNotesList(shortcut: String) -> NotesList? {
        let (collection, io) = provision(shortcut: shortcut, inspector: nil, readOnly: false)
        guard collection != nil else { return nil }
        return io.notesList
    }
    
    public func getLink(shortcut: String) -> NotenikLink? {
        guard let entry = shortcutDict[shortcut] else {
            return nil
        }
        return entry.link
    }
    
    public func displayShortcuts() {
        print(" ")
        print("MultiFileIO.display Shortcuts")
        for (key, entry) in shortcutDict {
            print("  - id = \(key), path = \(entry.link.path)")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Manage bookmarks.
    //
    // -----------------------------------------------------------
    
    
    /// Register a bookmark for a URL that the user has just granted us permission
    /// to open.
    /// - Parameter url: The folder that the user wishes to open.
    public func registerBookmark(url: URL) {
        let bookmark = MultiFileBookmark(url: url, source: .fromSession)
        do {
            bookmark.data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            addBookmark(bookmark: bookmark)
        } catch {
            communicateError("Couldn't generate bookmark data for url \(url)")
        }
    }
    
    /// Associate a URL's bookmark with the folder's assigned shortcut.
    /// - Parameters:
    ///   - url: The URL of a Collection folder with an assigned shortcut.
    ///   - shortcut: The shortcut assigned to the Collection folder.
    public func stashBookmark(url: URL, shortcut: String) {
        guard !shortcut.isEmpty else { return }
        let path = url.path
        for bookmark in bookmarks {
            if (path.starts(with: bookmark.path) || path == bookmark.path) && bookmark.source == .fromSession {
                UserDefaults.standard.set(bookmark.data!, forKey: "bookmark-for-\(shortcut)")
                return
            }
        }
    }
    
    /// Secure access to the identified Collection, if we need to, and if we have a bookmark stashed.
    /// - Parameters:
    ///   - shortcut: The shortcut assigned to the Collection.
    ///   - url: The URL pointing to the Collection. 
    public func secureAccess(shortcut: String, url: URL) {
        guard !shortcut.isEmpty else { return }
        let path = url.path
        for bookmark in bookmarks {
            if path.starts(with: bookmark.path) || path == bookmark.path {
                return
            }
        }
        
        // If the URL is already reachable, then let's not mess with any further.
        do {
            let reachable = try url.checkResourceIsReachable()
            if reachable {
                return
            }
        } catch {
            communicateError("Error caught while checking reachability for \(url)")
        }
        
        // Try to make it reachable using stashed bookmark data.
        if let bookmarkData = UserDefaults.standard.data(forKey: "bookmark-for-\(shortcut)") {
            do {
                var stale = false
                let stashedURL = try URL(resolvingBookmarkData: bookmarkData,
                                         options: .withSecurityScope,
                                         relativeTo: nil,
                                         bookmarkDataIsStale: &stale)
                if stale {
                    communicateError("bookmark is stale for shortcut \(shortcut)")
                } else {
                    let ok = stashedURL.startAccessingSecurityScopedResource()
                    if !ok {
                        communicateError("Attempt to start accessing returned false for shortcut \(shortcut)")
                    } else {
                        let bookmark = MultiFileBookmark(url: url, source: .fromStash)
                        addBookmark(bookmark: bookmark)
                    }
                }
            } catch {
                communicateError("Could not resolve bookmark data for shortcut \(shortcut)")
            }
        }
    }
    
    public func stopAccess(url: URL) {
        let path = url.path
        var index = 0
        while index < bookmarks.count {
            let bookmark = bookmarks[index]
            if path == bookmark.path {
                if bookmark.source == .fromStash {
                    bookmark.url.stopAccessingSecurityScopedResource()
                    bookmarks.remove(at: index)
                }
                break
            }
            index += 1
        }
    }
    
    func addBookmark(bookmark: MultiFileBookmark) {
        var index = 0
        while index < bookmarks.count && bookmark.path > bookmarks[index].path {
            index += 1
        }
        if index >= bookmarks.count {
            bookmarks.append(bookmark)
        } else if bookmark.path == bookmarks[index].path {
            bookmarks[index] = bookmark
        } else {
            bookmarks.insert(bookmark, at: index)
        }
    }
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "MultiFileIO",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "MultiFileIO",
                          level: .error,
                          message: msg)
    }
    
}
