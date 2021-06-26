//
//  IndexBuilder.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/25/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class IndexBuilder {
    
    var noteIO: NotenikIO
    var indexCollection  = IndexCollection()
    var mkdown = Markedup(format: .markdown)
    public var termCount = 0
    public var pageCount = 0
    
    /// Initialize with the input/output module to be used.
    public init(noteIO: NotenikIO) {
        self.noteIO = noteIO
    }
    
    /// Build the index. 
    public func build() -> String {
        
        // Spin through the collection and collection index terms and references.
        indexCollection  = IndexCollection()
        var (note, position) = noteIO.firstNote()
        while note != nil {
            if note!.hasTitle() && note!.hasIndex() {
                let pageType = note!.getFieldAsString(label: NotenikConstants.typeCommon)
                indexCollection.add(page: note!.title.value, pageType: pageType, index: note!.index)
            }
            (note, position) = noteIO.nextNote(position)
        }
        
        // Now sort the list of terms.
        indexCollection.sort()
        
        // Generate an index, formatted using Markdown.
        mkdown = Markedup(format: .markdown)
        termCount = 0
        pageCount = 0
        // var lastLetter = " "
        mkdown.startDefinitionList(klass: nil)
        for term in indexCollection.list {
            termCount += 1
            // let initialLetter = term.term.prefix(1).uppercased()
            
            /* if initialLetter != lastLetter {
                if lastLetter != " " {
                    mkdown.finishDefinitionList()
                }
                mkdown.heading(level: 2, text: "--- \(initialLetter) ---")
                lastLetter = initialLetter
                mkdown.startDefinitionList(klass: nil)
            } */
            mkdown.startDefTerm()
            mkdown.append(term.term)
            mkdown.finishDefTerm()
            for ref in term.refs {
                pageCount += 1 
                mkdown.startDefDef()
                mkdown.append("[[\(ref.page)]]")
                mkdown.finishDefDef()
            }
        }
        mkdown.finishDefinitionList()
        return mkdown.code
    }
    
}
