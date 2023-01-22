//
//  SeqSegment.swift
//  Notenik
//
//  Created by Herb Bowie on 3/10/20.
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// One segment of a sequence value.
public class SeqSegment {
    
    var value = ""
    var startingPunctuation = ""
    var endingPunctuation = ""
    var padChar:     Character = " "
    var digits       = false
    var letters      = false
    var allUppercase = true
    var numberType:  SeqNumberType = .digits
    
    public init() {
        
    }
    
    public init(startingPunctuation: String) {
        self.startingPunctuation = startingPunctuation
    }
    
    public init(_ text: String) {
        for c in text {
            append(c)
        }
    }
    
    public init(_ text: String, startingPunctuation: String) {
        self.startingPunctuation = startingPunctuation
        for c in text {
            append(c)
        }
    }
    
    /// Perform a deep copy of this object to create a new one. 
    public func dupe() -> SeqSegment {
        let newSegment = SeqSegment()
        newSegment.value = self.value
        newSegment.startingPunctuation = self.startingPunctuation
        newSegment.endingPunctuation = self.endingPunctuation
        newSegment.padChar = self.padChar
        newSegment.digits = self.digits
        newSegment.letters = self.letters
        newSegment.allUppercase = self.allUppercase
        newSegment.numberType = self.numberType
        return newSegment
    }
    
    /// Append another character to the segment value. 
    func append(_ c: Character) {
        if c == "0" && count == 0 {
            padChar = c
            digits = true
        } else if c == " " && startingPunctuation == ":" && numberType == .digits && value.count <= 2 {
            if value.count == 0 {
                value.append("00")
            }
            endingPunctuation.append(c)
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
        } else if c == "." || c == "-" || c == ":" {
            if value.count == 0 {
                value.append("0")
            }
            endingPunctuation.append(c)
        } // end character evaluation
        
        if digits {
            if letters {
                numberType = .mixed
            } else {
                numberType = .digits
            }
        } else if letters {
            if digits {
                numberType = .mixed
            } else if allUppercase {
                numberType = .uppercase
            } else {
                numberType = .lowercase
            }
        }
    }
    
    /// The number of characters in the segment value.
    var count: Int {
        return value.count
    }
    
    var endedByPunctuation: Bool {
        return !endingPunctuation.isEmpty
    }
    
    var possibleTimeSegment: Bool {
        if numberType == .digits && value.count < 3 && (startingPunctuation == ":" || startingPunctuation == "") {
            return true
        } else if amPM {
            return true
        }
        return false
    }
    
    var amPM: Bool {
        guard value.count == 2 else { return false }
        guard numberType == .lowercase || numberType == .uppercase else { return false }
        let lowered = value.lowercased()
        if lowered == "am" || lowered == "pm" {
            return true
        }
        return false
    }
    
    func removePunctuation() {
        endingPunctuation = ""
    }
    
    func valueWithPunctuation(position: Int, possibleTimeStack: Bool = false) -> String {
        
        var str = ""
        
        if possibleTimeStack && numberType == .digits && value.count < 2 {
            if value.count == 0 {
                str = "00" + endingPunctuation
            } else {
                str = "0" + value + endingPunctuation
            }
        } else if value.count == 0 && (position > 0 || endingPunctuation.count > 0) {
            str = "0" + endingPunctuation
        } else {
            str = value + endingPunctuation
        }
        return str
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
    
    /// Increment the sequence value by 1.
    public func increment() {
            
        guard value.count > 0 else {
            value = "1"
            return
        }
 
        var carryon = true
        var c: Character = " "
        var newChar: Character = "1"
        var i = value.index(before: value.endIndex)
        
        // Keep incrementing as long as we have 1 to carry to the next column to the left
        while carryon {
            // Get the character to be incremented on this pass
            c = value[i]
            
            // Now try to increment it.
            newChar = StringUtils.increment(c)
            if newChar == c {
                carryon = false
            } else {
                value.remove(at: i)
                value.insert(newChar, at: i)
                carryon = newChar < c
            }
            
            // Now decrement the index as needed.
            if carryon {
                if i > value.startIndex {
                    i = value.index(before: i)
                } else {
                    if digits {
                        c = "0"
                    } else {
                        c = " "
                    }
                    newChar = StringUtils.increment(c)
                    value.insert(newChar, at: value.startIndex)
                    carryon = false
                }
            }
        } // end while carrying on
    } // end function increment
    
}
