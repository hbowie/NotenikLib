//
//  Quote.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/24/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class Quote {
    
    public var author = ""
    public var majorTitle = ""
    public var minorTitle = ""
    public var date = ""
    public var link = ""
    public var text = ""
    
    public init() {
        
    }
    
    public init(_ quote: Quote) {
        self.author = quote.author
        self.majorTitle = quote.majorTitle
        self.date = quote.date
    }
    
    public func setWorkTitleAndYear(str: String) {
        majorTitle = ""
        date = ""
        var spacePending = false
        var yearStarted = false
        var closingParen = ""
        for char in str {
            if char.isWhitespace {
                spacePending = true
            } else if char == "(" {
                if !date.isEmpty {
                    majorTitle.append(" (" + date + closingParen)
                    date = ""
                    spacePending = false
                }
                yearStarted = true
            } else if yearStarted {
                if char == ")" {
                    closingParen.append(char)
                } else {
                    date.append(char)
                }
            } else {
                if spacePending {
                    majorTitle.append(" ")
                    spacePending = false
                }
                majorTitle.append(char)
            }
        }
    }
    
    public var hasText: Bool {
        return !text.isEmpty
    }
    
    public func setText(str: String) {
        text = str
    }
    
    public func parseTrailer(_ str: String) {
        date = ""
        var spacePending = false
        var dateStarted = false
        var closingParen = ""
        for char in str {
            if !closingParen.isEmpty {
                // Skip trailing characters after the first date
            } else if char == "\"" {
                // skip it
            } else if char.isWhitespace {
                spacePending = true
            } else if char == "(" {
                if !date.isEmpty {
                    minorTitle.append(" (" + date + closingParen)
                    date = ""
                    spacePending = false
                }
                dateStarted = true
                spacePending = false
            } else if dateStarted {
                if char == ")" {
                    closingParen.append(char)
                } else if char.isWhitespace {
                    spacePending = true
                } else {
                    if spacePending {
                        date.append(" ")
                        spacePending = false
                    }
                    date.append(char)
                }
            } else {
                if spacePending {
                    minorTitle.append(" ")
                    spacePending = false
                }
                minorTitle.append(char)
            }
        }
        
    }
    
    public func display() {
        print("Quote")
        print("Major Title: \(majorTitle)")
        print("Work Date:  \(date)")
        print("text: \(text)")
    }
    
}
