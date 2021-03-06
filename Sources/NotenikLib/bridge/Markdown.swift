//
//  Markdown.swift
//  Notenik
//
//  Created by Herb Bowie on 12/6/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

import Down
import Ink
import NotenikMkdown

// Convert Markdown to HTML, using the user's favorite parser.
public class Markdown {
    
    var notenikIO: NotenikIO?
    public var md = ""
    public var html = ""
    var mkdown = MkdownParser()
    var ok = true
    
    var parserID = "down"
    
    public var counts: MkdownCounts {
        if parserID == "notenik" || parserID == "mkdown" {
            return mkdown.counts
        } else {
            return MkdownCounts()
        }
    }
    
    public init() {
        
    }
    
    /// Parse the markdown text in md and place the result into html.
    /// Note that all instance properties must be set and accessed before and after
    /// the call to parse.
    public func parse() {
        ok = true
        html = ""
        parserID = AppPrefs.shared.markdownParser
        switch parserID {
        case "down":
            let down = Down(markdownString: md)
            do {
                html = try down.toHTML(DownOptions.smartUnsafe)
            } catch {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "MarkdownParser",
                                  level: .error,
                                  message: "Down parser threw an error")
                ok = false
            }
        case "ink":
            let ink = MarkdownParser()
            html = ink.html(from: md)
        case "notenik", "mkdown":
            mkdown = MkdownParser(md)
            mkdown.parse()
            html = mkdown.html
        default:
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "MarkdownParser",
                              level: .error,
                              message: "Parser ID of \(parserID) is unrecognized")
            ok = false
        }
    }
}
