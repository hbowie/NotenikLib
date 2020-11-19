//
//  WebCollection.swift
//  NotenikLib
//
//  Created by Herb Bowie on 11/14/20.
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A class defining a Website that contains a Notenik Collection, and that is structured in a certain fashion. 
public class WebCollection {
    
    let fileManager = FileManager.default
    
    public var webFolderURL: URL!
    
    let notesFolderName = "notes"
    public var notesFolderURL: URL!
    
    public var io = FileIO()
    public var collection: NoteCollection?
    
    public init (fileURL: URL) {
        webFolderURL = fileURL
        notesFolderURL = webFolderURL.appendingPathComponent(notesFolderName)
    }
    
    /// Attempt to initialize the Notenik Collection and return the result. 
    public func initCollection() -> Bool {
        
        io = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        
        let result = makeNotesFolder()
        guard result != .failure else { return false }

        var ok = io.initCollection(realm: realm, collectionPath: notesFolderURL.path)
        guard ok else { return false }
        
        collection = io.collection
        guard collection != nil else { return false }
        
        // Add the typical fields we would use for a blogging site
        let dict = collection!.dict
        let types = collection!.typeCatalog
        collection!.preferredExt = "md"
        collection!.mirrorAutoIndex = true
        
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.title)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.type)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.tags)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.link)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.seq)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.date)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.status)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.dateAdded)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.timestamp)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.teaser)
        _ = dict.addDef(typeCatalog: types, label: NotenikConstants.body)
        
        collection!.setStatusConfig(NotenikConstants.defaultWebStatusConfig)
        
        ok = io.newCollection(collection: collection!)
        
        guard ok else {
            communicateError("Problems initializing the new collection at " + collection!.fullPath)
            return false
        }
        
        collection = io.collection
        guard collection != nil else { return false }
        
        io.pickLists.statusConfig = collection!.statusConfig
        
        logInfo("New Collection successfully initialized at \(collection!.fullPath)")
        collection!.notesSubFolder = true
        collection!.path = webFolderURL.path
        
        if collection!.mirror != nil {
            communicateError("This Collection already has a functioning mirror folder")
        } else {
            collection!.mirror = NoteTransformer.genSampleMirrorFolder(io: io)
        }
        if collection!.mirror == nil {
            communicateError("Problems encountered trying to generate sample mirror folder")
            return false
        }
        
        return true
    }
    
    public func makeNotesFolder() -> MkDirResults {
        return FileUtils.makeDirectory(at: notesFolderURL)
    }
    
    /// Send info to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "WebCollection",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "WebCollection",
                          level: .error,
                          message: msg)
    }
}
