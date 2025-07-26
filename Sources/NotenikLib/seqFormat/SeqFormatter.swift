//
//  SeqFormatter.swift
//  NotenikLib
//
//  Copyright © 2022 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 3/7/22.
//

import Foundation

import NotenikUtils

public class SeqFormatter {
    
    var formatStack: [String] = []
    var sepChar: Character = "."
    
    public init() {
        
    }
    
    public init(with codes: String) {
        set(to: codes)
    }
    
    public var isEmpty: Bool {
        return formatStack.isEmpty
    }
    
    public func format(seq: SeqSingleValue, full: Bool = false) -> (String, Int) {
        
        // If no formatting codes, simply return the seq value.
        guard !formatStack.isEmpty else {
            return (seq.value, 0)
        }
        
        // Figure out wich format string to use.
        var stackIx = 0
        if !full {
            stackIx = seq.numberOfLevels
        }
        if stackIx < 0 || stackIx >= formatStack.count {
            return (seq.value, 0)
        }
        let subCodes = formatStack[stackIx]
        
        // Now apply formatting codes.
        var formatted = ""
        var segmentIx = 0
        var padLength = 1
        var charIx = subCodes.startIndex
        var skipped = 0
        while charIx < subCodes.endIndex {
            let nextIx = subCodes.index(after: charIx)
            let char = subCodes[charIx]
            charIx = nextIx
            
            // Ignore any leading white space
            if char.isWhitespace && formatted.isEmpty {
                continue
            }
            
            let lowerChar = char.lowercased()
            
            // The letter 'X' indicates we should skip this segment
            if lowerChar == "x" {
                segmentIx += 1
                skipped += 1
                continue
            }
            
            // If nothing else meaningful, add it to the output as a literal
            switch lowerChar {
            case "n", "i", "a":
                break
            default:
                var done = false
                if full && segmentIx >= seq.seqStack.segments.count {
                    done = true
                }
                if !full && segmentIx > seq.seqStack.segments.count {
                    done = true
                }
                if !done {
                    formatted.append(char)
                }
                continue
            }
            
            // Try to get the next seq seqment to be output.
            var segment: SeqSegment?
            if segmentIx < seq.seqStack.segments.count {
                segment = seq.seqStack.segments[segmentIx]
                segmentIx += 1
            } else {
                continue
            }
            
            // Get the following char, and its lowercase value
            var nextChar: Character = " "
            if nextIx < subCodes.endIndex {
                nextChar = subCodes[nextIx]
            }
            let nextCharLower = nextChar.lowercased()
            
            // If multiple n's in a rew, they imply padding.
            if lowerChar == "n" && nextCharLower == "n" {
                padLength += 1
                continue
            }
            
            // Format the next segment value as requested.
            if segment != nil {
                switch char {
                case "n", "N":
                    var padCount = padLength - segment!.value.count
                    var padChar = " "
                    if segment!.numberType == .digits {
                        padChar = "0"
                    }
                    while padCount > 0 {
                        formatted.append(padChar)
                        padCount -= 1
                    }
                    formatted.append(segment!.value)
                    padLength = 1
                default:
                    formatted.append(NumberUtils.toAlternate(segment!.value, altType: char))
                }
            }
        }
        return (formatted, skipped)
    }
    
