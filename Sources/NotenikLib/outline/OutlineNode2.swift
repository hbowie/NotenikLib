//
//  OutlineNode2.swift
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

/// A single node in the Tags Tree.
public class OutlineNode2: Comparable, CustomStringConvertible {
    
    // Constants used within this class.
    static let thisLessThanThat = -1
    static let thisGreaterThanThat = 1
    static let thisEqualsThat = 0
    
    // -----------------------------------------------------------
    //
    // MARK: Variables.
    //
    // -----------------------------------------------------------
    
    // Type of node: root or note.
    public var type:  nodeType = .root
    
    // Parent of this node.
    public var parent: OutlineNode2?
    
    public var hasParent: Bool {
        return parent != nil
    }
    
    // Children of this node.
    public private(set) var children: [OutlineNode2] = []
    
    public var hasChildren: Bool {
        return !children.isEmpty
    }
    
    // Note.
    public var note: Note? {
        get {
            return _note
        }
        set {
            _note = newValue
            if _note != nil {
                type = .note
                level = _note!.depth
                seqSortKey = _note!.seq.sortKey
                seqValue = _note!.seq.value
            } else {
                level = 0
                seqSortKey = ""
            }
        }
    }
    var _note: Note?
    
    // The Seq Sort Key for this node
    var seqSortKey = ""
    
    // The Seq Value for this Node
    var seqValue   = ""
    
    // Level in hierarchy as indicated by level and/or seq fields.
    var level = 0
    
    // -----------------------------------------------------------
    //
    // MARK: Initialization
    //
    // -----------------------------------------------------------
    
    /// Root init.
    init() {
        
    }
    
