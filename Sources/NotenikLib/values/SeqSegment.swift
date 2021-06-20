//
//  SeqSegment.swift
//  Notenik
//
//  Created by Herb Bowie on 3/10/20.
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// One segment of a sequence value.
class SeqSegment {
    
    var value = ""
    var punctuation = ""
    var padChar:     Character = " "
    var digits       = false
    var letters      = false
    var allUppercase = true
    
    /// Append another character to the segment value. 
    func append(_ c: Character) {
        if c == "0" && count == 0 {
            padChar = c
        } else if c.isWhitespace {
            // Ignore whitespace
        } else if c == "$" {
            value.append(c)
        } else if c == "'" {
            value.append(c)
        } else if c == "_" {
            value.append(c)
        } else if c == "," {
            value.append(c)
        } else if StringUtils.isAlpha(c) {
            value.append(c)
            letters = true
            if StringUtils.isLower(c) {
                allUppercase = false
            }
        } else if StringUtils.isDigit(c) {
            value.append(c)
            digits = true
        } else if c == "." || c == "-" {
            if value.count == 0 {
                value.append("0")
            }
            punctuation.append(c)
        } // end character evaluation
    }
    
    /// The number of characters in the segment value.
    var count: Int {
        return value.count
    }
    
    var endedByPunctuation: Bool {
        return !punctuation.isEmpty
    }
    
    var valueWithPunctuation: String {
        return value + punctuation
    }
    
    func pad(padChar: Character, padTo: Int, padLeft: Bool = true) -> String {
        var padded = ""
        if padLeft {
            var chars = count
            while chars < padTo {
                padded.append(padChar)
                chars += 1
            }
        }
        padded.append(value)
        if !padLeft {
            var chars = padded.count
            while chars < padTo {
                padded.append(padChar)
                chars += 1
            }
        }
        return padded
    }
    
    /// Increment the sequence value by 1, at the indicated depth.
    public func increment() {
            
        var carryon = true
        var c: Character = " "
        var i = value.index(before: value.endIndex)
        
        // Keep incrementing as long as we have 1 to carry to the next column to the left
        while carryon {
            // Get the character to be incremented on this pass
            if i < value.startIndex {
                if digits {
                    c = "0"
                } else {
                    c = " "
                }
                value.insert(c, at: value.startIndex)
                i = value.startIndex
            } else {
                c = value[i]
            }
            
            // Now try to increment it

            let newChar = StringUtils.increment(c)
            if newChar == c {
                carryon = false
            } else {
                value.remove(at: i)
                value.insert(newChar, at: i)
                carryon = newChar < c
            }
            if carryon {
                i = value.index(before: i)
            }
        } // end while carrying on
    } // end function increment
    
}
