//
//  SeqStack.swift
//  Notenik
//
//  Created by Herb Bowie on 3/10/20.
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An array containing all the Sequence Segments in a Sequence Value.
class SeqStack {
    
    var segments: [SeqSegment] = []
    
    /// Add another segment to the stack.
    func append(_ segment: SeqSegment) {
        segments.append(segment)
    }
    
    /// Return the number of segments in the stack.
    var count: Int {
        return segments.count
    }
    
    /// The maximum allowable value for an index into the array, based on its current size.
    var max: Int {
        return segments.count - 1
    }
    
    var value: String {
        if segments.count == 0 {
            return ""
        } else if segments.count == 1 {
            return segments[0].valueWithPunctuation(position: 0)
        } else {
            var str = ""
            var position = 0
            for segment in segments {
                str.append(segment.valueWithPunctuation(position: position))
                position += 1
            }
            return str
        }
    }
    
    /// A sort key for the stack, with appropriate padding added to each segment. 
    var sortKey: String {
        var key = ""
        var segIndex = 0
        for segment in segments {
            if segIndex == 0 {
                key.append(segment.pad(padChar: "0", padTo: 8, padLeft: true))
            } else {
                key.append(segment.pad(padChar: "0", padTo: 4, padLeft: true))
            }
            // if segIndex < max {
                key.append(".")
            // }
            segIndex += 1
        }
        while segIndex < 6 {
            if segIndex == 0 {
                key.append("00000000.")
            } else {
                key.append("0000.")
            }
            segIndex += 1
        }
        return key
    }
    
}
