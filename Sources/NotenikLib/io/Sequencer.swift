//
//  Sequencer.swift
//  Notenik
//
//  Created by Herb Bowie on 9/20/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Can be used to increment update Note Seq values, typically for multiple Notes.
public class Sequencer {
    
    let levelsHead = "levels-outline"
    
    var io:          NotenikIO!
    var collection:  NoteCollection!
    var seqFieldDef: FieldDefinition!
    var seqType:     SeqType!
    
    var notesToUpdate: [SortedNote] = []
    var updatedSeqs:   [SeqValue] = []
    var updatedLevels: [LevelValue] = []
    var updatedTags:   [String] = []
    
    /// Optionally create a new instance if necessary conditions are met.
    public init?(io: NotenikIO) {
        guard io.collectionOpen else { return nil }
        if io.collection == nil {
            return nil
        } else {
            self.io = io
            collection = io.collection!
        }
        guard let seqDef = collection.seqFieldDef else { return nil }
        self.seqFieldDef = seqDef
        guard let sqTyp = seqFieldDef.fieldType as? SeqType else { return nil }
        seqType = sqTyp
        guard io.sortParm == .seqPlusTitle || io.sortParm == .tasksBySeq else { return nil }
    }
    
    /// Increment the sequence of one Note along with following Notes
    /// that would otherwise now be less than or equal to the
    /// sequences of prior Notes.
    ///
    /// - Parameters:
    ///   - startingNote: The first Note whose sequence is to be incremented.
    /// - Returns: The number of Notes having their sequences incremented, and the first Note incremented.
    public func incrementSeq(startingNote: SortedNote, incMajor: Bool = false) -> (Int, SortedNote?) {
        
        // Make sure we have needed prereqs
        let (ready, _) = readyForUpdates()
        guard ready else { return (0, nil) }
        guard startingNote.note.hasSeq() else { return (0, nil) }
        
        // Determine depth at which we are incrementing
        var incDepth: Int = 0
        let singleSeq = startingNote.seqSingleValue
        incDepth = singleSeq.seqStack.max
        if incMajor {
            incDepth = 0
        }
        
        // Prepare to bump up as many notes as necessary to avoid duplicates
        var position = io.positionOfNote(startingNote)
        var sortedNote: SortedNote? = startingNote
        var (nextNote, nextPosition) = io.nextNote(position)
        var starting = true
        var lastSeq: SeqSingleValue?
        
        // Process notes until no more duplicates
        var incrementing = true
        while incrementing && sortedNote != nil && position.valid {
            let newSeq = sortedNote!.note.seq.dupe()
            var seqMods = false
            
            let seqSingle = sortedNote!.seqSingleValue
            
            // Special logic for first note processed
            if starting {
                lastSeq = seqSingle.dupe()
            }
            // See if the current sequence is already greater than the last one
            let greater = (seqSingle > lastSeq!)
            
            // See if we're done, or need to keep going
            if greater {
                incrementing = false
            } else {
                incrementing = true
                let newSingleSeq = seqSingle.dupe()
                newSingleSeq.incAtLevel(level: incDepth, removingDeeperLevels: false)
                let ok = newSeq.setSingleSeq(newSingleSeq.value, seqIndex: sortedNote!.seqIndex)
                if ok {
                    seqMods = true
                }
                lastSeq = newSingleSeq.dupe()
            }
            
            if seqMods {
                appendMod(sortedNote: sortedNote!, newSeq: newSeq, newLevel: nil)
            }
            
            sortedNote = nextNote
            position = nextPosition
            starting = false
            (nextNote, nextPosition) = io.nextNote(position)
        }
        
        let firstNote = applyUpdates(updateSeq: true, updateTags: false)
        
        return (updatedSeqs.count, firstNote)
    }
    
    /// Resequence a range of Notes.
    /// - Parameters:
    ///   - startingRow: The first row to be resequenced.
    ///   - endingRow:   The last row to be resequenced.
    ///   - newSeqValue: The new value to be assigned as the Seq value for the first note in the range.
    /// - Returns: Updates the notes in the range to retain their Seq depth, but be numbered consecutively
    ///
    ///     starting with the new Seq value of the starting note.
    public func renumberRange(startingRow: Int, endingRow: Int, newSeqValue: String) -> SortedNote? {
        
        let (ready, _) = readyForUpdates()
        guard ready else { return nil }
        
        guard let firstNote = io.getSortedNote(at: startingRow) else { return nil }
        let oldSingleSeq = firstNote.seqSingleValue
        let newEntireSeq = firstNote.note.seq.dupe()
        _ = newEntireSeq.setSingleSeq(newSeqValue, seqIndex: firstNote.seqIndex)
        let newSingleSeq = newEntireSeq.getSingleSeq(seqIndex: firstNote.seqIndex)
        guard newSingleSeq != nil else { return nil }
        
        // Adjust note's level value, if the number of seq levels is changing
        var newLevel: LevelValue?
        var levelAdd: Int = 0
        
        // Check for changing levels
        levelAdd = newSingleSeq!.numberOfLevels - oldSingleSeq.numberOfLevels
        if levelAdd != 0 {
            newLevel = firstNote.note.level.dupe()
            newLevel!.add(levelsToAdd: levelAdd, config: collection.levelConfig)
        }

        appendMod(sortedNote: firstNote, newSeq: newEntireSeq, newLevel: newLevel)
        
        var priorNewSingleSeq = newSingleSeq!.dupe()
        // var priorOldSeqDepth = oldSingleSeq.maxLevel
        var priorOldSingleSeq = oldSingleSeq.dupe()
        
        var nextRow = startingRow + 1
        while nextRow <= endingRow {
            
            // Get the sorted note for the next row
            guard let nextNote = io.getSortedNote(at: nextRow) else {
                nextRow = endingRow
                break
            }
            
            // Update Seq value
            // let nextOldSingleSeq = priorNewSingleSeq
            let nextOldSingleSeq = nextNote.seqSingleValue
            let nextNewEntireSeq = nextNote.note.seq.dupe()
            let relationshipToPrior = nextOldSingleSeq.maxLevel - priorOldSingleSeq.maxLevel
            let incLevel =  priorNewSingleSeq.maxLevel + relationshipToPrior
            let singleSeq = priorNewSingleSeq.dupe()
            singleSeq.incAtLevel(level: incLevel, removingDeeperLevels: true)
            _ = nextNewEntireSeq.setSingleSeq(singleSeq.value, seqIndex: nextNote.seqIndex)
            
            // Update level, if requested.
            var newLevel: LevelValue? = nil
            if levelAdd != 0 {
                newLevel = nextNote.note.level.dupe()
                newLevel!.add(levelsToAdd: levelAdd, config: collection.levelConfig)
            }
            
            appendMod(sortedNote: nextNote, newSeq: nextNewEntireSeq, newLevel: newLevel)
            
            priorNewSingleSeq = singleSeq
            priorOldSingleSeq = nextOldSingleSeq
            nextRow += 1
        }
        
        return applyUpdates(updateSeq: true, updateTags: false)
    }
    
