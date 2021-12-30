//
//  Sequencer.swift
//  Notenik
//
//  Created by Herb Bowie on 9/20/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Can be used to increment update Note Seq values, typically for multiple Notes.
public class Sequencer {
    
    let levelsHead = "levels-outline"
    
    var io: NotenikIO!
    var collection: NoteCollection!
    var seqFieldDef: FieldDefinition!
    
    var notesToUpdate: [Note] = []
    var updatedSeqs:   [SeqValue] = []
    var updatedLevels: [LevelValue] = []
    var updatedTags:   [String] = []
    
    public init?(io: NotenikIO) {
        guard io.collectionOpen else { return nil }
        if io.collection == nil {
            return nil
        } else {
            self.io = io
            collection = io.collection!
        }
        guard io.sortParm == .seqPlusTitle || io.sortParm == .tasksBySeq else { return nil }
    }
    
    /// Increment the sequence of one Note along with following Notes
    /// that would otherwise now be less than or equal to the
    /// sequences of prior Notes.
    ///
    /// - Parameters:
    ///   - startingNote: The first Note whose sequence is to be incremented.
    /// - Returns: The number of Notes having their sequences incremented, and the first Note incremented.
    public func incrementSeq(startingNote: Note, incMajor: Bool = false) -> (Int, Note?) {
        
        let (ready, _) = readyForUpdates()
        guard ready else { return (0, nil) }
        guard startingNote.hasSeq() else { return (0, nil) }
        
        var incDepth = startingNote.seq.seqStack.max
        if incMajor {
            incDepth = 0
        }
        var position = io.positionOfNote(startingNote)
        var note: Note? = startingNote
        var (nextNote, nextPosition) = io.nextNote(position)
        var starting = true
        var lastSeq: SeqValue?
        
        var incrementing = true
        while incrementing && note != nil && position.valid {
            let seq = note!.seq
            
            // Special logic for first note processed
            if starting {
                lastSeq = seq.dupe()
                starting = false
            }
            
            // See if the current sequence is already greater than the last one
            let greater = (seq > lastSeq!)
            
            // See if we're done, or need to keep going
            if greater {
                incrementing = false
            } else {
                incrementing = true
                let newSeq = seq.dupe()
                newSeq.incAtLevel(level: incDepth, removingDeeperLevels: false)
                appendMod(note: note!, newSeq: newSeq, newLevel: nil)
                lastSeq = newSeq.dupe()
            }
            
            note = nextNote
            position = nextPosition
            (nextNote, nextPosition) = io.nextNote(position)
        }
        
        let firstNote = applyUpdates(updateSeq: true, updateTags: false)
        
        return (updatedSeqs.count, firstNote)
    }
    
    /// Resequence a range of Notes.
    /// - Parameters:
    ///   - startingRow: The first row to be resequenced.
    ///   - endingRow: The last row to be resequenced.
    ///   - newSeqValue: The new value to be assigned as the Seq value for the first note in the range.
    /// - Returns: Updates the notes in the range to retain their Seq depth, but be numbered consecutively
    ///     starting with the new Seq value of the starting note. 
    public func renumberRange(startingRow: Int, endingRow: Int, newSeqValue: String) -> Note? {
        
        let (ready, _) = readyForUpdates()
        guard ready else { return nil }
        
        guard let firstNote = io.getNote(at: startingRow) else { return nil }
        var priorOldSeq = firstNote.seq.dupe()
        var priorNewSeq = SeqValue(newSeqValue)
        let levelAdd = priorNewSeq.numberOfLevels - priorOldSeq.numberOfLevels
        var newLevel: LevelValue?
        if levelAdd != 0 {
            newLevel = firstNote.level.dupe()
            newLevel!.add(levelsToAdd: levelAdd, config: collection.levelConfig)
        }
        appendMod(note: firstNote, newSeq: priorNewSeq, newLevel: newLevel)
        
        var nextRow = startingRow + 1
        while nextRow <= endingRow {
            guard let nextNote = io.getNote(at: nextRow) else {
                nextRow = endingRow
                break
            }
            let nextOldSeq = nextNote.seq
            let nextNewSeq = priorNewSeq.dupe()
            let incLevel =  nextOldSeq.maxLevel + levelAdd
            nextNewSeq.incAtLevel(level: incLevel, removingDeeperLevels: true)
            if levelAdd != 0 {
                newLevel = nextNote.level.dupe()
                newLevel!.add(levelsToAdd: levelAdd, config: collection.levelConfig)
            }
            appendMod(note: nextNote, newSeq: nextNewSeq, newLevel: newLevel)
            priorOldSeq = nextOldSeq
            priorNewSeq = nextNewSeq
            nextRow += 1
        }
        
        return applyUpdates(updateSeq: true, updateTags: false)
    }
    
