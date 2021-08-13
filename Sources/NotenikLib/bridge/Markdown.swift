//
//  Markdown.swift
//  Notenik
//
//  Created by Herb Bowie on 12/6/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
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
    
    var mkdownOptions = MkdownOptions()
    var context: MkdownContext? = nil
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
    
    /// A static utility function to convert markdown to HTML and write it to an instance of Markedup.
    public static func markdownToMarkedup(markdown: String,
                                          options: MkdownOptions,
                                          mkdownContext: MkdownContext?,
                                          writer: Markedup) {
        let mkdown = Markdown()
        mkdown.md = markdown
        mkdown.mkdownOptions = options
        mkdown.context = mkdownContext
        mkdown.parse()
        writer.append(mkdown.html)
    }
    
    /// Parse the given string of Markdown using the passed options and optional context.
    /// - Parameters:
    ///   - markdown: The Markdown code to be parsed.
    ///   - options: The options to apply to the parsing.
    ///   - context: The environment in which the Markdown was found.
    /// - Returns: The resulting HTML.
    public static func parse(markdown: String, options: MkdownOptions, context: MkdownContext? = nil) -> String {
        let mkdown = Markdown()
        mkdown.md = markdown
        mkdown.mkdownOptions = options
        mkdown.context = context
        mkdown.parse()
        return mkdown.html
    }
    
    public init() {
        
    }
    
    /// Parse the given string of Markdown using the passed options and optional context.
    /// - Parameters:
    ///   - markdown: The Markdown code to be parsed.
    ///   - options: The options to apply to the parsing.
    ///   - context: The environment in which the Markdown was found.
    /// - Returns: The resulting HTML.
    public func parse(markdown: String, options: MkdownOptions, context: MkdownContext? = nil) -> String {
        md = markdown
        mkdownOptions = options
        self.context = context
        parse()
        return html
    }
    
    /// Parse the markdown text in md and place the result into html.
    /// Note that all instance properties must be set and accessed before and after
    /// the call to parse.
    func parse() {
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
            mkdown = MkdownParser(md, options: mkdownOptions)
            mkdown.setWikiLinkFormatting(prefix: mkdownOptions.wikiLinkPrefix,
                                         format: mkdownOptions.wikiLinkFormatting,
                                         suffix: mkdownOptions.wikiLinkSuffix,
                                         context: context)
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
