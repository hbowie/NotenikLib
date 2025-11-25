//
//  QuoteFromDriver.swift
//  NotenikLib
//
//  Created by Herb Bowie on 11/23/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).

import Foundation

import NotenikUtils

public class QuoteFromDriver {
    
    public init() {
        
    }
    
    public func formatFrom(writer: Markedup, quoteNote: Note?, authorNote: Note? = nil, workNote: Note? = nil) {
        
        let quoteFrom = QuoteFrom()
        
        if authorNote != nil {
            quoteFrom.authorIdBasis = authorNote!.title.value
            quoteFrom.author = authorNote!.title.value
            if authorNote!.hasAKA() {
                quoteFrom.author = authorNote!.aka.value
            } else if authorNote!.title.value.contains(", ") {
                let author = AuthorValue(authorNote!.title.value)
                quoteFrom.author = author.firstNameFirst
            }
        }
        
        if workNote != nil {
            quoteFrom.workIdBasis = workNote!.title.value
            quoteFrom.workTitle = workNote!.title.value
            if workNote!.hasDate() {
                quoteFrom.pubDate = workNote!.date.value
            }
            quoteFrom.workType = workNote!.getFieldAsString(label: NotenikConstants.workTypeCommon)
        }
        
        if quoteNote != nil {
            quoteFrom.formatFromInMarkdown(writer: writer)
        } else {
            quoteFrom.formatWorkFromInMarkdown(writer: writer)
        }
        
    }
    
}
