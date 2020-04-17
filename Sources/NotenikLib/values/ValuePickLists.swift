//
//  ValuePickLists.swift
//  Notenik
//
//  Created by Herb Bowie on 7/11/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class ValuePickLists {
    
    public var statusConfig = StatusValueConfig()
    public var tagsPickList = TagsPickList()
    public var authorPickList = AuthorPickList()
    public var workTitlePickList = WorkTitlePickList()
    
    /// Register the relevant values from another Note. 
    func registerNote(note: Note) {
        if note.hasAuthor() {
            authorPickList.registerAuthor(note.author)
        }
        if note.hasTags() {
            tagsPickList.registerTags(note.tags)
        }
        if note.hasWorkTitle() {
            workTitlePickList.registerWork(note)
        }
    }
}
