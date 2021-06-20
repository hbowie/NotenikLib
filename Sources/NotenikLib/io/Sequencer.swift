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

/// Can be used to increment the sequence of one Note and following Notes.
public class Sequencer {
    
    /// Increment the sequence of one Note along with following Notes
    /// that would otherwise now be less than or equal to the
    /// sequences of prior Notes.
    ///
    /// - Parameters:
    ///   - io: The I/O Module for the Collection being accessed.
    ///   - startingNote: The first Note whose sequence is to be incremented.
    /// - Returns: The number of Notes having their sequences incremented.
    public static func incrementSeq(io: NotenikIO, startingNote: Note, incMajor: Bool = false) -> Int {
        
        guard io.collectionOpen else { return 0 }
        guard io.collection != nil else { return 0 }
        guard startingNote.hasSeq() else { return 0 }
        
        let sortParm = io.collection!.sortParm
        guard sortParm == .seqPlusTitle || sortParm == .tasksBySeq else { return 0 }
        
        var newSeqs: [SeqValue] = []
        var notes:   [Note] = []
        
        var incrementing = true
        var incDepth = 0
        var position = io.positionOfNote(startingNote)
        var note: Note? = startingNote
        var (nextNote, nextPosition) = io.nextNote(position)
        var starting = true
        var lastSeq: SeqValue?
        while incrementing && note != nil && position.valid {
            let seq = note!.seq
            
            // Special logic for first note processed
            if starting {
                lastSeq = SeqValue(seq.value)
                if incMajor {
                    incDepth = 0
                } else {
                    incDepth = seq.seqStack.max
                }
                starting = false
            }
            
            // See if the current sequence is already greater than the last one
            let greater = (seq > lastSeq!)
            
            // See if we're done, or need to keep going
            if greater {
                incrementing = false
            } else {
                incrementing = true
                let newSeq = SeqValue(seq.value)
                newSeq.increment(atDepth: incDepth)
                newSeqs.append(newSeq)
                notes.append(note!)
                lastSeq = SeqValue(newSeq.value)
            }
            
            starting = false
            
            note = nextNote
            position = nextPosition
            (nextNote, nextPosition) = io.nextNote(position)
        }
        
        // Now apply the new sequences from the top down, in order to
        // keep notes from changing position in the sorted list.
        var index = newSeqs.count - 1
        while index >= 0 {
            let newSeq = newSeqs[index]
            let noteToMod = notes[index]
            let setOK = noteToMod.setSeq(newSeq.value)
            let writeOK = io.writeNote(noteToMod)
            if (!setOK) || (!writeOK) {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "Sequencer",
                                  level: .error,
                                  message: "Trouble updating Note titled \(noteToMod.title.value)")
            }
            index -= 1
        }
        
        return newSeqs.count
    }
}
