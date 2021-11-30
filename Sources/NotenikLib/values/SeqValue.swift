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
    
    public convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    public func newChild() {
        var start = self.value
        start.append(".1")
        set(start)
    }
    
    public func dropLevelAndInc() {
        seqStack.segments.removeLast()
        if seqStack.segments[seqStack.max].endedByPunctuation {
            seqStack.segments[seqStack.max].removePunctuation()
        }
        let dropped = seqStack.value
        set(dropped)
        increment()
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
    
    public func increment () {
        increment(atDepth: seqStack.max)
    }
    
    /// Increment the sequence value by 1, at the indicated depth.
    public func increment (atDepth: Int) {

        guard atDepth >= 0 else { return }
        var depth = atDepth
        if depth > seqStack.max {
            depth = seqStack.max
        }
        if depth < 0 {
            depth = 0
        }
        seqStack.segments[depth].increment()
        super.set(seqStack.value)
    } // end function increment
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return seqStack.sortKey
    }
    
}
