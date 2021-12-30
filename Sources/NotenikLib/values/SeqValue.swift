//
//  SeqValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/5/18.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A String Value interpreted as a sequence number, or revision letter, or version number.
///
/// Such a value may contain letters and digits and one or more periods or hyphens or dollar signs.
public class SeqValue: StringValue {
    
    var seqStack = SeqStack()
    
    public override init() {
        super.init()
    }
    
    public convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    public func dupe() -> SeqValue {
        let newSeq = SeqValue()
        newSeq.value = self.value
        newSeq.seqStack = self.seqStack.dupe()
        return newSeq
    }
    
    public func increment() {
        incAtLevel(level: seqStack.max, removingDeeperLevels: false)
    }
    
    /// The number of levels (separated by dots or dashes) in the Seq value. 
    public var numberOfLevels: Int {
        return seqStack.count
    }
    
    public var maxLevel: Int {
        return seqStack.max
    }
    
    public func incByLevels(originalLevel: LevelValue, newLevel: LevelValue) {
        let levelToInc = newLevel.getInt() - originalLevel.getInt() + seqStack.max
        incAtLevel(level: levelToInc, removingDeeperLevels: true)
    }
    
    /// Increment the current sequence value by 1, at the indicated level.
    /// - Parameter level: 0 = first level, 1 = second (following a dot or a dash), etc.
    public func incAtLevel(level: Int, removingDeeperLevels: Bool) {
        
        // If level is deeper than current sequence, add segments
        // as needed to get to the specified level.
        while level > seqStack.max {
            if !seqStack.segments[seqStack.max].endedByPunctuation {
                seqStack.segments[seqStack.max].punctuation = "."
            }
            seqStack.append(SeqSegment("0"))
        }
        
        // If level is shallower than current sequence, remove segments
        // as needed to get to the specified level.
        if removingDeeperLevels {
            while level < seqStack.max {
                seqStack.segments.removeLast()
                if seqStack.segments[seqStack.max].endedByPunctuation {
                    seqStack.segments[seqStack.max].removePunctuation()
                }
            }
        }
        seqStack.segments[level].increment()
        let newValue = seqStack.value
        set(newValue)
    }
    
    /// Set this sequence value to the provided string
    override func set (_ value : String) {
        super.set(value)
        seqStack = SeqStack()
        var nextSegment = SeqSegment()
        var lastPunctuation = ""
        
        for c in value {
            nextSegment.append(c)
            if nextSegment.endedByPunctuation {
                lastPunctuation = nextSegment.punctuation
                seqStack.append(nextSegment)
                nextSegment = SeqSegment()
            }
        }
        if nextSegment.count > 0 || lastPunctuation.count > 0 {
            seqStack.append(nextSegment)
        }
        super.set(seqStack.value)
    } // end set function
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return seqStack.sortKey
    }
    
}
