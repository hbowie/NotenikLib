//
//  NoteCollector.swift
//
//  Created by Herb Bowie on 11/9/20.

//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class NoteCollector: NoteOpenInspector {
    
    public var notes: [Note] = []
    
    public init() {
        
    }
    
    /// Inspect each note as its being opened to see if we want to do anything with it.
    public func inspect(_ note: Note) {
        let tags = note.tags
        for tag in tags.tags {
            if tag.levels.count >= 1 && tag.levels[0].text == "Launch at Startup" {
                notes.append(note)
            }
        }
    }
    
    public func sort() {
        notes.sort()
    }

}
