//
//  MultiFileEntry.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/19/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Info about a Notenik Collection. 
public class MultiFileEntry {
    public var link =    NotenikLink()
    public var io:       FileIO?
    
    public init (link: NotenikLink) {
        self.link = link
    }
    
    public init(link: NotenikLink, io: FileIO) {
        self.link = link
        self.io = io
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
