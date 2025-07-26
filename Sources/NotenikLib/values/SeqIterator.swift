//
//  SeqIterator.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/18/25.
//

import Foundation

/// Interate over single Seq values.
public class SeqIterator: IteratorProtocol {
    let seqValue: SeqValue
    var nextIndex = 0

    public init(_ seqValue: SeqValue) {
        self.seqValue = seqValue
    }

    public func next() -> SeqSingleValue? {
        guard nextIndex > 0 && nextIndex < seqValue.multiCount else { return nil }
        let nextSeq = seqValue[nextIndex]
        nextIndex = seqValue.index(after: nextIndex)
        return nextSeq
    }
}
