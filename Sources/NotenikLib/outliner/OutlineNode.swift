//
//  OutlineNode.swift
//  NotenikLib
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 12/21/23.
//

import Foundation

public class OutlineNode {
    
    // Getter and Setter for Note.
    var note: Note? {
        get {
            return _note
        }
        set {
            _note = newValue
            if _note != nil {
                level = _note!.depth
            } else {
                level = 0
            }
        }
    }
    var _note: Note?
    
    // Level in hierarchy as indicated by level and/or seq fields.
    var level = 0
    
    // Depth in actual outline hierarchy built by this class,
    // where 0 is the topmost.
    var depth = -1
    
    // Parent of this node.
    var parent:         OutlineNode? {
        get {
            return _parent
        }
        set {
            _parent = newValue
            if _parent != nil {
                _parent!.children.append(self)
            }
        }
    }
    var _parent:        OutlineNode?
    
    public var hasParent: Bool {
        return _parent != nil
    }
    
    // Children of this node.
    var children:       [OutlineNode] = []
    
    public var hasChildren: Bool {
        return !children.isEmpty
    }
    
    public var firstChild: OutlineNode? {
        if children.isEmpty {
            return nil
        } else {
            return children[0]
        }
    }
    
    // Prior Sibling
    var priorSibling:   OutlineNode? {
        get {
            return _priorSibling
        }
        set {
            _priorSibling = newValue
            if _priorSibling != nil {
                _priorSibling!.nextSibling = self
            }
        }
    }
    var _priorSibling:  OutlineNode?
    
    // Next sibling
    public var nextSibling:    OutlineNode?
    
    public var hasNextSibling: Bool {
        return nextSibling != nil
    }
    
    public init() {
        
    }
    
    public func nextNode(childrenExhausted: Bool) -> OutlineNode? {
        if hasChildren && !childrenExhausted {
            return firstChild
        } else if hasNextSibling {
            return nextSibling
        } else if hasParent {
            return _parent!.nextNode(childrenExhausted: true)
        } else {
            return nil
        }
    }
    
    public func display() {
        print(" ")
        print("OutlineNode.display")
        if note != nil {
            print("  - Note Title: \(note!.title.value)")
            print("    - Note Seq: \(note!.seq.value)")
            print("    - Note Level: \(note!.level.value)")
        }
        print("  - Level: \(level)")
        print("  - Depth: \(depth)")
        if hasParent {
            print("  - Parent: \(parent!.note!.title.value)")
        }
        if hasChildren {
            if children.count == 1 {
                print("  - Has one Child")
            } else {
                print("  - Has \(children.count) Children")
            }
        }
        if priorSibling != nil {
            print("  - Prior Sibling: \(priorSibling!.note!.title.value)")
        }
        if hasNextSibling {
            print("  - Next Sibling: \(nextSibling!.note!.title.value)")
        }
    }

}
