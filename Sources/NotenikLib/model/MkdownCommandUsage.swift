//
//  MkdownCommandUsage.swift
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
import NotenikUtils


/// Documents the usage of a Markdown command on a particular Note within a Collection.
/// This can be used to expose Markdown commands at the Note level, and (for some commands)
/// at the Collection level as well.
public class MkdownCommandUsage: Comparable, Equatable {
    
    var command = ""
    var mods    = ""
    var noteID  = ""
    var code    = ""
    
    var saveCode = false
    var saveForCollection = false
    
    /// Create a new instance.
    /// - Parameters:
    ///   - command: The Markdown command being documented.
    ///   - noteTitle: The title of the Note containing the command.
    public init(command: String, noteTitle: String, mods: String? = nil) {
        self.command = StringUtils.toCommon(command)
        self.noteID = StringUtils.toCommon(noteTitle)
        if mods != nil {
            self.mods = mods!
        }
        setCommandAttributes()
    }
    
    func setCommandAttributes() {
        switch command {
        case MkdownConstants.footerCmd:
            saveCode = true
            saveForCollection = true
        case MkdownConstants.headerCmd:
            saveCode = true
            saveForCollection = true
        case MkdownConstants.metadataCmd:
            saveCode = true
            saveForCollection = true
        case MkdownConstants.navCmd:
            saveCode = true
            saveForCollection = true
        case MkdownConstants.navLeftCmd:
            saveCode = true
            saveForCollection = true
        case MkdownConstants.tagsCloudCmd:
            saveForCollection = true
        case MkdownConstants.tagsOutlineCmd:
            saveForCollection = true
        case MkdownConstants.authorCmd:
            saveForCollection = true
        case MkdownConstants.titleSuffixCmd:
            saveForCollection = true
        case MkdownConstants.descriptionCmd:
            saveForCollection = true
        default:
            saveCode = false
            saveForCollection = false
        }
    }
    
    /// Display properties: used for debugging. 
    public func display() {
        print("  MkdownCommandUsage.display")
        print("    - command: \(command)")
        print("      - save code? \(saveCode)")
        print("      - save for collection? \(saveForCollection)")
        print("    - note ID: \(noteID)")
        if code.isEmpty {
            print("    - code is empty")
        } else {
            print("    - code follows:")
            print(code)
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Conform to Comparable and Equatable.
    //
    // -----------------------------------------------------------
    
    public static func < (lhs: MkdownCommandUsage, rhs: MkdownCommandUsage) -> Bool {
        if lhs.command < rhs.command {
            return true
        } else if lhs.command > rhs.command {
            return false
        } else if lhs.noteID < rhs.noteID {
            return true
        } else {
            return false
        }
    }
    
    public static func == (lhs: MkdownCommandUsage, rhs: MkdownCommandUsage) -> Bool {
        return lhs.command == rhs.command && lhs.noteID == rhs.noteID
    }
    
}
