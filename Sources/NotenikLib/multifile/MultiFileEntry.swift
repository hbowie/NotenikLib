//
//  MultiFileEntry.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/19/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Info about a Notenik Collection. 
public class MultiFileEntry {
    
    public var collectionID = ""
    public var filePathKey  = FilePathKey()
    public var link         = NotenikLink()
    public var io:            FileIO?
    
    public var linkStr: String { return link.linkStr }
    
    public init (link: NotenikLink) {
        self.link = link
    }
    
    public init(link: NotenikLink, io: FileIO) {
        self.link = link
        self.io = io
    }
    
    public func establishCollectionID() {
        
        guard collectionID.isEmpty else { return }
        
        if let collection = io?.collection {
            collectionID = collection.shortcut
        }
        
        guard collectionID.isEmpty else { return }
        
        collectionID = link.shortcut
        
        guard collectionID.isEmpty else { return }
        
        if !link.folder.isEmpty {
            let folderCommon = StringUtils.toCommon(link.folder)
            let folderFile = StringUtils.toCommonFileName(link.folder, leavingSlashes: false)
            if link.folder == folderCommon || link.folder == folderFile {
                collectionID = link.folder
            }
        }
    }
    
    public var hasCollectionID: Bool {
        return !collectionID.isEmpty
    }
    
    public func display() {
        print(" ")
        print("MultiFileEntry.display")
        print("Shortcut: \(link.shortcut)")
        print("Path: \(link.path)")
        if io == nil {
            print("I/O module not yet assigned")
        } else {
            print("I/O module open? \(io!.collectionOpen)")
        }
    }
}
