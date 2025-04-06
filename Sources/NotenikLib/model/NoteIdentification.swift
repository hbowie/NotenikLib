//
//  NoteIdentification.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/10/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// This class contains all the identifying information for a Note.
public class NoteIdentification: Identifiable, Comparable, Equatable {
    
    // -----------------------------------------------------------
    //
    // MARK: Variables.
    //
    // -----------------------------------------------------------
    
    var plainText        = false
    var noteFileFormat: NoteFileFormat = .toBeDetermined
    var preferredExt = "txt"
    
    var mmdOrYaml: Bool {
        return noteFileFormat == .yaml || noteFileFormat == .multiMarkdown
    }
    
    var mmdMetaStartLine = ""
    var mmdMetaEndLine = ""
    
    var seqBeforeTitle   = false
    var basis            = ""
    var text             = ""
    
    var existingBase:    String?
    var existingExt:     String?
    
    var matchesIdSource  = true
    
    var useExistingFilename = false
    
    var derivationNeeded = false
    
    var commonID         = ""
    var readableFileName = ""
    var commonFileName   = ""
    
    // -----------------------------------------------------------
    //
    // MARK: Set the input fields.
    //
    // -----------------------------------------------------------
    
    public func setNoteFileFormat(newFormat: NoteFileFormat) {
        noteFileFormat = newFormat
        if mmdOrYaml {
            mmdMetaStartLine = "---"
            mmdMetaEndLine = "---"
        }
    }
    
    func changeFileExt(to newFileExt: String) {
        existingExt = newFileExt
        preferredExt = newFileExt
    }
    
    func setPreferredExt(_ ext: String) {
        preferredExt = ext
    }
    
    func setExistingFileName(_ filename: String?) {
        guard filename != nil  else {
            existingBase = nil
            existingExt = nil
            return
        }
        existingBase = ""
        existingExt = ""
        var dotFound = false
        for char in filename! {
            if char == "." {
                dotFound = true
                if existingExt!.count > 0 {
                    existingBase!.append(".")
                    existingBase!.append(existingExt!)
                    existingExt = ""
                }
            } else if dotFound {
                existingExt!.append(char)
            } else {
                existingBase!.append(char)
            }
        }
        checkIDSourceMatch()
        if matchesIdSource {
            useExistingFilename = true
        }
        
    }
    
    public func clearExistingFilename() {
        existingBase = nil
        existingExt = nil
        useExistingFilename = false
    }
    
    public func setIDSourceMatch(_ match: Bool) {
        matchesIdSource = match
    }
    
    /// Set the flag indicating whether the file name matches the Note's ID.
    func checkIDSourceMatch() {
        matchesIdSource = true
        guard existingBase != nil && !existingBase!.isEmpty else { return }
        matchesIdSource = (StringUtils.toCommon(existingBase!) == commonID)
    }
    
