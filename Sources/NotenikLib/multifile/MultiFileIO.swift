//
//  MultiFileIO.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/19/21.

//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Perform requested lookup operations on the indicated Collection. 
public class MultiFileIO {
    
    public static let shared = MultiFileIO()
    
    // Use a Collection's shortcut as the key for the dictionary.
    public var entries: [String : MultiFileEntry] = [:]
    
    var bookmarks: [MultiFileBookmark] = []
    
    init() {
        
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Manage multi-file entries.
    //
    // -----------------------------------------------------------
    
    /// Register a known Collection with an assigned shortcut.
    public func register(link: NotenikLink) {
        
        guard !link.shortcut.isEmpty else { return }
        let entry = entries[link.shortcut]
        let newEntry = MultiFileEntry(link: link)
        if entry == nil || entry!.link != newEntry.link {
            entries[link.shortcut] = newEntry
        }
    }
    
    /// Register an I/O module for a Collection.
    public func register(link: NotenikLink, io: FileIO) {
        
        guard !link.shortcut.isEmpty else { return }
        let entry = entries[link.shortcut]
        let newEntry = MultiFileEntry(link: link, io: io)
        if entry == nil || entry!.link != newEntry.link {
            entries[link.shortcut] = newEntry
        } else {
            entry!.io = io
        }
    }
    
    /// Attempt to get a Note from the indicated lookup Collection.
    public func getNote(shortcut: String, knownAs vagueID: String) -> Note? {
        guard let io = getFileIO(shortcut: shortcut) else { return nil }
        return io.getNote(knownAs: vagueID)
    }
    
    public func getNotesList(shortcut: String) -> NotesList? {
        guard let io = getFileIO(shortcut: shortcut) else { return nil }
        return io.notesList
    }
    
    /// Get the shared I/O module for the Collection with the indicated shortcut.  If we
    ///  don't already have one, then create one, and open it.
    /// - Parameter shortcut: <#shortcut description#>
    /// - Returns: <#description#>
    public func getFileIO(shortcut: String) -> FileIO? {
        
        // First, see if we can find an entry for the shortcut.
        guard let entry = entries[shortcut] else {
            return nil
        }
        
        // Now let's ensure we have a File Input/Output instance.
        let link = entry.link
        var collection: NoteCollection?
        
        if entry.io != nil && entry.io!.collection != nil && entry.io!.collectionOpen {
            collection = entry.io!.collection!
        } else {
            entry.io = FileIO()
            let realm = entry.io!.getDefaultRealm()
            realm.path = ""
            collection = entry.io!.openCollection(realm: realm, collectionPath: link.path, readOnly: false)
        }
        guard entry.io != nil && collection != nil && entry.io!.collectionOpen else {
            communicateError("Could not open Collection at \(link.path)")
            return nil
        }
        
        return entry.io
    }
    
    /// Either find an open I/O module or create one.
    public func getFileIO(fileURL: URL, readOnly: Bool) -> FileIO? {
        
        // Do we already have an open I/O module?
        for (_, entry) in entries {
            if fileURL.path == entry.link.path {
                if entry.io != nil && entry.io!.collectionOpen {
                    return entry.io
                }
            }
        }
        
        // Nothing open, so let's make one.
        let io = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        var collectionURL: URL
        if FileUtils.isDir(fileURL.path) {
            collectionURL = fileURL
        } else {
            collectionURL = fileURL.deletingLastPathComponent()
        }
        
        let collection = io.openCollection(realm: realm, collectionPath: collectionURL.path, readOnly: readOnly)
        if collection == nil {
            communicateError("Problems opening the collection at " + collectionURL.path)
            return nil
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "MultiFileIO",
                              level: .info,
                              message: "Collection successfully opened: \(collection!.title)")
        }
        if !collection!.shortcut.isEmpty {
            let link = NotenikLink(url: collectionURL, isCollection: true)
            link.shortcut = collection!.shortcut
            register(link: link, io: io)
        }
        return io
    }
    
    public func getLink(shortcut: String) -> NotenikLink? {
        guard let entry = entries[shortcut] else {
            return nil
        }
        return entry.link
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
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "MultiFileIO",
                          level: .error,
                          message: msg)
    }
    
}
