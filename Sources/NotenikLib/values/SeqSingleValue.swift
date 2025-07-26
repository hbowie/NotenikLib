//
//  SeqSingleValue.swift
//  Notenik
//
//  Created by Herb Bowie on 7/18/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A String Value interpreted as a sequence number, or revision letter, or version number.
///
/// Such a value may contain letters and digits and one or more periods or hyphens or dollar signs.
public class SeqSingleValue: StringValue {
    
    var seqStack: SeqStack!
    
    var seqParms: SeqParms!
    
    var originalValue = ""
    
    public override init() {
        super.init()
        print("SeqSingleValue.init without SeqParms!")
    }
    
    public init(seqParms: SeqParms) {
        super.init()
        self.seqParms = seqParms
        seqStack = SeqStack(seqParms: seqParms)
    }
    
    public init (_ value: String, seqParms: SeqParms) {
        super.init()
        self.seqParms = seqParms
        seqStack = SeqStack(seqParms: seqParms)
        set(value)
    }
    
    public func dupe() -> SeqSingleValue {
        let newSeq = SeqSingleValue(seqParms: seqParms)
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
            if seqStack.max >= 0 && !seqStack.segments[seqStack.max].endedByPunctuation {
                seqStack.segments[seqStack.max].endingPunctuation = "."
            }
            seqStack.append(SeqSegment("0"))
        }
        
        // If level is shallower than current sequence, remove segments
        // as needed to get to the specified level.
        if removingDeeperLevels {
            while level < seqStack.max {
                seqStack.segments.removeLast()
                if seqStack.max >= 0 {
                    if seqStack.segments[seqStack.max].endedByPunctuation {
                        seqStack.segments[seqStack.max].removePunctuation()
                    }
                }
            }
        }
        if level >= 0 && level < seqStack.count {
            seqStack.segments[level].increment()
        }
        let newValue = seqStack.value
        set(newValue)
    }
    
    /// Set this sequence value to the provided string
    public override func set (_ value : String) {
        super.set(value)
        originalValue = value
        seqStack = SeqStack(seqParms: seqParms)
        var nextSegment = SeqSegment()
        var lastPunctuation = ""
        
        for c in value {
            nextSegment.append(c)
            if nextSegment.endedByPunctuation {
                lastPunctuation = nextSegment.endingPunctuation
                seqStack.append(nextSegment)
                nextSegment = SeqSegment(startingPunctuation: lastPunctuation)
            }
        }
        if nextSegment.count > 0 || lastPunctuation.count > 0 {
            seqStack.append(nextSegment)
        }
        super.set(seqStack.value)
    } // end set function
    
    /// Return a value that can be used as a key for comparison purposes
    public override var sortKey: String {
        return seqStack.sortKey
    }
    
}
