//
//  TagsTree.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/19.
//
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A tree structure listing notes in a collection by their tags.
class TagsTree {
    
    let root = TagsNode()
    
    let untagged = TagsValue("- untagged")
    
    /// Add a note to the Tags Tree, with one leaf for each Tag that the note possesses
    func add(note: Note) {
        var tags = TagsValue()
        if note.hasTags() {
            tags = note.tags
        } else {
            tags = untagged
        }
        var i = 0
        
        // Process each tag separately
        while i < tags.tags.count {
            let tag = tags.tags[i]
            var node = root
            var j = 0
            while j < tag.levels.count {
                // Now let's work our way up through the tag's levels,
                // adding (or locating) one tag level at a time, working
                // our way deeper into the tree structure as we go.
                let level = tag.levels[j]
                let nextNode = node.addChild(tagLevel: level)
                node = nextNode
                j += 1
            }
            
            // Now that we've worked our way through the tags,
            // Add the note itself to the tree.
            _ = node.addChild(note: note)
            
            // And on to the next tag for this note
            i += 1
        }
    }
    
    /// Delete a note from the tree, wherever it appears
    func delete(note: Note) {
        deleteNoteInChildren (note: note, node: root)
    }
    
    /// Delete child nodes where this Note is found
    func deleteNoteInChildren(note: Note, node: TagsNode) {
        var i = 0
        var deleted = 0
        while i < node.countChildren {
            let child = node.getChild(at: i)
            if child!.type == .note {
                if child!.note!.noteID.commonID == note.noteID.commonID {
                    node.remove(at: i)
                    deleted += 1
                } else {
                    i += 1
                }
            } else {
                deleteNoteInChildren(note: note, node: child!)
                i += 1
            }
        }
        if deleted > 0 && node.countChildren == 0 {
            let parent = node.parent
            if parent != nil {
                var j = 0
                while j < parent!.countChildren {
                    let child = parent!.getChild(at: j)
                    if child! == node {
                        parent!.remove(at: j)
                    } else {
                        j += 1
                    }
                }
            }
        }
    }
    
}
