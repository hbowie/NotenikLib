//
//  Transmogrifier.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/4/21.
//
//  Copyright © 2021 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown

/// A class to transform a Notenik Collection in a surprising or magical manner.
public class Transmogrifier {
    
    var io: NotenikIO
    
    /// Initialize with the input/output module to be used.
    public init(io: NotenikIO) {
        self.io = io
    }
    
    /// Update WikiLinks and BackLinks for an edited Note.
    /// - Parameters:
    ///   - note:  The note that has been edited.
    ///   - links: The Wiki Links derived from the latest Markdown contents of the
    ///            note's body field.
    /// - Returns: True if changes in the Wiki Links were detected; false otherwise.
    public func updateLinks(for note: Note, links: [WikiLink]) -> Bool {

        guard let collection = io.collection else { return false }
        guard collection.backlinksDef != nil else { return false }
        guard collection.wikilinksDef != nil else { return false }
        
        // Compare old links to new ones, deleting any matches
        // from both lists.
        var newLinks = links
        var oldLinks = note.wikilinks.notePointers.list
        
        var i = 0
        while i < newLinks.count {
            var matched = false
            let newLink = newLinks[i]
            var j = 0
            while j < oldLinks.count {
                let oldLink = oldLinks[j]
                if newLink.bestTarget.pathSlashID == oldLink.pathSlashID {
                    matched = true
                    oldLinks.remove(at: j)
                    break
                } else {
                    j += 1
                }
            }
            if matched {
                newLinks.remove(at: i)
            } else {
                i += 1
            }
        }
        
        var noteUpdated = false
        
        for newLink in newLinks {
            noteUpdated = true
            let (targetIO, linkedNote) = getNote(newLink.bestTarget)
            if linkedNote != nil {
                let modNote = linkedNote!.copy() as! Note
                let backLinks = modNote.backlinks
                let path = note.collection.collectionID
                if path.isEmpty {
                    backLinks.add(noteIdBasis: note.noteID.basis)
                } else {
                    backLinks.add(noteIdBasis: path + "/" + note.noteID.basis)
                }
                _ = modNote.setBacklinks(backLinks)
                _ = targetIO!.modNote(oldNote: linkedNote!, newNote: modNote)
            }
        }
        
        for oldLink in oldLinks {
            noteUpdated = true
            let (targetIO, linkedNote) = getNote(oldLink)
            if linkedNote != nil {
                let modNote = linkedNote!.copy() as! Note
                let backLinks = modNote.backlinks
                backLinks.remove(noteIdBasis: note.noteID.basis)
                _ = modNote.setBacklinks(backLinks)
                _ = targetIO!.modNote(oldNote: linkedNote!, newNote: modNote)
            }
        }
        
        if noteUpdated {
            _ = note.setWikiLinks(wikiLinks: links)
        }
        
        return noteUpdated
    }
    
