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
    
    var entries: [String: MultiFileEntry] = [:]
    
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
    
}