    /// Update Seq and/or Tags field based on outline structure (based on seq + level).
    public func outlineUpdatesBasedOnLevel(updateSeq: Bool, tagsAction: SeqTagsAction) -> (Int, String) {
        
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
        
        var (sortedNote, position) = io.firstNote()
        while sortedNote != nil {
            
            // Process the next note.
            let noteLevel = sortedNote!.note.level.getInt()
            
            // Calculate the new seq value.
            var newSeq = ""
            if first && !sortedNote!.note.hasSeq() && noteLevel == low {
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
            let tagTitle = TagsValue.tagify(sortedNote!.note.title.value)
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
            let currTags = sortedNote!.note.tags
            var replaced = false
            for tagValue in currTags.tags {
                let tag = tagValue.value
                if tag.hasPrefix(levelsHead) {
                    if tagsAction == .update {
                        if newTags.count > 0 { newTags.append(",") }
                        newTags.append(newLevelTags)
                    }
                    replaced = true
                } else {
                    if newTags.count > 0 { newTags.append(",") }
                    newTags.append(tag)
                }
            }
            if !replaced && tagsAction == .update {
                if newTags.count > 0 { newTags.append(",") }
                newTags.append(newLevelTags)
            }
            
            // Now store any updates, so that we can apply them later.
            var updateNote = false
            
            if updateSeq && newSeq != sortedNote!.seqSingleValue.value {
                updateNote = true
            }
            
            if (tagsAction == .update || tagsAction == .remove) && newTags != sortedNote!.note.tags.value {
                updateNote = true
            }
            
            if updateNote {
                notesToUpdate.append(sortedNote!)
                if updateSeq {
                    let newSeqValue = seqType.createValue(newSeq) as! SeqValue
                    updatedSeqs.append(newSeqValue)
                }
                if tagsAction == .update || tagsAction == .remove {
                    updatedTags.append(newTags)
                }
            }
            
            first = false
            (sortedNote, position) = io!.nextNote(position)
        }
        
        // Now perform the updates.
        _ = applyUpdates(updateSeq: updateSeq, updateTags: (tagsAction == .update || tagsAction == .remove))
        
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
    func appendMod(sortedNote: SortedNote, newSeq: SeqValue, newLevel: LevelValue?) {
        updatedSeqs.append(newSeq)
        notesToUpdate.append(sortedNote)
        if newLevel != nil {
            updatedLevels.append(newLevel!)
        }
    }
    
    
    /// Apply the generated updates to the Collection.
    /// - Parameters:
    ///   - updateSeq: Are we updating Seq values?
    ///   - updateTags: Are we updating Tags?
    /// - Returns: The first note modified, if any.
    func applyUpdates(updateSeq: Bool, updateTags: Bool) -> SortedNote? {
        
        // Now apply the new sequences from the top down, in order to
        // keep notes from changing position in the sorted list when we
        // are incrementing.
        
        var firstModNote: SortedNote?
        var updateIndex = notesToUpdate.count - 1
        while updateIndex >= 0 {
            let originalNote = notesToUpdate[updateIndex]
            let modNote = originalNote.copy()
            var setOK = true
            var modOK = true
            if updateSeq && updatedSeqs.count == notesToUpdate.count {
                let newSeq = updatedSeqs[updateIndex]
                setOK = modNote.setSeq(newSeq.value)
            }
            if updateTags && updatedTags.count == notesToUpdate.count && setOK {
                let newTags = updatedTags[updateIndex]
                setOK = modNote.note.setTags(newTags)
            }
            if updatedLevels.count == notesToUpdate.count
                && setOK
                && collection.levelFieldDef != nil {
                let newLevel = updatedLevels[updateIndex]
                setOK = modNote.note.setLevel(newLevel)
            }
            let (note, position) = io.modNote(oldNote: originalNote.note, newNote: modNote.note)
            modOK = (note != nil && position.valid)
            if (!setOK) || (!modOK) {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "Sequencer",
                                  level: .error,
                                  message: "Trouble updating Note titled \(modNote.note.title.value)")
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "Sequencer",
                                  level: .error,
                                  message: "setok = \(setOK) modok = \(modOK)")
            }
            firstModNote = modNote
            
            updateIndex -= 1
        }
        return firstModNote
    }
}