    /// Update Inclusions  and IncludedBy links for an edited Note.
    /// - Parameters:
    ///   - note:  The note that has been edited.
    ///   - links: The Inclusions derived from the latest Markdown contents of the
    ///            note's body field.
    /// - Returns: True if changes in the Inclusions were detected; false otherwise.
    public func updateInclusions(for includingNote: Note, links: [WikiLink]) -> Bool {

        guard let collection = io.collection else { return false }
        guard collection.includedByDef != nil else { return false }
        guard collection.inclusionsDef != nil else { return false }
        
        // Compare old links to new ones, deleting any matches
        // from both lists.
        var newLinks = links
        var oldLinks = includingNote.inclusions.notePointers.list
        
        var i = 0
        while i < newLinks.count {
            var matched = false
            let newLink = newLinks[i]
            var j = 0
            while j < oldLinks.count {
                let oldLink = oldLinks[j]
                if newLink.bestTarget.pathSlashID == oldLink.pathSlashID {
                    matched = true
                    oldLinks.remove(at: j)
                    break
                } else {
                    j += 1
                }
            }
            if matched {
                newLinks.remove(at: i)
            } else {
                i += 1
            }
        }
        
        var noteUpdated = false
        
        // Now let's process any unmatched new links.
        for newLink in newLinks {
            noteUpdated = true
            let (targetIO, includedNote) = getNote(newLink.bestTarget)
            if includedNote != nil {
                let modNote = includedNote!.copy() as! Note
                let includedBy = modNote.includedBy
                let path = includingNote.collection.collectionID
                if path.isEmpty {
                    includedBy.add(noteIdBasis: includingNote.noteID.basis)
                } else {
                    includedBy.add(noteIdBasis: path + "/" + includingNote.noteID.basis)
                }
                _ = modNote.setIncludedBy(includedBy)
                _ = targetIO!.modNote(oldNote: includedNote!, newNote: modNote)
            }
        }
        
        for oldLink in oldLinks {
            noteUpdated = true
            let (targetIO, linkedNote) = getNote(oldLink)
            if linkedNote != nil {
                let modNote = linkedNote!.copy() as! Note
                let includedBy = modNote.includedBy
                includedBy.remove(noteIdBasis: includingNote.noteID.basis)
                _ = modNote.setIncludedBy(includedBy)
                _ = targetIO!.modNote(oldNote: linkedNote!, newNote: modNote)
            }
        }
        
        if noteUpdated {
            _ = includingNote.setInclusions(wikiLinks: links)
        }
        
        return noteUpdated
    }
    
    
    /// Go through the entire Collection, updating Wikilinks and Backlinks fields to reflect
    /// current wiki style links found within Note bodies.
    public func generateBacklinks() -> Int {
        
        guard let collection = io.collection else { return 0 }
        guard collection.backlinksDef != nil else { return 0 }
        guard collection.wikilinksDef != nil else { return 0 }
        
        let noteDisplay = NoteDisplay()
        let parms = DisplayParms()
        parms.localMj = false
        var from: [String:ListOfNoteIdentifiers] = [:]
        var to:   [String:ListOfNoteIdentifiers] = [:]
        
        // First pass through the Notes in the Collection, storing linkages in memory.
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            let mdResults = TransformMdResults()
            parms.setFrom(sortedNote: sortedNote!)
            let _ = noteDisplay.display(sortedNote!, io: io, parms: parms, mdResults: mdResults)
            let noteLinkList = mdResults.wikiLinks
            if !noteLinkList.isEmpty {
                for link in noteLinkList.links {
                    link.setFrom(path: "", item: sortedNote!.note.noteID.basis)
                    
                    // Add a Note if a target is missing
                    if !link.targetFound {
                        let newNote = Note(collection: sortedNote!.note.collection)
                        _ = newNote.setTitle(link.originalTarget.item)
                        newNote.identify()
                        _ = io.addNote(newNote: newNote)
                    }
                    
                    // Determine the To Title to be recorded
                    var toTarget = link.originalTarget
                    if !link.updatedTarget.isEmpty {
                        toTarget = link.updatedTarget
                    }
                    
                    // Record this link in the from dict.
                    let fromTitles = from[link.fromTarget.itemID]
                    if fromTitles == nil {
                        from[link.fromTarget.itemID] = ListOfNoteIdentifiers(noteIdBasis: toTarget.pathSlashItem)
                    } else {
                        from[link.fromTarget.itemID]!.add(noteIdBasis: toTarget.pathSlashItem)
                    }
                    
                    // Record this link in the To dict
                    let toTitles = to[link.bestTarget.pathSlashID]
                    if toTitles == nil {
                        to[link.bestTarget.pathSlashID] = ListOfNoteIdentifiers(noteIdBasis: link.fromTarget.pathSlashItem)
                    } else {
                        to[link.bestTarget.pathSlashID]!.add(noteIdBasis: link.fromTarget.pathSlashItem)
                    }
                }
            }
            
            (sortedNote, position) = io.nextNote(position)
        }
        
        // Now make a second pass through the Notes in the Collection,
        // updating them this time around.
        var backlinksCount = 0
        (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            let wikiLinks = WikilinkValue()
            let backLinks = BacklinkValue()

            let fromList = from[sortedNote!.note.noteID.commonID]
            if fromList != nil {
                for noteIdBasis in fromList!.noteIDs {
                    wikiLinks.add(noteIdBasis: noteIdBasis)
                }
            }
            
            let toList = to[sortedNote!.note.noteID.commonID]
            if toList != nil {
                for noteID in toList!.noteIDs {
                    backLinks.notePointers.add(noteIdBasis: noteID)
                    backlinksCount += 1
                }
            }
            
            var noteUpdated = false
            let modNote = sortedNote!.note.copy() as! Note
            
            if wikiLinks.value != sortedNote!.note.wikilinks.value {
                noteUpdated = true
                _ = modNote.setWikilinks(wikiLinks)
            }
            
            if backLinks.value != sortedNote!.note.backlinks.value {
                noteUpdated = true
                _ = modNote.setBacklinks(backLinks)
            }
            
            if noteUpdated {
                let (updatedNote, _) = io.modNote(oldNote: sortedNote!.note, newNote: modNote)
                if updatedNote == nil {
                    print("io.modNote failed!")
                }
            }
            
            (sortedNote, position) = io.nextNote(position)
        }
        
        return backlinksCount
    }
    
    let multiIO = MultiFileIO.shared
    
    /// Look for a Note, using the path to access a differnet Collection via MultifileIO, if path is non-blank.
    func getNote(_ target: WikiLinkTarget) -> (NotenikIO?, Note?) {
        var targetIO = io
        if target.hasPath {
            let (targetCollection, maybeIO) = multiIO.provision(shortcut: target.path, inspector: nil, readOnly: false)
            if targetCollection != nil {
                targetIO = maybeIO
            }
        }
        let linkedNote = targetIO.getNote(forID: target.itemID)
        return (targetIO, linkedNote)
    }
    
    class ListOfNoteIdentifiers {
        
        var noteIDs: [String] = []
        
        init(noteIdBasis: String) {
            noteIDs.append(noteIdBasis)
        }
        
        func add(noteIdBasis: String) {
            var index = 0
            while index < noteIDs.count && noteIdBasis > noteIDs[index] {
                index += 1
            }
            if index >= noteIDs.count {
                noteIDs.append(noteIdBasis)
            } else if noteIdBasis == noteIDs[index] {
                return
            } else {
                noteIDs.insert(noteIdBasis, at: index)
            }
        }
        
        func display() {
            print("Transmogrifier.ListOfTitles.display")
            for noteIdBasis in noteIDs {
                print("  - note ID Basis = \(noteIdBasis)")
            }
        }
    }
    
}
