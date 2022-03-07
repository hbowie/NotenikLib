//
//  SeqFormatter.swift
//  NotenikLib
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 3/7/22.
//

import Foundation

public class SeqFormatter {
    
    var formatStack: [SeqSegmentFormatter] = []
    var sepChar: Character = "."
    
    public init() {
        
    }
    
    public init(with codes: String) {
        set(to: codes)
    }
    
    public func format(seq: SeqValue) -> String {
        var formatted = ""
        var ix = 0
        for segment in seq.seqStack.segments {
            var segmentFormatter = SeqSegmentFormatter()
            if ix < formatStack.count {
                segmentFormatter = formatStack[ix]
            }
            formatted.append(segmentFormatter.format(segment: segment, soFar: formatted, sepChar: sepChar))
            ix += 1
        }
        return formatted
    }
    
    public func set(to codes: String) {
        let codeArray = codes.components(separatedBy: "|")
        for subCodes in codeArray {
            formatStack.append(SeqSegmentFormatter(with: subCodes))
        }
    }
    
    public func toCodes() -> String {
        var codes = ""
        for formatter in formatStack {
            if !codes.isEmpty {
                codes.append("|")
            }
            codes.append(formatter.toCodes())
        }
        return codes
    }
    
}