    /// Update Seq and/or Tags field based on outline structure (based on seq + level).
    public func outlineUpdatesBasedOnLevel(updateSeq: Bool, updateTags: Bool) -> (Int, String) {
        
        let (ready, errMsg) = readyForUpdates()
        guard ready else { return (0, errMsg) }
        
        guard collection.levelFieldDef != nil else {
            return(0, "The Collection must contain a Level field before it can be Renumbered or Retagged")
        }
        
        // Go through the Collection, dentifying Notes that need updating.
        let low = collection.levelConfig.low
        let high = collection.levelConfig.high
        var first = true
        
        var numbers: [Int] = []
        while numbers.count <= high {
            numbers.append(0)
        }
        
        var parents: [String] = []
        while parents.count <= high {
            parents.append("")
        }
        
        var lastLevel = 0
        var startNumberingAt = low
        var tagStart = low
        
        var (note, position) = io.firstNote()
        while note != nil {
            
            // Process the next note.
            let noteLevel = note!.level.getInt()
            
            // Calculate the new seq value.
            var newSeq = ""
            if first && !note!.hasSeq() && noteLevel == low {
                startNumberingAt = low + 1
                tagStart = low + 1
            } else {
                while lastLevel > noteLevel {
                    numbers[lastLevel] = 0
                    parents[lastLevel] = ""
                    lastLevel -= 1
                }
                lastLevel = noteLevel
                numbers[noteLevel] += 1
                var i = startNumberingAt
                while i <= noteLevel {
                    if numbers[i] > 0 {
                        if newSeq.count > 0 { newSeq.append(".") }
                        newSeq.append(String(numbers[i]))
                    }
                    i += 1
                }
            }
            
            // Generate the new tags.
            var levelsTagForThisLevel = ""
            if updateSeq {
                if noteLevel >= startNumberingAt {
                    levelsTagForThisLevel.append(String(numbers[noteLevel]))
                    if levelsTagForThisLevel.count > 0 {
                        levelsTagForThisLevel.append(" ")
                    }
                }
            }
            let tagTitle = TagsValue.tagify(note!.title.value)
            levelsTagForThisLevel.append(tagTitle)
            parents[noteLevel] = levelsTagForThisLevel
            
            var newLevelTags = ""
            newLevelTags.append(levelsHead)
            var tagEnd = noteLevel
            if tagEnd == high {
                tagEnd = noteLevel - 1
            }
            if tagEnd < low {
                tagEnd = low
            }
            var j = tagStart
            while j <= tagEnd {
                if parents[j].count > 0 {
                    if newLevelTags.count > 0 { newLevelTags.append(".") }
                    newLevelTags.append(parents[j])
                }
                j += 1
            }
            
            // Now generate the new tags, preserving any non-level related tags assigned by the user.
            var newTags = ""
            let currTags = note!.tags
            var replaced = false
            for tagValue in currTags.tags {
                let tag = tagValue.value
                if tag.hasPrefix(levelsHead) {
                    if newTags.count > 0 { newTags.append(",") }
                    newTags.append(newLevelTags)
                    replaced = true
                } else {
                    if newTags.count > 0 { newTags.append(",") }
                    newTags.append(tag)
                }
            }
            if !replaced {
                if newTags.count > 0 { newTags.append(",") }
                newTags.append(newLevelTags)
            }
            
            // Now store any updates, so that we can apply them later.
            var updateNote = false
            
            if updateSeq && newSeq != note!.seq.value {
                updateNote = true
            }
            
            if updateTags && newLevelTags != note!.tags.value {
                updateNote = true
            }
            
            if updateNote {
                notesToUpdate.append(note!)
                if updateSeq {
                    updatedSeqs.append(SeqValue(newSeq))
                }
                if updateTags {
                    updatedTags.append(newTags)
                }
            }
            
            first = false
            (note, position) = io!.nextNote(position)
        }
        
        // Now perform the updates.
        _ = applyUpdates(updateSeq: updateSeq, updateTags: updateTags)
        
        return (notesToUpdate.count, "")
    }
    
