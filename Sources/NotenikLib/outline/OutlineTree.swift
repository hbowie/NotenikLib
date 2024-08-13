//
//  OutlineTree.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/4/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class OutlineTree: Sequence {
    
    let root = OutlineNode2()
    
    var collection: NoteCollection?
    var hasLevel = false
    public var hasSeq = false
    var hasLevelAndSeq: Bool {
        return hasLevel && hasSeq
    }
    
    var outlineTreeEnabled = false
    
    /// Add a note to the Outline Tree.
    func add(note: Note) -> OutlineNode2? {
        let node = OutlineNode2()
        node.note = note
        return add(node: node)
    }
    
    func add(node: OutlineNode2) -> OutlineNode2? {
        if collection == nil && node.note != nil {
            grabCollectionInfo(node.note!)
        }
        guard outlineTreeEnabled else { return nil }
        return root.addChild(node: node)
    }
    
    /// Delete a note from the tree, wherever it appears
    func delete(note: Note) -> OutlineNode2? {
        return root.removeChild(note: note)
    }
    
    var isEmpty: Bool {
        return root.children.isEmpty
    }
    
    func grabCollectionInfo(_ note: Note) {
        collection = note.collection
        hasLevel = (collection!.levelFieldDef != nil)
        hasSeq = (collection!.seqFieldDef != nil)
        if collection!.outlineTab {
            outlineTreeEnabled = true
        }
    }
    
    public func makeIterator() -> OutlineNodeIterator {
        return OutlineNodeIterator(root: root)
    }
    
    func display() {
        print("OutlineTree.display")
        print("  - has seq? \(hasSeq)")
        root.display(numberOfParents: 0)
    }
}
