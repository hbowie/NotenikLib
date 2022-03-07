//
//  SeqSegmentFormatter.swift
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

public class SeqSegmentFormatter {
    
    var exclude = false
    var padToLength = 0
    var prefix = ""
    var suffix = ""
    
    public init() {
        
    }
    
    public init(with codes: String) {
        set(to: codes)
    }
    
    public func format(segment: SeqSegment, soFar: String, sepChar: Character) -> String {
        
        guard !exclude else { return "" }
        
        var seg = ""
        
        // Add prefix when requested
        if prefix.isEmpty {
            if !soFar.isEmpty {
                let lastChar = soFar.last!
                if lastChar == sepChar || lastChar == "." || lastChar == "-" || lastChar.isPunctuation || lastChar.isWhitespace {
                    // leave well enough alone
                } else {
                    seg.append(sepChar)
                }
            }
        } else {
            seg.append(prefix)
        }
        
        // Pad when requested
        var padCount = padToLength - segment.value.count
        var padChar = " "
        if segment.numberType == .digits {
            padChar = "0"
        }
        while padCount > 0 {
            seg.append(padChar)
            padCount -= 1
        }
        
        // Add value
        seg.append(segment.value)
        
        // Add suffix when requested.
        seg.append(suffix)
        
        return seg
    }
    
    public func set(to codes: String) {
        
        exclude = false
        padToLength = 0
        prefix = ""
        suffix = ""
        
        var prefixPassed = false
        
        for char in codes {
            switch char.lowercased() {
            case "_":
                prefixPassed = true
            case "n":
                padToLength += 1
                prefixPassed = true
            case "x":
                exclude = true
                prefixPassed = true
            default:
                if prefixPassed {
                    suffix.append(char)
                } else {
                    prefix.append(char)
                }
            } // end of char switch
        } // end of codes
    } // end of set function
    
    public func toCodes() -> String {
        guard !exclude else { return "x"}
        var codes = ""
        codes.append(prefix)
        if padToLength == 0 {
            codes.append("_")
        } else {
            var padCount = padToLength
            while padCount > 0 {
                codes.append("n")
                padCount -= 1
            }
        }
        codes.append(suffix)
        return codes
    }
}
