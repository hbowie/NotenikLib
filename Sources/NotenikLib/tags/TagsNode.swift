//
//  TagsNode.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/19.

//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A single node in the Tags Tree.
public class TagsNode: Comparable, CustomStringConvertible, Hashable {
    
    static let thisLessThanThat = -1
    static let thisGreaterThanThat = 1
    static let thisEqualsThat = 0
    
    public static func < (lhs: TagsNode, rhs: TagsNode) -> Bool {
        return lhs.compareTo(node2: rhs) < 0
    }
    
    public static func == (lhs: TagsNode, rhs: TagsNode) -> Bool {
        return lhs.compareTo(node2: rhs) == 0
    }
    
    public private(set) var parent:   TagsNode?
    public private(set) var children: [TagsNode] = []
    public              var type:     TagsNodeType = .root
    public              var tag:      TagLevel?
    public              var note:     Note?
    
    public var hasParent: Bool {
        return (parent != nil)
    }
    
    init() {
        
    }
    
    convenience init(tag: TagLevel) {
        self.init()
        type = .tag
        self.tag = tag
    }
    
    convenience init(tag: String) {
        self.init()
        type = .tag
        self.tag = TagLevel(tag)
    }
    
    convenience init(note: Note) {
        self.init()
        type = .note
        self.note = note
    }
    
    public var description: String {
        switch type {
        case .root:
            return "root"
        case .tag:
            return tag!.forDisplay
        case .note:
            return note!.title.value
        }
    }
    
    /// Compare this Tags Node to another one and determine which is greater.
    func compareTo(node2: TagsNode) -> Int {
        if self.type.rawValue < node2.type.rawValue {
            return TagsNode.thisLessThanThat
        } else if self.type.rawValue > node2.type.rawValue {
            return TagsNode.thisGreaterThanThat
        } else if self.type == .tag && self.tag! < node2.tag! {
            return TagsNode.thisLessThanThat
        } else if self.type == .tag && self.tag! > node2.tag! {
            return TagsNode.thisGreaterThanThat
        } else if self.type == .note && self.note! < node2.note! {
            return TagsNode.thisLessThanThat
        } else if self.type == .note && self.note! > node2.note! {
            return TagsNode.thisGreaterThanThat
        } else if self.type == .note && self.note!.noteID < node2.note!.noteID {
            return TagsNode.thisLessThanThat
        } else if self.type == .note && self.note!.noteID > node2.note!.noteID {
            return TagsNode.thisGreaterThanThat
        } else {
            return TagsNode.thisEqualsThat
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.rawValue)
        if type == .tag {
            hasher.combine(tag!.sortKey)
        } else if type == .note {
            hasher.combine(note!.sortKey)
            hasher.combine(note!.noteID.commonID)
        }
    }
    
    func addChild(tagLevel: TagLevel) -> TagsNode {
        let tagNode = TagsNode(tag: tagLevel)
        return addChild(node: tagNode)
    }
    
    func addChild(tagLevel: String) -> TagsNode {
        let tagNode = TagsNode(tag: tagLevel)
        return addChild(node: tagNode)
    }
    
    func addChild(note: Note) -> TagsNode {
        let noteNode = TagsNode(note: note)
        return addChild(node: noteNode)
    }
    
    /// Either add the supplied node to this node at the proper insertion point,
    /// or determine that a node with an identical key already exists.
    ///
    /// - Parameter node: The node to be added, if it's not already there.
    /// - Returns: The node that was added, or the equal one that already existed. 
    func addChild(node: TagsNode) -> TagsNode {
        
        // Use binary search to look for a match or the
        // first item greater than the desired key.
        var index = 0
        var bottom = 0
        var top = children.count - 1
        var done = false
        while !done {
            if bottom > top {
                done = true
                index = bottom
            } else if top == bottom || top == (bottom + 1) {
                done = true
                if node > children[top] {
                    index = top + 1
                } else if node == children[top] {
                    return children[top]
                } else if node == children[bottom] {
                    return children[bottom]
                } else if node > children[bottom] {
                    index = top
                } else {
                    index = bottom
                }
            } else {
                let middle = bottom + ((top - bottom) / 2)
                if node == children[middle] {
                    return children[middle]
                } else if node > children[middle] {
                    bottom = middle + 1
                } else {
                    top = middle
                }
            }
        }
        
        if index >= children.count {
            node.parent = self
            children.append(node)
            return node
        } else if index < 0 {
            node.parent = self
            children.insert(node, at: 0)
            return node
        } else if node < children[index] {
            node.parent = self
            children.insert(node, at: index)
            return node
        } else {
            return children[index]
        }
    }
    
    /// Return the child at the specified index, or nil if bad index
    func getChild(at index: Int) -> TagsNode? {
        if index < 0 || index >= children.count {
            return nil
        } else {
            return children[index]
        }
    }
    
    /// Remove the child at the specified index.
    func remove(at index: Int) {
        if index >= 0 && index < children.count {
            children.remove(at: index)
        }
    }
    
    /// Return the number of children for which this node is a parent
    var countChildren: Int {
        return children.count
    }
    
    public func display() {
        print(" ")
        print("TagsNode.display")
        print("  - Type = \(type)")
        switch type {
        case .root:
            break
        case .tag:
            print("  - Tags = \(tag!.forDisplay)")
        case .note:
            print("  - Title = \(note!.title.value)")
            if note!.hasTags() {
                print("  - Tags = \(note!.tags.value)")
            } else {
                print("  - Untagged")
            }
        }
    }
}
