//
//  MDHeadReader.swift
//  Notenik
//
//  Created by Herb Bowie on 11/7/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation
import NotenikUtils

/// Read a Markdown file with headings, and chunk it up into sections.   
public class MDHeadReader: RowImporter {
    
    var consumer:           RowConsumer!
    
    var lineReader:         BigStringReader!
    
    var priorLine:          String?
    
    var labels:             [String] = []
    var fields:             [String] = []
    
    var title = ""
    var level = ""
    var body  = ""
    
    public init() {
        
    }
    
    public func setContext(consumer: RowConsumer) {
        self.consumer = consumer
    }
    
    /// Read the file and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    public func read(fileURL: URL) {
        do {
            let bigString = try String(contentsOf: fileURL, encoding: .utf8)
            let reader = BigStringReader(bigString)
            read(lineReader: reader)
        } catch {
            logError("Error reading Markdown File from \(fileURL)")
        }
    }
    
    /// Read the file and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter lineReader: A line reader ready to be opened.
    func read(lineReader: LineReader) {
        labels.append(NotenikConstants.title)
        labels.append("Level")
        labels.append("Body")
        priorLine = nil
        lineReader.open()
        var line = lineReader.readLine()
        startRow()
        while line != nil {
            scanLine(line!)
            line = lineReader.readLine()
        }
        lineReader.close()
        flushPriorLine()
        finishRow()
    }
    
    func scanLine(_ line: String) {
        var firstChar: Character = " "
        var consecutiveLeadingChars = 0
        var charPosition = 0
        var charIndex = line.startIndex
        var titleStart = line.startIndex
        var titleEnd = line.endIndex
        for char in line {
            if charPosition == 0 {
                if char == "#" || char == "=" || char == "-" {
                    firstChar = char
                    consecutiveLeadingChars = 1
                } else {
                    break
                }
            } else if charPosition == consecutiveLeadingChars {
                if char == firstChar {
                    consecutiveLeadingChars += 1
                } else if char.isWhitespace {
                    // We're good
                } else {
                    // No space following initial repeating characters
                    firstChar = " "
                    consecutiveLeadingChars = 0
                    break
                }
            } else {
                // We're past any initial string of repeating characters
                if char.isWhitespace {
                    // ignore spaces
                } else if char == "#" && char == firstChar {
                    // ignore it
                } else {
                    // We have some line content
                    if firstChar == "#" {
                        if titleStart == line.startIndex {
                            titleStart = charIndex
                        }
                        titleEnd = line.index(after: charIndex)
                    } else {
                        // We have content on this line, so it can't be an underline
                        firstChar = " "
                        consecutiveLeadingChars = 0
                        break
                    }
                }
            }
            charPosition += 1
            charIndex = line.index(after: charIndex)
        }
        
        // Done scanning -- let's see what we've got.
        if firstChar == "#" && titleStart > line.startIndex {
            flushPriorLine()
            finishRow()
            title = String(line[titleStart ..< titleEnd])
            level = "\(consecutiveLeadingChars)"
        } else if firstChar == "=" && priorLine != nil && priorLine!.count > 0 {
            finishRow()
            title = priorLine!
            priorLine = nil
            level = "1"
        } else if firstChar == "-" && priorLine != nil && priorLine!.count > 0 {
            finishRow()
            title = priorLine!
            priorLine = nil
            level = "2"
        } else {
            flushPriorLine()
            priorLine = line
        }
    }
    
    func flushPriorLine() {
        if priorLine != nil {
            body.append(priorLine!)
            body.append("\n")
            priorLine = nil
        }
    }
    
    func finishRow() {
        if title.count > 0 || body.count > 0 {
            if title.count == 0 {
                title = "Start of Document"
                level = "1"
            }
            
            fields.append(title)
            consumer.consumeField(label: labels[0], value: fields[0], rule: .always)
            
            fields.append(level)
            consumer.consumeField(label: labels[1], value: fields[1], rule: .always)
            
            fields.append(body)
            consumer.consumeField(label: labels[2], value: fields[2], rule: .always)
            
            consumer.consumeRow(labels: labels, fields: fields)
        }
        startRow()
    }
    
    func startRow() {
        title = ""
        level = ""
        body = ""
        fields = []
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "MDHeadReader",
                          level: .error,
                          message: msg)
    }
}
