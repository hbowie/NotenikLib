//
//  SeqStack.swift
//  Notenik
//
//  Created by Herb Bowie on 3/10/20.
//  Copyright © 2021 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An array containing all the Sequence Segments in a Sequence Value.
class SeqStack {
    
    var segments: [SeqSegment] = []
    
    var seqParms: SeqParms!
    
    public init(seqParms: SeqParms) {
        self.seqParms = seqParms
    }
    
    /// Perform a deep copy of this object to create a new one.
    public func dupe() -> SeqStack {
        let newStack = SeqStack(seqParms: seqParms)
        for segment in segments {
            let newSegment = segment.dupe()
            newStack.segments.append(newSegment)
        }
        return newStack
    }
    
    /// Add another segment to the stack.
    func append(_ segment: SeqSegment) {
        segments.append(segment)
        checkLargestNumberOfSegments()
    }
    
    func checkLargestNumberOfSegments() {
        if segments.count > seqParms.largestNumberOfSegments {
            seqParms.largestNumberOfSegments = segments.count
        }
    }
    
    /// Return the number of segments in the stack.
    var count: Int {
        return segments.count
    }
    
    /// The maximum allowable value for an index into the array, based on its current size.
    var max: Int {
        return segments.count - 1
    }
    
    var possibleTimeStack: Bool {
        for segment in segments {
            if !segment.possibleTimeSegment {
                return false
            }
        }
        return true
    }
    
    var value: String {
        if segments.count == 0 {
            return ""
        } else if segments.count == 1 {
            return segments[0].valueWithPunctuation(position: 0)
        } else {
            var str = ""
            var position = 0
            let timeStack = possibleTimeStack
            for segment in segments {
                str.append(segment.valueWithPunctuation(position: position, possibleTimeStack: timeStack))
                position += 1
            }
            return str
        }
    }
    
    /// A sort key for the stack, with appropriate padding added to each segment. 
    var sortKey: String {
        var key = ""
        var segIndex = 0
        var pm = false
        if count > 2 && segments[max].amPM && segments[max].value.lowercased() == "pm" && possibleTimeStack {
            pm = true
        }
        for segment in segments {
            var appended = false
            if pm && segIndex == 0 {
                var adjusted = Int(segment.value)
                if adjusted != nil {
                    if adjusted! < 12 {
                        adjusted! += 12
                    }
                    let adjustedValue = "\(adjusted!)"
                    var adjustedChars = adjustedValue.count
                    while adjustedChars < 8 {
                        key.append("0")
                        adjustedChars += 1
                    }
                    key.append(adjustedValue)
                    appended = true
                }
            }
            if !appended {
                if segIndex == 0 {
                    key.append(segment.pad(padChar: "0", padTo: 8, padLeft: true))
                } else {
                    key.append(segment.pad(padChar: "0", padTo: 4, padLeft: true))
                }
            }
            // if segIndex < max {
            key.append(".")
            // }
            segIndex += 1
        }
        while segIndex < seqParms.largestNumberOfSegments {
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
