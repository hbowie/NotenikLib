//
//  NotenikFolderNode.swift
//  Notenik
//  
//  Created by Herb Bowie on 9/10/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// One node in a Notenik Folder Tree.
public class NotenikFolderNode: Comparable, CustomStringConvertible {
    
    private(set) weak   var parent:   NotenikFolderNode?
    public private(set) var children: [NotenikFolderNode] = []
    public              var type:     NotenikFolderNodeType = .root
    public              var desc    = ""
    public              var folder:   NotenikFolder?
    
    /// Initialize with defaults.
    public init() {
        
    }
    
    /// Initialize with data.
    convenience init(type: NotenikFolderNodeType, desc: String, folder: NotenikFolder? = nil) {
        self.init()
        self.type = type
        self.desc = desc
        self.folder = folder
    }
    
    /// Conform to CustomStringConvertible by returning a String description.
    public var description: String { return desc }
    
    /// Add a child given the child data. 
    func addChild(type: NotenikFolderNodeType, desc: String, folder: NotenikFolder? = nil) -> NotenikFolderNode {
        let newNode = NotenikFolderNode(type: type, desc: desc, folder: folder)
        return addChild(newNode: newNode)
    }
    
    /// Add a child node to this parent.
    func addChild(newNode: NotenikFolderNode) -> NotenikFolderNode {
        newNode.parent = self
        var index = children.count - 1
        while index >= 0 {
            let compareNode = children[index]
            if newNode == compareNode {
                return compareNode
            } else if newNode > compareNode {
                if index == children.count - 1 {
                    children.append(newNode)
                } else {
                    children.insert(newNode, at: index + 1)
                }
                return newNode
            } else {
                index -= 1
            }
        }
        children.insert(newNode, at: 0)
        return newNode
    }
    
    /// Return a child node at the specified index.
    public func getChild(at index: Int) -> NotenikFolderNode? {
        if index < 0 || index >= children.count {
            return nil
        } else {
            return children[index]
        }
    }
    
    /// Remove a child node at the specified index.
    func remove(at index: Int) {
        if index >= 0 && index < children.count {
            children.remove(at: index)
        }
    }
    
    /// How many children does this node have?
    public var countChildren: Int {
        return children.count
    }
    
    /// Conform to Comparable protocol: determine if one node is less than another.
    public static func < (lhs: NotenikFolderNode, rhs: NotenikFolderNode) -> Bool {
        if lhs.type.rawValue < rhs.type.rawValue {
            return true
        } else if lhs.type.rawValue > rhs.type.rawValue {
            return false
        } else if lhs.desc.lowercased() < rhs.desc.lowercased() {
            return true
        } else if lhs.desc.lowercased() > rhs.desc.lowercased() {
            return false
        } else {
            return lhs.desc < rhs.desc
        }
    }
    
    /// Conform to Comparable protocol: determine if one node is equal to another.
    public static func == (lhs: NotenikFolderNode, rhs: NotenikFolderNode) -> Bool {
        return (lhs.type.rawValue == rhs.type.rawValue && lhs.desc == rhs.desc)
    }
}
