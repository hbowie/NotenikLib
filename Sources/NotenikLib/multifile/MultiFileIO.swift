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
    
    var entries: [String : MultiFileEntry] = [:]
    
    init() {
        
    }
    
    public func register(collection: NoteCollection) {
        guard !collection.shortcut.isEmpty else { return }
    }
    
    /// Register a known Collection with an assigned shortcut.
    public func register(link: NotenikLink) {
        
        guard !link.shortcut.isEmpty else { return }
        let entry = entries[link.shortcut]
        if entry == nil {
            let newEntry = MultiFileEntry(link: link)
            entries[link.shortcut] = newEntry
        }
        
    }
    
    /// Register an I/O module for a Collection.
    public func register(link: NotenikLink, io: FileIO) {
        
        guard !link.shortcut.isEmpty else { return }
        let entry = entries[link.shortcut]
        if entry == nil {
            let newEntry = MultiFileEntry(link: link, io: io)
            entries[link.shortcut] = newEntry
        } else {
            entry!.io = io
        }
        
    }
    
    /// Attempt to get a Note from the indicated lookup Collection.
    public func getNote(shortcut: String, forID id: String) -> Note? {
        guard let io = getFileIO(shortcut: shortcut) else { return nil }
        let commonID = StringUtils.toCommon(id)
        return io.getNote(forID: commonID)
    }
    
    public func getNotesList(shortcut: String) -> NotesList? {
        guard let io = getFileIO(shortcut: shortcut) else { return nil }
        return io.notesList
    }
    
    public func getFileIO(shortcut: String) -> FileIO? {
        
        // First, see if we can find an entry for the shortcut.
        guard let entry = entries[shortcut] else {
            print("Shortcut \(shortcut) could not be found!")
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
            print("Could not open Collection at \(link.path)")
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
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "MultiFileIO",
                          level: .error,
                          message: msg)
    }
    
}
