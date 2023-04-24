//
//  MkdownCommandList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/21/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown

/// Information about Markdown commands found within -- either within an associated Note,
/// or within an associated Collection.
public class MkdownCommandList {
    
    // -----------------------------------------------------------
    //
    // MARK: Definition and Initialization.
    //
    // -----------------------------------------------------------
    
    var collectionLevel = false
    
    var commands: [MkdownCommandUsage] = []

    public var contentPage  = true
    public var header       = false
    public var footer       = false
    public var nav          = false
    public var metadata     = false
    public var search       = false
    public var scripted     = false
    
    public init(collectionLevel: Bool) {
        self.collectionLevel = collectionLevel
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Getters that return information found here.
    //
    // -----------------------------------------------------------
    
    public var isEmpty: Bool {
        return commands.isEmpty
    }
    
    public var count: Int {
        return commands.count
    }
    
    /// Should this Note be excluded from a web book being generated?
    /// - Parameter epub: Is this an EPUB web book?
    /// - Returns: True if the Note should be excluded.
    public func excludeFromBook(epub: Bool) -> Bool {
        if contentPage { return false }
        if search && epub { return true }
        return true
    }
    
    /// Should this Note be included in a web book being generated?
    /// - Parameter epub: Is this an EPUB web book?
    /// - Returns: True if the Note should be included.
    public func includeInBook(epub: Bool) -> Bool {
        if contentPage { return true }
        if search && !epub { return true }
        return false
    }
    
    /// Return the code associated with a particular command.
    public func getCodeFor(_ command: String) -> String {
        for usage in commands {
            if usage.command == command {
                return usage.code
            }
        }
        return ""
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Update routines.
    //
    // -----------------------------------------------------------
    
    /// Update this instance (presumabley associated with a Collection) with information
    /// from another instance (presumably associated with a single Note within
    /// the Collection).
    /// - Parameters:
    ///   - noteList: The Markdown Command list from a Note.
    ///   - noteTitle: The title of that Note.
    ///   - code: The code generated from the Note's body field.
    public func updateWith(noteList: MkdownCommandList) {
        for usage in noteList.commands {
            updateWith(command: usage.command, noteTitle: usage.noteID, code: usage.code)
        }
    }
    
    /// Update the existing command list with the code to be saved.
    /// - Parameters:
    ///   - body: The body of the Note, before parsting.
    ///   - html: The HTML output, after parsing. 
    public func updateWith(body: String, html: String) {
        for usage in commands {
            if usage.saveCode {
                usage.code = pickCodeFor(usage.command, body: body, html: html)
            }
        }
    }
    
    /// Update this instance with new information about a single command usage.
    /// - Parameters:
    ///   - command: The command found.
    ///   - noteTitle: The title of the Note.
    ///   - body: The body field, before parsing into HTML.
    ///   - html: The body field, after parsing into HTML. 
    public func updateWith(command: String, noteTitle: String, body: String, html: String) {
        updateWith(command: command,
                   noteTitle: noteTitle,
                   code: pickCodeFor(command, body: body, html: html))
    }
    
    /// Return the desired code for the indicated command.
    /// - Parameters:
    ///   - command: The command being exposed.
    ///   - body: The body code, before being parsed.
    ///   - html: The HTML code, after being parsed.
    /// - Returns: Either the HTML code (for most commands), or the input code, minus
    ///            the first line, for the metadata command.
    func pickCodeFor(_ command: String, body: String, html: String) -> String {
        if command.lowercased() == MkdownConstants.metadataCmd {
            var lines = body.components(separatedBy: "\n")
            lines.removeFirst()
            return lines.joined(separator: "\n")
        } else {
            return html
        }
    }
    
    /// Update this instance with new information about a single command usage.
    /// - Parameters:
    ///   - command: The Markdown command.
    ///   - noteTitle: The title of the Note.
    ///   - code: The code generated from the Note.
    public func updateWith(command: String, noteTitle: String, code: String?) {
        
        let usage = MkdownCommandUsage(command: command, noteTitle: noteTitle)
        guard !collectionLevel || usage.saveForCollection else { return }
        var i = 0
        var done = false
        while i < commands.count && !done {
            if usage > commands[i] {
                i += 1
            } else if usage == commands[i] {
                done = true
            } else {
                commands.insert(usage, at: i)
                adjustVariablesFor(command: usage.command)
                done = true
            }
        }
        if !done {
            commands.append(usage)
            adjustVariablesFor(command: usage.command)
        }
        if commands[i].saveCode && commands[i].code.isEmpty && code != nil && !code!.isEmpty {
            commands[i].code = code!
        }
    }
    
    public func adjustVariablesFor(command: String) {
        
        switch command {
        case MkdownConstants.footerCmd:
            footer = true
            contentPage = false
        case MkdownConstants.headerCmd:
            header = true
            contentPage = false
        case MkdownConstants.metadataCmd:
            metadata = true
            contentPage = false
        case MkdownConstants.navCmd:
            nav = true
            contentPage = false
        case MkdownConstants.searchCmd:
            search = true
            scripted = true
            contentPage = false
        case MkdownConstants.sortTableCmd:
            scripted = true
        default:
            break
        }
    }
    
    public func display() {
        print("MkdownCommandList.display \(commands.count) command usages")
        for usage in commands {
            usage.display()
        }
    }
    
}
