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
    
    public init() {

    }
    
    public func add(sortedNotes: [SortedNote]) {
        for sortedNote in sortedNotes {
            _ = add(sortedNote: sortedNote)
        }
    }
    
    /// Add a note to the Outline Tree.
    func add(sortedNote: SortedNote) -> OutlineNode2? {
        let node = OutlineNode2()
        node.sortedNote = sortedNote
        return add(node: node)
    }
    
    func add(node: OutlineNode2) -> OutlineNode2? {
        if collection == nil && node.sortedNote != nil {
            grabCollectionInfo(node.sortedNote!.note)
        }
        guard outlineTreeEnabled else { return nil }
        return root.addChild(node: node)
    }
    
    func delete(sortedNotes: [SortedNote]) {
        for sortedNote in sortedNotes {
            _ = delete(sortedNote: sortedNote)
        }
    }
    
    /// Delete a note from the tree, wherever it appears
    func delete(sortedNote: SortedNote) -> OutlineNode2? {
        return root.removeChild(sortedNote: sortedNote)
    }
    
    var isEmpty: Bool {
        return root.children.isEmpty
    }
    
    func grabCollectionInfo(_ note: Note) {
        collection = note.collection
        hasLevel = (collection!.levelFieldDef != nil)
        hasSeq = (collection!.seqFieldDef != nil)
        if collection!.outlineTabSetting.isEnabled {
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