    func setBasis(_ basis: String) {
        self.basis = basis
        deriveIdentifiers()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Figure out the derived fields.
    //
    // -----------------------------------------------------------
    
    func deriveIfNeeded() {
        if derivationNeeded {
            deriveIdentifiers()
        }
    }
    
    func deriveIdentifiers() {
        commonID         = StringUtils.toCommon(basis)
        readableFileName = StringUtils.toReadableFilename(basis, allowDots: AppPrefs.shared.allowDots)
        commonFileName   = StringUtils.toCommonFileName(basis)
        derivationNeeded = false
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Getters to retrieve the useful data.
    //
    // -----------------------------------------------------------
    
    /// Return the full URL pointing to the Note's file
    public func getURL(note: Note) -> URL? {
        let path = getFullPath(note: note)
        guard path != nil else { return nil }
        return URL(fileURLWithPath: path!)
    }
    
    /// Return the full file path for the Note
    public func getFullPath(note: Note) -> String? {
        let collection = note.collection
        let base = getBaseFilename()
        guard base != nil && !base!.isEmpty else {
            return nil
        }
        let ext = getFileExt()
        guard ext != nil && !ext!.isEmpty else {
            return nil
        }
        let masterPath = collection.lib.getPath(type: .notes)
        var folderPath = masterPath
        if note.hasFolder() {
            folderPath = FileUtils.joinPaths(path1: masterPath, path2: note.folder.value)
        }
        
        return FileUtils.joinPaths(path1: folderPath, path2: getBaseDotExt()!)
    }
    
    public var hasData: Bool {
        return !commonID.isEmpty
    }
    
    public var isEmpty: Bool {
        return commonID.isEmpty
    }
    
    public var id: String {
        return commonID
    }
    
    public func getBaseDotExtForWrite() -> String? {
        var baseDotExt: String? = nil
        if useExistingFilename {
            baseDotExt = getExistingBaseDotExt()
        }
        if baseDotExt == nil {
            baseDotExt = getBaseDotExt()
        }
        return baseDotExt
    }
    
    public func getExistingBaseDotExt() -> String? {
        guard existingBase != nil && existingExt != nil else { return nil }
        return existingBase! + "." + existingExt!
    }
    
    /// The filename consisting of a base, plus a dot, plus the extension.
    public func getBaseDotExt() -> String? {
        
        // Concatenate base, dot and extension.
        if isEmpty {
            return nil
        } else {
            return getBaseFilename()! + "." + getFileExt()!
        }
    }
    
    public func getBaseFilename() -> String? {
        if isEmpty && existingBase == nil {
            return nil
        } else if existingBase == nil || existingBase!.isEmpty {
            return readableFileName
        } else if matchesIdSource {
            return readableFileName
        } else {
            return existingBase
        }
    }
    
    public func getBasis() -> String {
        if basis.isEmpty && existingBase == nil {
            return ""
        } else if existingBase == nil || existingBase!.isEmpty {
            return basis
        } else if matchesIdSource {
            return basis
        } else {
            return existingBase!
        }
    }
    
    public func getFileExt() -> String? {
        if existingExt != nil {
            return existingExt
        } else {
            return preferredExt
        }
    }
    
    public func getNoteFileFormat() -> NoteFileFormat {
        return noteFileFormat
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Utility routines.
    //
    // -----------------------------------------------------------
    
    public func copy() -> NoteIdentification {
        let noteID2 = NoteIdentification()
        noteID2.plainText = self.plainText
        noteID2.noteFileFormat = self.noteFileFormat
        noteID2.preferredExt = self.preferredExt
        noteID2.mmdMetaStartLine = self.mmdMetaStartLine
        noteID2.mmdMetaEndLine = self.mmdMetaEndLine
        noteID2.existingBase = self.existingBase
        noteID2.existingExt = self.existingExt
        noteID2.basis       = self.basis
        noteID2.text        = self.text
        noteID2.commonID    = commonID
        noteID2.readableFileName = self.readableFileName
        noteID2.commonFileName = self.commonFileName
        noteID2.matchesIdSource = self.matchesIdSource
        noteID2.useExistingFilename = self.useExistingFilename
        noteID2.derivationNeeded = self.derivationNeeded
        return noteID2
    }
    
    public func display() {
        deriveIfNeeded()
        print(" ")
        print("NoteIdentification.display")
        if getExistingBaseDotExt() == nil {
            print("  - existing base and/or ext is nil")
        } else {
            print("  - existing base dot ext: \(getExistingBaseDotExt()!)")
        }
        print("  - common id: \(commonID)")
        print("  - readable file name: \(readableFileName)")
        print("  - commonFileName: \(commonFileName)")
        print("  - plain text? \(plainText)")
        print("  - note file format: \(noteFileFormat)")
        print("  - matches id source? \(matchesIdSource)")
        print("  - use existing file name? \(useExistingFilename)")
    }
    
    public static func == (lhs: NoteIdentification, rhs: NoteIdentification) -> Bool {
        return lhs.commonID == rhs.commonID
    }
    
    public static func < (lhs: NoteIdentification, rhs: NoteIdentification) -> Bool {
        return lhs.commonID < rhs.commonID
    }
    
}
