//
//  Transmogrifier.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/4/21.
//
//  Copyright © 2021 - 2022 Herb Bowie (https://hbowie.net)
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
                break
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
                backLinks.add(title: note.title.value)
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
                backLinks.remove(title: note.title.value)
                _ = modNote.setBacklinks(backLinks)
                _ = targetIO!.modNote(oldNote: linkedNote!, newNote: modNote)
            }
        }
        
        if noteUpdated {
            _ = note.setWikiLinks(wikiLinks: links)
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
        var from: [String:ListOfTitles] = [:]
        var to:   [String:ListOfTitles] = [:]
        
        // First pass through the Notes in the Collection, storing linkages in memory.
        var (note, position) = io.firstNote()
        while note != nil {
            parms.setFrom(note: note!)
            let (_, _) = noteDisplay.display(note!, io: io, parms: parms)
            let noteLinkList = noteDisplay.wikilinks
            if noteLinkList != nil {
                for link in noteLinkList!.links {
                    link.setFrom(path: "", item: note!.title.value)
                    
                    // Add a Note if a target is missing
                    if !link.targetFound {
                        let newNote = Note(collection: note!.collection)
                        _ = newNote.setTitle(link.originalTarget.item)
                        newNote.setID()
                        _ = io.addNote(newNote: newNote)
                    }
                    
                    // Determine the To Title to be recorded
                    var toTitle = link.originalTarget
                    if !link.updatedTarget.isEmpty {
                        toTitle = link.updatedTarget
                    }
                    
                    // Record this link in the from dict.
                    let fromTitles = from[link.fromTarget.item]
                    if fromTitles == nil {
                        from[link.fromTarget.itemID] = ListOfTitles(title: toTitle.pathSlashItem)
                    } else {
                        from[link.fromTarget.itemID]!.add(title: toTitle.pathSlashItem)
                    }
                    
                    // Record this link in the To dict
                    let toTitles = to[link.bestTarget.pathSlashID]
                    if toTitles == nil {
                        to[link.bestTarget.pathSlashID] = ListOfTitles(title: link.fromTarget.pathSlashItem)
                    } else {
                        to[link.bestTarget.pathSlashID]!.add(title: link.fromTarget.pathSlashItem)
                    }
                }
            }
            
            (note, position) = io.nextNote(position)
        }
        
        // Now make a second pass through the Notes in the Collection,
        // updating them this time around.
        var backlinksCount = 0
        (note, position) = io.firstNote()
        while note != nil {
            let titleCommon = note!.id
            let wikiLinks = WikilinkValue()
            let backLinks = BacklinkValue()

            let fromList = from[titleCommon]
            if fromList != nil {
                for title in fromList!.titles {
                    wikiLinks.add(title: title)
                }
            }
            
            let toList = to[titleCommon]
            if toList != nil {
                for title in toList!.titles {
                    backLinks.notePointers.add(title: title)
                    backlinksCount += 1
                }
            }
            
            var noteUpdated = false
            let modNote = note!.copy() as! Note
            
            if wikiLinks.value != note!.wikilinks.value {
                noteUpdated = true
                _ = modNote.setWikilinks(wikiLinks)
            }
            
            if backLinks.value != note!.backlinks.value {
                noteUpdated = true
                _ = modNote.setBacklinks(backLinks)
            }
            
            if noteUpdated {
                let (updatedNote, _) = io.modNote(oldNote: note!, newNote: modNote)
                if updatedNote == nil {
                    print("io.modNote failed!")
                }
            }
            
            (note, position) = io.nextNote(position)
        }
        
        return backlinksCount
    }
    
    let multiIO = MultiFileIO.shared
    
    /// Look for a Note, using the path to access a differnet Collection via MultifileIO, if path is non-blank.
    func getNote(_ target: WikiLinkTarget) -> (NotenikIO?, Note?) {
        var targetIO = io
        if target.hasPath {
            if let ioFromPath = multiIO.getFileIO(shortcut: target.path) {
                targetIO = ioFromPath
            }
        }
        let linkedNote = targetIO.getNote(forID: target.itemID)
        return (targetIO, linkedNote)
    }
    
    class ListOfTitles {
        
        var titles: [String] = []
        
        init(title: String) {
            titles.append(title)
        }
        
        func add(title: String) {
            var index = 0
            while index < titles.count && title > titles[index] {
                index += 1
            }
            if index >= titles.count {
                titles.append(title)
            } else if title == titles[index] {
                return
            } else {
                titles.insert(title, at: index)
            }
        }
        
        func display() {
            print("Transmogrifier.ListOfTitles.display")
            for title in titles {
                print("  - title = \(title)")
            }
        }
    }
    
}
