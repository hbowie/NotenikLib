//
//  TransformMdResults.swift
//  NotenikLib
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 9/7/23.
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// All the results harvested from the Notenik Markdown parser.
public class TransformMdResults {
    
    // The following variables show the results of the most recent
    // parsing operation.
    public var ok = true
    public var html = ""
    public var mkdownContext: NotesMkdownContext?
    
    // The following variables show the results of the parsing of
    // the body field for the current Note.
    public var bodyHTML: String? = nil
    public var counts = MkdownCounts()
    public var minutesToRead: MinutesToReadValue?
    
    /// The following variables show the cumulative results for all parsing operations
    /// performed for the current Note. 
    public var wikiLinks = WikiLinkList()
    
    /// Indicates whether any notes were automatically added as the result of
    /// missing wiki link targets. 
    public var wikiAdds = false
    
    public init() {
        
    }

}
