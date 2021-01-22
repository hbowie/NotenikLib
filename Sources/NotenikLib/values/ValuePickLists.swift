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
    public var workTitlePickList = WorkTitlePickList()
    
    /// Register the relevant values from another Note. 
    func registerNote(note: Note) {
        if note.hasTags() {
            tagsPickList.registerTags(note.tags)
        }
        if note.hasWorkTitle() {
            workTitlePickList.registerWork(note)
        }
        
        for def in note.collection.pickLists {
            guard let list = def.pickList else { continue }
            guard let field = note.getField(def: def) else { continue }
            if let authors = def.pickList as? AuthorPickList, let author = field.value as? AuthorValue {
                authors.registerAuthor(author)
                continue
            }
            list.registerValue(field.value)
        }
    }
}