    /// Reverse the formatting.
    public func unformat(_ str: String) -> String {
        
        var unformatted = ""
        
        // If no formatting codes, simply return the seq value.
        guard !formatStack.isEmpty else {
            return str
        }
        
        let subCodes = formatStack[0]
        guard !subCodes.isEmpty else {
            return str
        }
        
        var formatCode = SeqFormatCode(code: " ")
        var codesIx = subCodes.startIndex
        var codeConsumed = true
        
        var seg = SeqSeg(" ")
        var strIx = str.startIndex
        var segConsumed = true
        
        while codesIx < subCodes.endIndex && strIx < str.endIndex {
            if codeConsumed {
                (formatCode, codesIx) = nextFormatCode(subCodes: subCodes, index: codesIx)
            }
            if segConsumed {
                (seg, strIx) = nextSeqSeg(seq: str, index: strIx)
            }

            codeConsumed = true
            segConsumed = true
            
            switch formatCode.codeLowered {
            case "n":
                switch seg.type {
                case .alpha:
                    appendWithDots(seg.val, toStr: &unformatted)
                case .numeric:
                    appendWithDots(seg.val, toStr: &unformatted)
                case .punctuation:
                    codeConsumed = false
                case .whitespace:
                    codeConsumed = false
                }
            case "?":
                switch seg.type {
                case .alpha:
                    appendWithDots(seg.val, toStr: &unformatted)
                case .numeric:
                    appendWithDots(seg.val, toStr: &unformatted)
                case .punctuation:
                    codeConsumed = false
                case .whitespace:
                    codeConsumed = false
                }
            case "a":
                switch seg.type {
                case .alpha:
                    let number = String(NumberUtils.alphaToInt(seg.val))
                    appendWithDots(number, toStr: &unformatted)
                case .numeric:
                    appendWithDots(seg.val, toStr: &unformatted)
                case .punctuation:
                    codeConsumed = false
                case .whitespace:
                    codeConsumed = false
                }
            case "i":
                switch seg.type {
                case .alpha:
                    let number = String(NumberUtils.romanToInt(seg.val))
                    appendWithDots(number, toStr: &unformatted)
                case .numeric:
                    appendWithDots(seg.val, toStr: &unformatted)
                case .punctuation:
                    codeConsumed = false
                case .whitespace:
                    codeConsumed = false
                }
            case " ":
                switch seg.type {
                case .alpha:
                    segConsumed = false
                case .numeric:
                    segConsumed = false
                case .punctuation:
                    segConsumed = false
                case .whitespace:
                    break
                }
            default:
                switch seg.type {
                case .alpha:
                    segConsumed = false
                case .numeric:
                    segConsumed = false
                case .punctuation:
                    break
                case .whitespace:
                    codeConsumed = false
                }
            }
        }
        
        return unformatted
    }
    
    func appendWithDots(_ add: String, toStr: inout String) {
        if !toStr.isEmpty {
            toStr.append(".")
        }
        toStr.append(add)
    }
    
    func nextFormatCode(subCodes: String, index: String.Index) -> (SeqFormatCode, String.Index) {
        if index >= subCodes.endIndex {
            return (SeqFormatCode(code: "?"), index)
        }
        var currIndex = index
        var nextIndex = subCodes.index(after: currIndex)
        var c = subCodes[currIndex]
        var cAfter: Character = " "
        if nextIndex < subCodes.endIndex {
            cAfter = subCodes[nextIndex]
        }
        while nextIndex < subCodes.endIndex && c.lowercased() == "n" && cAfter.lowercased() == "n" {
            currIndex = nextIndex
            nextIndex = subCodes.index(after: currIndex)
            c = subCodes[currIndex]
            if nextIndex < subCodes.endIndex {
                cAfter = subCodes[nextIndex]
            } else {
                cAfter = " "
            }
        }
        return (SeqFormatCode(code: c), nextIndex)
    }
    
    func nextSeqSeg(seq: String, index: String.Index) -> (SeqSeg, String.Index) {
        if index >= seq.endIndex {
            return (SeqSeg(" "), index)
        }
        let seg = SeqSeg()
        var currIndex = index
        var c = seq[currIndex]
        while currIndex < seq.endIndex && seg.fits(c) {
            seg.append(c)
            currIndex = seq.index(after: currIndex)
            if currIndex < seq.endIndex {
                c = seq[currIndex]
            } else {
                c = " "
            }
        }
        return (seg, currIndex)
    }
    
    public func set(to codes: String) {
        let codeArray = codes.components(separatedBy: "|")
        for subCodes in codeArray {
            if !subCodes.isEmpty {
                formatStack.append(subCodes)
            }
        }
    }
    
    public func toCodes() -> String {
        var codes = ""
        for subCodes in formatStack {
            if !codes.isEmpty {
                codes.append("|")
            }
            codes.append(subCodes)
        }
        return codes
    }
    
}
