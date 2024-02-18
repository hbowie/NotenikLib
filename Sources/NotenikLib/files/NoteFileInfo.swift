//
//  NoteFileInfo.swift
//  Notenik
//
//  Created by Herb Bowie on 1/6/20.
//  Copyright © 2020 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// The file name for a Note stored on disk.
/*
public class NoteFileInfo {
    
            var note: Note
            var collection: NoteCollection
    
    public  var format: NoteFileFormat = .toBeDetermined
            var mmdMetaStartLine = ""
            var mmdMetaEndLine = ""
    
    /// This should contain the file name (without the path) plus the file extension
    public  var base: String?
            var ext:  String?
            var matchesIDSource = true
    
    public init(note: Note) {
        self.note = note
        self.collection = note.collection
        setFormat(newFormat: collection.noteFileFormat)
    }
    
    /// Does this note have a file name?
    public var isEmpty: Bool {
        return base == nil
            || ext == nil
            || base!.count == 0
            || ext!.count == 0
    }
    
    public func setFormat(newFormat: NoteFileFormat) {
        format = newFormat
        if mmdOrYaml {
            mmdMetaStartLine = "---"
            mmdMetaEndLine = "---"
        }
    }
    
    public var mmdOrYaml: Bool {
        return format == .yaml || format == .multiMarkdown
    }
    
    /// Return the full file path for the Note
    public var fullPath: String? {
        if self.isEmpty {
            return nil
        } else {
            return FileUtils.joinPaths(path1: note.collection.lib.getPath(type: .notes), path2: baseDotExt!)
        }
    }
    
    /// Return the full URL pointing to the Note's file
    var url: URL? {
        let path = fullPath
        guard path != nil else { return nil }
        return URL(fileURLWithPath: path!)
    }
    
    /// If the file name matched the ID source before, then regen it; if the filename did
    /// not match the ID source before, then leave it alone. 
    func optRegenFileName() {
        if matchesIDSource {
            genFileName()
        }
    }
    
    /// Create a file name for the file, based on the Note's title
    func genFileName() {
        guard collection.preferredExt.count > 0 else { return }
        let source = note.noteID.source
        guard source.count > 0 else { return }
        
        // ??? Why consistently use title here? 
        if note.hasTitle() {
            base = StringUtils.toReadableFilename(note.title.value)
            genFileExt()
            matchesIDSource = true
        }
    }
    
    func genFileExt() {
        if collection.textFormatFieldDef != nil && note.textFormat.isText {
            ext = NotenikConstants.textFormatTxt
        } else {
            ext = collection.preferredExt
        }
    }
    
    /// Set the flag indicating whether the file name matches the Note's ID.
    func checkIDSourceMatch() {
        guard base != nil else { return }
        matchesIDSource = (StringUtils.toCommon(base!) == StringUtils.toCommon(note.noteID.source))
    }
    
    /// The filename consisting of a base, plus a dot, plus the extension.
    var baseDotExt: String? {
        
        // Concatenate base, dot and extension.
        get {
            if self.isEmpty {
                return nil
            } else {
                return base! + "." + ext!
            }
        }
        
        // Separate out base from extension. 
        set {
            guard newValue != nil  else {
                base = nil
                ext = nil
                return
            }
            base = ""
            ext = ""
            var dotFound = false
            for char in newValue! {
                if char == "." {
                    dotFound = true
                    if ext!.count > 0 {
                        base!.append(".")
                        base!.append(ext!)
                        ext = ""
                    }
                } else if dotFound {
                    ext!.append(char)
                } else {
                    base!.append(char)
                }
            }
            checkIDSourceMatch()
        }
    }
    
    public func display() {
        print("NoteFileInfo for Note titled '\(note.title.value)'")
        if base == nil {
            print("  - base is nil")
        } else {
            print("  - base is '\(base!)'")
        }
        if ext == nil {
            print("  - ext is nil")
        } else {
            print("  - ext is '\(ext!)'")
        }
        print("  - matches ID source? \(matchesIDSource)")
    }
    
} */