    /// Get ready to generate updates.
    /// - Returns: (success flag, error message)
    func readyForUpdates() -> (Bool, String) {
        guard io.collectionOpen else { return (false, "Collection not open") }
        guard collection != nil else { return (false, "Collection metadata missing") }
        guard collection.seqFieldDef != nil else {
            return(false, "The Collection must contain a Seq field in order to perform the requested operation")
        }
        guard collection.sortParm == .seqPlusTitle || collection.sortParm == .tasksBySeq else {
            return (false, "First Sort by Seq + Title before attempting this operation")
        }
        
        updatedSeqs = []
        updatedLevels = []
        updatedTags = []
        notesToUpdate = []
        
        return (true, "")
    }
    
    
    /// Append the next note to be modified, along with its new seq value.
    /// - Parameters:
    ///   - note: The note to be modified.
    ///   - newSeq: The new seq value.
    func appendMod(note: Note, newSeq: SeqValue, newLevel: LevelValue?) {
        updatedSeqs.append(newSeq)
        notesToUpdate.append(note)
        if newLevel != nil {
            updatedLevels.append(newLevel!)
        }
    }
    
    
    /// Apply the generated updates to the Collection.
    /// - Parameters:
    ///   - updateSeq: Are we updating Seq values?
    ///   - updateTags: Are we updating Tags?
    /// - Returns: The first note modified, if any.
    func applyUpdates(updateSeq: Bool, updateTags: Bool) -> Note? {
        
        // Now apply the new sequences from the top down, in order to
        // keep notes from changing position in the sorted list when we
        // are incrementing.
        
        var firstModNote: Note?
        var updateIndex = notesToUpdate.count - 1
        while updateIndex >= 0 {
            let originalNote = notesToUpdate[updateIndex]
            let modNote = originalNote.copy() as! Note
            var setOK = true
            var modOK = true
            if updateSeq && updatedSeqs.count == notesToUpdate.count {
                let newSeq = updatedSeqs[updateIndex]
                setOK = modNote.setSeq(newSeq.value)
            }
            if updateTags && updatedTags.count == notesToUpdate.count && setOK {
                let newTags = updatedTags[updateIndex]
                setOK = modNote.setTags(newTags)
            }
            if updatedLevels.count == notesToUpdate.count && setOK {
                let newLevel = updatedLevels[updateIndex]
                setOK = modNote.setLevel(newLevel)
            }
            let (note, position) = io.modNote(oldNote: originalNote, newNote: modNote)
            modOK = (note != nil && position.valid)
            if (!setOK) || (!modOK) {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "Sequencer",
                                  level: .error,
                                  message: "Trouble updating Note titled \(modNote.title.value)")
            } else {
                firstModNote = modNote
            }
            
            updateIndex -= 1
        }
        return firstModNote
    }
}
