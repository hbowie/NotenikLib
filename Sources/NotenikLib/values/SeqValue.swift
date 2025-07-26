//
//  SeqValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/5/18.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A String Value interpreted as a sequence number, or revision letter, or version number.
///
/// Such a value may contain letters and digits and one or more periods or hyphens or dollar signs.
public class SeqValue: StringValue, MultiValues, Collection, Sequence {
    
    var seqParms: SeqParms!
    
    var seqList: [SeqSingleValue] = []
    
    public var firstSeq: SeqSingleValue {
        if seqList.isEmpty {
            seqList.append(SeqSingleValue("", seqParms: seqParms))
        }
        return seqList[0]
    }
    
    var seqStack: SeqStack! {
        return firstSeq.seqStack
    }
    
    var originalValue = ""
    
    public override init() {
        super.init()
        print("SeqValue.init without SeqParms!")
    }
    
    public init(seqParms: SeqParms) {
        super.init()
        self.seqParms = seqParms
    }
    
    public init (_ value: String, seqParms: SeqParms) {
        super.init()
        self.seqParms = seqParms
        set(value)
    }
    
    /// Set the Note's Sequence value
    public func setSingleSeq(_ seq: String, seqIndex: Int) -> Bool {
        guard seqIndex >= 0 && seqIndex < multiCount else {
            return false
        }
        let newSeq = SeqSingleValue(seq, seqParms: seqParms)
        seqList[seqIndex] = newSeq
        setWithLatestValues()
        return true
    }
    
    public func setWithLatestValues() {
        super.set(multiConcat)
    }
    
    /// Set this sequence value to the provided string
    public override func set (_ value : String) {
        super.set(value)
        originalValue = value
        seqList = []
        var nextSingleStr = ""
        for c in value {
            if c == ";" && !nextSingleStr.isEmpty {
                let nextSingleSeq = SeqSingleValue(nextSingleStr, seqParms: seqParms)
                seqList.append(nextSingleSeq)
                nextSingleStr = ""
            } else if c.isWhitespace && nextSingleStr.isEmpty {
                // drop the space
            } else {
                nextSingleStr.append(c)
            }
        }
        if !nextSingleStr.isEmpty {
            let nextSingleSeq = SeqSingleValue(nextSingleStr, seqParms: seqParms)
            seqList.append(nextSingleSeq)
        }
        setWithLatestValues()
    } // end set function
    
    public func dupe() -> SeqValue {
        return SeqValue(multiConcat, seqParms: seqParms)
    }
    
    public func increment() {
        for singleSeq in seqList {
            singleSeq.increment()
        }
        setWithLatestValues()
    }
    
    /// The number of levels (separated by dots or dashes) in the Seq value. 
    public var numberOfLevels: Int {
        if seqList.isEmpty {
            return 0
        } else {
            return seqList[0].numberOfLevels
        }
    }
    
    public var maxLevel: Int {
        if seqList.isEmpty {
            return 0
        } else {
            return seqList[0].maxLevel
        }
    }
    
    public func incByLevels(originalLevel: LevelValue, newLevel: LevelValue) {
        for singleSeq in seqList {
            singleSeq.incByLevels(originalLevel: originalLevel, newLevel: newLevel)
        }
        setWithLatestValues()
    }
    
    /// Increment the current sequence value by 1, at the indicated level.
    /// - Parameter level: 0 = first level, 1 = second (following a dot or a dash), etc.
    public func incAtLevel(level: Int, removingDeeperLevels: Bool) {
        
        var i = 0
        while i < seqList.count {
            let seqSingleValue = seqList[i]
            seqSingleValue.incAtLevel(level: level, removingDeeperLevels: removingDeeperLevels)
            i += 1
        }
    }
    
    public func genSortKey(seqIndex: Int = 0) -> String {
        if seqList.count == 0 {
            let seqsingleValue = SeqSingleValue("", seqParms: seqParms)
            return seqsingleValue.sortKey
        } else if seqIndex >= 0 && seqIndex < seqList.count {
            return seqList[seqIndex].sortKey
        } else {
            return seqList[0].sortKey
        }
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public override var sortKey: String {
        var concat = ""
        var i = 0
        while i < seqList.count {
            let singleSeq = seqList[i]
            if !concat.isEmpty {
                concat.append(multiDelimiter)
            }
            concat.append(singleSeq.sortKey)
            i += 1
        }
        return concat
    }
    
    public func getSingleSeq(seqIndex: Int) -> SeqSingleValue? {
        if seqIndex >= 0 && seqIndex < seqList.count {
            return seqList[seqIndex]
        } else {
            return nil
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Conformance to MultiValues protocol.
    //
    // -----------------------------------------------------------
    
    /// The number of sub-values within this multi-value.
    public var multiCount: Int {
        return seqList.count
    }
    
    /// Return a sub-value at the given index position.
    /// - Returns: The indicated sub-value, for a valid index, otherwise nil.
    public func multiAt(_ index: Int) -> String? {
        guard index >= 0 && index < seqList.count else {
            return nil
        }
        return seqList[index].value
    }
    
    /// The preferred delimiter to use to separate each sub-value when combining into a String.
    public var multiDelimiter: String {
        return "; "
    }
    
    /// Append a new value to the list.
    public func append(_ str: String) {
        originalValue.append(multiDelimiter)
        originalValue.append(str)
        let nextSingleSeq = SeqSingleValue(str, seqParms: seqParms)
        seqList.append(nextSingleSeq)
        setWithLatestValues()
    }
    
    public var multiConcat: String {
        var concat = ""
        var i = 0
        while i < seqList.count {
            let singleSeq = seqList[i]
            if !concat.isEmpty {
                concat.append(multiDelimiter)
            }
            concat.append(singleSeq.value)
            i += 1
        }
        return concat
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Conformance to Collection Protocol.
    //
    // -----------------------------------------------------------
    
    public typealias Index = Int
    public typealias Element = SeqSingleValue

    public var startIndex: Index { return 0 }
    public var endIndex:   Index { return seqList.count }
    public subscript(position: Index) -> Element {
        return seqList[position]
    }
    public func index(after i: Index) -> Index {
        return i + 1
    }

    
    // -----------------------------------------------------------
    //
    // MARK: Conformance to Sequence protocol.
    //
    // -----------------------------------------------------------
    
    /// Factory method to return an iterator.
    public func makeIterator() -> SeqIterator {
        return SeqIterator(self)
    }
    
}
