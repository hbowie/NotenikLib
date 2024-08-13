//
//  OutlineNodeIterator.swift
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

public class OutlineNodeIterator: IteratorProtocol {
    
    var outlineNode: OutlineNode2? = nil
    var depth = 0
    var positions: [Int] = []
    
    /// Initialize with the NotenikIO instance.
    init(root: OutlineNode2) {
        outlineNode = root
    }
    
    /// Return the next Outline Node, or nil at the end.
    public func next() -> OutlineNode2? {
        
        var nextNode: OutlineNode2? = nil
        if outlineNode!.children.count > 0 {
            setPosition(depth: depth, position: 0)
            nextNode = outlineNode!.children[0]
            depth += 1
        } else {
            depth -= 1
            var checkNode = outlineNode
            while depth >= 0 && nextNode == nil {
                let parent = checkNode!.parent
                let siblingPosition = positions[depth] + 1
                if siblingPosition < parent!.children.count {
                    setPosition(depth: depth, position: siblingPosition)
                    nextNode = parent!.children[siblingPosition]
                    depth += 1
                } else {
                    depth -= 1
                    checkNode = parent
                }
            }
        }
        outlineNode = nextNode
        return nextNode
    }
    
    /// Set the position within the list of children at the given level.
    func setPosition(depth: Int, position: Int) {
        if depth >= positions.count {
            positions.append(position)
        } else {
            positions[depth] = position
        }
    }
    
}