    /// Initialize witth a Note.
    /// - Parameter note: The Note object to be used.
    convenience init(note: Note) {
        self.init()
        self.note = note
        seqSortKey = note.seq.sortKey
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Protocol Compliance.
    //
    // -----------------------------------------------------------
    
    /// Provide a String identifyint the node.
    public var description: String {
        switch type {
        case .root:
            return "Root of Outline (level: \(level))"
        case .note:
            return note!.seq.value + " " + note!.title.value + " (level: \(level))"
        }
    }
    
    /// Is the first node less than the second node?
    /// - Parameters:
    ///   - lhs: The first (left-hand) node.
    ///   - rhs: The sedond (right-hand) node.
    /// - Returns: True if  the first is less than the second.
    public static func < (lhs: OutlineNode2, rhs: OutlineNode2) -> Bool {
        return lhs.compareTo(node2: rhs) <= thisLessThanThat
    }
    
    /// Is the first node equal to the second?
    /// - Parameters:
    ///   - lhs: The first (left-hand side) node
    ///   - rhs: The second (right-hand side) node
    /// - Returns: True if the two are equal.
    public static func == (lhs: OutlineNode2, rhs: OutlineNode2) -> Bool {
        return lhs.compareTo(node2: rhs) == thisEqualsThat
    }
    
    /// Compare this Outline Node to another one and determine which is greater.
    func compareTo(node2: OutlineNode2) -> Int {
        
        // Compare node types
        guard self.type == .note && node2.type == .note else {
            if self.type.rawValue < node2.type.rawValue {
                return OutlineNode2.thisLessThanThat
            }
            if self.type.rawValue > node2.type.rawValue {
                return OutlineNode2.thisGreaterThanThat
            }
            return OutlineNode2.thisEqualsThat
        }
        
        // Compare Seq values
        if self.seqSortKey < node2.seqSortKey {
            return OutlineNode2.thisLessThanThat
        }
        if self.seqSortKey > node2.seqSortKey {
            return OutlineNode2.thisGreaterThanThat
        }
        
        // Compare Note Identifiers
        if self.note!.noteID < node2.note!.noteID {
            return OutlineNode2.thisLessThanThat
        }
        if self.note!.noteID > node2.note!.noteID {
            return OutlineNode2.thisGreaterThanThat
        }
        
        // Everything is equal.
        return OutlineNode2.thisEqualsThat
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Custom Functions.
    //
    // -----------------------------------------------------------
    
    /// Does this node qualify as a child of the given node, based on node type, level and  seq.
    /// - Parameter possibleParent: The possible parent to be evaluated.
    /// - Returns: True if  level and seq are both beneath the parent's values.
    public func isChildOf(_ possibleParent: OutlineNode2) -> Bool {
        guard level > possibleParent.level else {
            return false
        }
        guard seqValue.starts(with: possibleParent.seqValue) else {
            return false
        }
        return true
    }
    
    /// Add a child note beneatht his node.
    /// - Parameter note: The note to be added.
    /// - Returns: The node created and added.
    func addChild(note: Note) -> OutlineNode2 {
        let noteNode = OutlineNode2(note: note)
        return addChild(node: noteNode)
    }
    
    /// Either add the supplied node to this node at the proper insertion point,
    /// or determine that a node with an identical key already exists.
    ///
    /// - Parameter node: The node to be added, if it's not already there.
    /// - Returns: The node that was added, or the equal one that already existed.
    func addChild(node: OutlineNode2) -> OutlineNode2 {
        
        if children.isEmpty {
            node.parent = self
            children.append(node)
            return node
        }
        
        var precedingNode: OutlineNode2? = nil
        var i = 0
        while i < children.count {
            let nextChild = children[i]
            if node < nextChild {
                if precedingNode == nil {
                    node.parent = self
                    children.insert(node, at: 0)
                    scanForChildren(newNode: node, startingAt: 1)
                    return node
                } else {
                    if node.isChildOf(precedingNode!) {
                        return precedingNode!.addChild(node: node)
                    } else {
                        if node == precedingNode {
                            node.parent = self
                            children[i - 1] = node
                            scanForChildren(newNode: node, startingAt: i + 1)
                            return node
                        } else {
                            node.parent = self
                            children.insert(node, at: i)
                            scanForChildren(newNode: node, startingAt: i + 1)
                            return node
                        }
                    }
                }
            } else {
                precedingNode = nextChild
                i += 1
            }
        }
        
        if node.isChildOf(precedingNode!) {
            return precedingNode!.addChild(node: node)
        } else {
            if node == precedingNode {
                node.parent = self
                children[i - 1] = node
                return node
            } else {
                node.parent = self
                children.append(node)
                return node
            }
        }
    }
    
    /// See if following nodes should become children of the one being added.
    /// - Parameters:
    ///   - newNode: The node being added.
    ///   - startingAt: An index pointing to this node/s next child.
    func scanForChildren(newNode: OutlineNode2, startingAt: Int) {
        var childrenFound = true
        while startingAt < children.count && childrenFound {
            let possibleChild = children[startingAt]
            childrenFound = false
            if possibleChild.isChildOf(newNode) {
                childrenFound = true
                _ = newNode.addChild(node: possibleChild)
                children.remove(at: startingAt)
            }
        }
    }
    
    /// Attempt to remove the given note from the outline tree.
    /// - Parameter note: The note to be removed.
    /// - Returns: The node removed, if a match could be found.
    func removeChild(note: Note) -> OutlineNode2? {
        let noteNode = OutlineNode2(note: note)
        return removeChild(node: noteNode)
    }
    
    /// Attempt to remove the given node from the outline tree.
    /// - Parameter note: The node to be removed.
    /// - Returns: The node removed, if a match could be found.
    func removeChild(node: OutlineNode2) -> OutlineNode2? {
        
        guard node.type == .note else { return nil }
        
        guard hasChildren else { return nil }
        
        var precedingNode: OutlineNode2? = nil
        var i = 0
        while i < children.count {
            let nextChild = children[i]
            if node == nextChild {
                reassignChildren(parent: self, index: i)
                children.remove(at: i)
                return nextChild
            }
            if node < nextChild {
                if precedingNode == nil {
                    return nil
                }
                if node.level > precedingNode!.level {
                    return precedingNode!.removeChild(node: node)
                }
                return nil
            }
            // node > nextChild
            precedingNode = nextChild
            i += 1
        }
        
        if node.level > precedingNode!.level {
            return precedingNode!.removeChild(node: node)
        }
        return nil
    }
    
    func reassignChildren(parent: OutlineNode2, index: Int) {
        let vanishingChild = parent.children[index]
        guard vanishingChild.hasChildren else { return }
        var prior: OutlineNode2?
        var following: OutlineNode2?
        if index > 0 {
            prior = parent.children[index - 1]
        }
        if (index + 1) < parent.children.count {
            following = parent.children[index + 1]
        }
        var insertAt = index + 1
        while 0 < vanishingChild.children.count {
            let grandChild = vanishingChild.children[0]
            if prior != nil && grandChild.isChildOf(prior!) {
                _ = prior!.addChild(node: grandChild)
            } else if following != nil && grandChild.isChildOf(following!) {
                _ = following!.addChild(node: grandChild)
            } else {
                grandChild.parent = parent
                parent.children.insert(grandChild, at: insertAt)
                insertAt += 1
            }
            vanishingChild.children.remove(at: 0)
        }
    }
    
    /// Return the child at the specified index, or nil if bad index
    func getChild(at index: Int) -> OutlineNode2? {
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
        print("OutlineNode2.display")
        print("  - Type = \(type)")
        if note != nil {
            print("  - Note Title: \(note!.title.value)")
            print("    - Note Seq: \(note!.seq.value)")
            print("    - Note Level: \(note!.level.value)")
        }
        print("  - Level: \(level)")
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
    }
    
    public func display(numberOfParents: Int = 0) {
        if type == .root {
            print("Root of Outline (level: \(level))")
        } else {
            let indent = String(repeating: "  ", count: numberOfParents)
            print(indent + "- " + note!.seq.value + " " + note!.title.value + " (level: \(level))")
        }
        for child in children {
            child.display(numberOfParents: numberOfParents + 1)
        }
    }
    
    public enum nodeType: Int {
        case root   = 0
        case note   = 1
    }
}
