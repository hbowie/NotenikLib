//
//  NotenikFolderIterator.swift
//
//  Created by Herb Bowie on 8/26/20.

//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An object capable of iterating through a Notenik Folder List.
public class NotenikFolderIterator: IteratorProtocol {
    
    var list: NotenikFolderList
    var index = 0
    
    init(_ list: NotenikFolderList) {
        self.list = list
    }
        
    /// Return the next Notenik Folder or nil at end of list.
    public func next() -> NotenikLink? {
        if index < list.count {
            let folder = list[index]
            index += 1
            return folder
        } else {
            return nil
        }
    }
}
