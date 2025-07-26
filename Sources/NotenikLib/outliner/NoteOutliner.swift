//
//  NoteOutliner.swift
//  NotenikLib
//
//  Copyright © 2023 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 12/21/23.
//

import Foundation

import NotenikUtils

public class NoteOutliner: Sequence {

    public typealias Iterator = OutlineIterator
    
    var notesList = NotesList()
    var levelStart = 0
    var levelEnd   = 999
    var displayParms = DisplayParms()
    
    var firstNode: OutlineNode?
    
    var collection: NoteCollection?
    var hasLevel = false
    var hasSeq = false
    var hasLevelAndSeq: Bool {
        return hasLevel && hasSeq
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Build the outline from a list of notes.
    //
    // -----------------------------------------------------------
    
    var stack: [OutlineNode?] = []
    
    /// Build an outline using a list of Notes.
    public init(list: NotesList, levelStart: Int, levelEnd: Int, skipID: String = "", displayParms: DisplayParms) {
        self.notesList = list
        self.levelStart = levelStart
        self.levelEnd = levelEnd
        self.displayParms = displayParms
        populateOutline(skipID: skipID)
    }
    
    var isEmpty: Bool {
        return firstNode == nil
    }
    
    func populateOutline(skipID: String = "") {

        stack = []
        var i = 0
        while i < notesList.count {
            
            // Initialize a new node instance.
            let sortedNote = notesList[i]
            let node = OutlineNode()
            node.sortedNote = sortedNote
            node.depth = 0
            
            if collection == nil {
                grabCollectionInfo(sortedNote.note)
            }
            
            // var inTheFamily = false
            
            var include = true
            if node.level < levelStart {
                include = false
            } else if node.level > levelEnd {
                include = false
            } else if sortedNote.note.noteID.commonID == skipID {
                include = false
            } else if sortedNote.note.klass.value == NotenikConstants.titleKlass {
                include = false
            } else if !sortedNote.note.includeInBook(epub: displayParms.epub3) {
                include = false
            } else if hasLevelAndSeq && sortedNote.note.level.level <= 1 && sortedNote.note.seq.count == 0 {
                include = false
            }
                        
            if include {
                
                // Calculate familial relationships.
                node.priorSibling = getNodeForLevel(node.level)
                
                var parentIndex = node.level - 1
                while parentIndex >= 0 && getNodeForLevel(parentIndex) == nil {
                    parentIndex -= 1
                }
                node.parent = getNodeForLevel(parentIndex)
                if node.hasParent {
                    node.depth = node.parent!.depth + 1
                }
                
                // Store this node for later use.
                setNodeForLevel(node.level, node: node)
                if firstNode == nil {
                    firstNode = node
                }
            }
            
            i += 1
            
        }
        stack = []
    }
    
    func grabCollectionInfo(_ note: Note) {
        let collection = note.collection
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
    }
    
    func getNodeForLevel(_ level: Int) -> OutlineNode? {
        
        guard level >= 0 else { return nil }
        
        if level < stack.count {
            return stack[level]
        } else {
            return nil
        }
    }
    
    func setNodeForLevel(_ level: Int, node: OutlineNode?) {
        
        guard level >= 0 else { return }
        
        while stack.count <= level {
            stack.append(nil)
        }
        var i = stack.count - 1
        while i > level {
            stack[i] = nil
            i -= 1
        }
        stack[level] = node
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Code to generate a table of contents in HTML.
    //
    // -----------------------------------------------------------
    
    /**
        The goal is to generate HTML entries in the following sequence.
     <ul>
        <li>
            <details>
                <summary>
                    1 <a href="https://ntnk.app/identity" class="nav-link">Identity</a>
                </summary>
                <ul>
                                ... repeat the ul structure as needed
                </ul>
    
            </details>
        </li>
     </ul>
     
     */
    var code = Markedup(format: .htmlFragment)
    var details = false
    var openNodes: [OutlineNode] = []
    var level = 0
    
    public func genToC(details: Bool) -> Markedup {
        
        if displayParms.format == .markdown {
            code = Markedup(format: .markdown)
        } else {
            code = Markedup(format: .htmlFragment)
        }
        
        self.details = details
        
        openNodes = []
        
        level = 0
        
        startUnorderedList()
        
        for node in self {
            
            // Process all the nodes in the tree structure.
            closeOpenNodes(downTo: node.depth)
            
            startListItem(node: node)
            
            if node.hasChildren {
                startUnorderedList()
            }

            openNodes.append(node)
        }
        
        closeOpenNodes(downTo: 0)
        finishUnorderedList()
        
        return code
    }
    
    func closeOpenNodes(downTo: Int) {
        while openNodes.count > 0 && downTo <= openNodes[openNodes.count - 1].depth {
            let top = openNodes.count - 1
            let openNode = openNodes[top]
            if openNode.hasChildren {
                finishUnorderedList()
                if details {
                    code.finishDetails()
                }
            }
            finishListItem(node: openNode)
            openNodes.remove(at: top)
        }
    }
    
    func startUnorderedList() {
        level += 1
        if details {
            code.startUnorderedList(klass: "outline-ul-within-details")
        } else {
            code.startUnorderedList(klass: "outline-ul")
        }
    }
    
    func startListItem(node: OutlineNode) {
        guard let sortedNote = node.sortedNote else { return }
        if level < 1 {
            level = 1
        }
        if details && node.hasChildren {
            code.startListItem()
        } else {
            code.startListItem(klass: "outline-li-no-kids", level: level)
        }
        if details && node.hasChildren {
            code.startDetails()
            code.startSummary()
        }
        displayParms.streamlinedTitleWithLink(markedup: code, sortedNote: sortedNote, klass: Markedup.htmlClassNavLink)
        if details && node.hasChildren {
            code.finishSummary()
        }
    }
    
    func finishListItem(node: OutlineNode) {
        code.finishListItem()
    }
    
    func finishUnorderedList() {
        if level > 0 {
            level -= 1
        }
        code.finishUnorderedList()
    }
    
    public func makeIterator() -> OutlineIterator {
        return OutlineIterator(self)
    }
    
    public class OutlineIterator: IteratorProtocol {
        
        public typealias Element = OutlineNode
        
        var outliner: NoteOutliner
        
        var lastNode: OutlineNode?
        
        public init(_ outliner: NoteOutliner) {
            self.outliner = outliner
        }
        
        public func next() -> OutlineNode? {
            if lastNode == nil {
                lastNode = outliner.firstNode
                return outliner.firstNode
            } else {
                let nextNode = lastNode!.nextNode(childrenExhausted: false)
                lastNode = nextNode
                return nextNode
            }
        }
    }
    
}
