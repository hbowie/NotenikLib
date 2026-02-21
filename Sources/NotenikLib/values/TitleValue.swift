//
//  TitleValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/3/18.
//
//  Copyright © 2019-2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A title field value
public class TitleValue: StringValue {
    
    var trimmed = ""
    var plain = ""
    var common = ""
    var macFileName = ""
    var webFileName = ""
    var html = ""
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Is this value empty?
    public override var isEmpty: Bool {
        return (value.count == 0 || common.count == 0)
    }
    
    /// Does this value have any data stored in it?
    public override var hasData: Bool {
        return (value.count > 0 && common.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public override var sortKey: String {
        return common
    }
    
    public func getTitle(format: TitleFormat) -> String {
        switch format {
        case .trimmed: return value
        case .plain: return plain
        case .common: return common
        case .macFileName: return macFileName
        case .webFileName: return webFileName
        case .html: return html
        }
    }
    
    /// Set a new title value, converting to a lowest common denominator form while we're at it
    public override func set(_ value: String) {
        
        trimmed = ""
        plain = ""
        common = ""
        macFileName = ""
        webFileName = ""
        html = ""

        var spacesPending = false
        
        var startingTagCount = 0
        var charsWithinTags = 0
        var lastChar: Character = " "
        var nextChar: Character = " "
        var closingTag = ""
        var codePending: Bool {
            return closingTag == "</code>"
        }
        var index = value.startIndex
        
        while index < value.endIndex {
            
            // Get our characters ready
            let char: Character = value[index]
            var nextIndex = value.index(after: index)
            if nextIndex < value.endIndex {
                nextChar = value[nextIndex]
            } else {
                nextChar = " "
            }
            let charLowered: Character = char.lowercased().first!
            
            // Evaluate
            if codePending && char.isWhitespace {
                appendSpace()
            } else if codePending && char == "<" {
                appendLessThan()
            } else if codePending && char == ">" {
                appendGreaterThan()
            } else if char.isWhitespace || char.isNewline {
                // Handle blank characters
                if common == "a" || common == "an" || common == "the" {
                    common = ""
                }
                if !trimmed.isEmpty {
                    spacesPending = true
                }
            } else {
                // Handle non-blank characters
                
                // Handle pending spaces, if any
                if spacesPending {
                    appendSpace()
                    spacesPending = false
                }
                
                trimmed.append(char)
                
                if char == "<" {
                    if nextChar != " " {
                        if startingTagCount == 0 {
                            charsWithinTags = 0
                        }
                        startingTagCount += 1
                        html.append("<")
                    } else {
                        plain.append(char)
                        common.append(char)
                        macFileNameAppend(char)
                        webFileName.append("less-than")
                        html.append("&lt;")
                    }
                } else if char == ">" {
                    if startingTagCount > 0 {
                        startingTagCount -= 1
                        if startingTagCount == 0 && charsWithinTags > 0 {
                            plain.removeLast(charsWithinTags)
                            common.removeLast(charsWithinTags - 1)
                            macFileName.removeLast(charsWithinTags)
                            webFileName.removeLast(charsWithinTags)
                            charsWithinTags = 0
                        }
                        html.append(">")
                    } else {
                        plain.append(char)
                        common.append(">")
                        macFileNameAppend(">")
                        webFileName.append("greater-than")
                        html.append("&gt;")
                    }
                } else if char == "=" && startingTagCount == 0 {
                    plainAppend(char)
                    common.append("equals")
                    macFileNameAppend("=")
                    webFileName.append("equals")
                    html.append(char)
                } else if char == "+" && startingTagCount == 0 {
                    plainAppend(char)
                    common.append("plus")
                    macFileNameAppend("+")
                    webFileName.append("plus")
                    html.append(char)
                } else if char.isLetter || char.isNumber  {
                    plainAppend(char)
                    commonAppend(charLowered)
                    macFileNameAppend(char)
                    webFileNameAppend(charLowered)
                    html.append(char)
                    if startingTagCount > 0 {
                        charsWithinTags += 1
                    }
                } else if char == "-" {
                    plainAppend(char)
                    macFileNameAppend(char)
                    webFileNameAppend(char)
                    html.append(char)
                } else if char == ":" || char == "/" {
                    plain.append(char)
                    if lastChar == " " {
                        macFileNameAppend("-")
                    } else {
                        macFileNameAppend(" ")
                        macFileNameAppend("-")
                    }
                    webFileName.append("-")
                    html.append(char)
                    if startingTagCount > 0 {
                        charsWithinTags += 1
                    }
                } else if char == "&" && nextChar == " " && lastChar == " " && startingTagCount == 0 && !codePending {
                    common.append("and")
                    plainAppend("&")
                    macFileNameAppend(char)
                    webFileName.append("and")
                    html.append("&amp;")
                }  else if char == "\'" && nextChar != " " && !nextChar.isPunctuation && lastChar != " " && !lastChar.isPunctuation && startingTagCount == 0 && !codePending {
                    // common.append("")
                    plainAppend("'")
                    macFileNameAppend(char)
                    // webFileName.append("")
                    html.append("&#8217;")
                } else if (char == "*" || char == "_") && !codePending {
                    if !closingTag.isEmpty {
                        html.append(closingTag)
                        closingTag = ""
                        if nextChar == "*" || nextChar == "_" {
                            trimmed.append(nextChar)
                            if nextIndex < value.endIndex {
                                nextIndex = value.index(after: nextIndex)
                            }
                        }
                    } else if closingTag.isEmpty && (nextChar == "*" || nextChar == "_") {
                        html.append("<strong>")
                        closingTag = "</strong>"
                        trimmed.append(nextChar)
                        if nextIndex < value.endIndex {
                            nextIndex = value.index(after: nextIndex)
                        }
                    } else {
                        html.append("<em>")
                        closingTag = "</em>"
                    }
                } else if char == "`" {
                    if !closingTag.isEmpty {
                        html.append(closingTag)
                        closingTag = ""
                    } else {
                        html.append("<code>")
                        closingTag = "</code>"
                    }
                } else {
                // if char == "/" || char == "\'" || char == "\"" || char == "=" || char == "(" || char == ")" || char == "," || char == "+" {
                    if startingTagCount == 0 {
                        plainAppend(char)
                        macFileNameAppend(char)
                    }
                    html.append(char)
                }
            }
            lastChar = char
            index = nextIndex
        } // end of while loop
        
        super.set(trimmed)
        trimmed = ""
    }
    
    func appendSpace() {
        trimmed.append(" ")
        plainAppend(" ")
        // Skip for common
        macFileNameAppend(" ")
        webFileNameAppend("-")
        html.append(" ")
    }
    
    func appendLessThan() {
        trimmed.append("<")
        plainAppend("<")
        common.append("lessthan")
        macFileNameAppend("<")
        webFileName.append("less-than")
        html.append("&lt;")
    }
    
    func appendGreaterThan() {
        trimmed.append(">")
        plainAppend(">")
        common.append(">")
        macFileNameAppend(">")
        webFileName.append("greater-than")
        html.append("&gt;")
    }
    
    func plainAppend(_ char: Character) {
        if char == " " || char == "-" {
            if let lastPlain = plain.last {
                if lastPlain == char {
                    return
                }
            }
        }
        plain.append(char)
    }
    
    func commonAppend(_ char: Character) {
        if char != "-" && char != " " {
            common.append(char)
        }
    }
    
    func macFileNameAppend(_ char: Character) {
        if char == " " || char == "-" {
            if let lastNameChar = macFileName.last {
                if lastNameChar == " " || lastNameChar == "-" {
                    return
                }
            }
        }
        macFileName.append(char)
    }
    
    func webFileNameAppend(_ char: Character) {
        if char == " " || char == "-" {
            if let lastNameChar = webFileName.last {
                if lastNameChar == " " || lastNameChar == "-" {
                    return
                }
            }
            webFileName.append("-")
        } else {
            webFileName.append(char.lowercased())
        }
    }
    
    public func display() {
        
        print("TitleValue.display")
        print("  - trimmed value: \(value)")
        print("  - plain:         \(plain)")
        print("  - common:        \(common)")
        print("  - mac file name: \(macFileName)")
        print("  - web file name: \(webFileName)")
        print("  - html:          \(html)")

    }
    
}
