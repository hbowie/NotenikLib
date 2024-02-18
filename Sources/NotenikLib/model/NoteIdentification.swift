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
    
    var basis            = ""
    var text             = ""
    var dupeCounter      = 0
    
    var existingBase:    String?
    var existingExt:     String?
    
    var matchesIdSource  = true
    
    var useExistingFilename = false
    
    var derivationNeeded = false
    
    var basisPlusDupe    = ""
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
    
    public func avoidDuplicate() {
        if dupeCounter < 2 {
            dupeCounter = 2
        } else {
            dupeCounter += 1
        }
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
        basisPlusDupe = basis
        if dupeCounter >= 2 {
            basisPlusDupe.append(" \(dupeCounter)")
        }
        commonID         = StringUtils.toCommon(basisPlusDupe)
        readableFileName = StringUtils.toReadableFilename(basisPlusDupe)
        commonFileName   = StringUtils.toCommonFileName(basisPlusDupe)
        derivationNeeded = false
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Getters to retrieve the useful data.
    //
    // -----------------------------------------------------------
    
    /// Return the full URL pointing to the Note's file
    public func getURL(collection: NoteCollection) -> URL? {
        let path = getFullPath(collection: collection)
        guard path != nil else { return nil }
        return URL(fileURLWithPath: path!)
    }
    
    /// Return the full file path for the Note
    public func getFullPath(collection: NoteCollection) -> String? {
        let base = getBaseFilename()
        guard base != nil && !base!.isEmpty else {
            return nil
        }
        let ext = getFileExt()
        guard ext != nil && !ext!.isEmpty else {
            return nil
        }
        return FileUtils.joinPaths(path1: collection.lib.getPath(type: .notes), path2: getBaseDotExt()!)
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
    
    public func getExistingBaseDotExt() -> String? {
        guard existingBase != nil && existingExt != nil else { return nil }
        return existingBase! + "." + existingExt!
    }
    
    /// The filename consisting of a base, plus a dot, plus the extension.
    public func  getBaseDotExt() -> String? {
        
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
        noteID2.basis       = self.basis
        noteID2.dupeCounter = self.dupeCounter
        noteID2.text        = self.text
        noteID2.commonID    = commonID
        noteID2.readableFileName = self.readableFileName
        noteID2.commonFileName = self.commonFileName
        return noteID2
    }
    
    public static func == (lhs: NoteIdentification, rhs: NoteIdentification) -> Bool {
        return lhs.commonID == rhs.commonID
    }
    
    public static func < (lhs: NoteIdentification, rhs: NoteIdentification) -> Bool {
        return lhs.commonID < rhs.commonID
    }
    
}
