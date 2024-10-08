//
//  AttachmentName.swift
//  Notenik
//
//  Created by Herb Bowie on 7/22/19.
//  Copyright © 2019-2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// The full name assigned to a Note attachment.
public class AttachmentName: Comparable, NSCopying, CustomStringConvertible {
    
    let preferredSeparator = " | "
    
    var prefix = ""
    var separator = " | "
    var sepCharFound = false
    public var suffix = ""
    public var ext = FileExtension("")
    
    /// Standard string representation to conform to CustomStringConvertible.
    public var description: String {
        return fullName
    }
    
    /// The full name for the attachment, consisting of
    /// prefix, separator, suffix and file extension.
    public var fullName: String {
        return prefix + separator + suffix + ext.originalExtWithDot
    }
    
    /// The common file name to be used for this attachment, when
    /// used as a Web component. 
    public var commonName: String {
        return (StringUtils.toCommonFileName(prefix)
            + "-" + StringUtils.toCommonFileName(suffix)
                + self.ext.lowercaseExtWithDot)
    }
    
    /// Is the first attachment name less than the second?
    public static func < (lhs: AttachmentName, rhs: AttachmentName) -> Bool {
        return lhs.fullName < rhs.fullName
    }
    
    /// Are the two attachment names equal?
    public static func == (lhs: AttachmentName, rhs: AttachmentName) -> Bool {
        return lhs.fullName == rhs.fullName
    }
    
    /// Make a copy of this Attachment Name. 
    public func copy(with zone: NSZone? = nil) -> Any {
        let newAttachmentName = AttachmentName()
        newAttachmentName.prefix = self.prefix
        newAttachmentName.separator = self.separator
        newAttachmentName.suffix = self.suffix
        newAttachmentName.ext = FileExtension(self.ext.originalExtSansDot)
        return newAttachmentName
    }
    
    /// Given a Note and the full file name for an attachment,
    /// separate out the name into its constituent parts.
    func setName(note: Note, fullName: String) -> Bool {
        prefix = ""
        separator = ""
        sepCharFound = false
        suffix = ""
        var extWork = ""
        guard let fnBase = note.noteID.getBaseFilename() else { return false }
        prefix = fnBase
        if let existingBase = note.noteID.existingBase {
            if !existingBase.isEmpty {
                if fullName.hasPrefix(existingBase) {
                    prefix = existingBase
                }
            }
        }
        var index = fullName.index(fullName.startIndex, offsetBy: prefix.count)
        while index < fullName.endIndex {
            let char = fullName[index]
            if suffix.count == 0 && (char.isWhitespace || char.isPunctuation || char == "|") {
                separator.append(char)
                if !char.isWhitespace {
                    sepCharFound = true
                }
            } else if char == "." {
                if extWork.count > 0 {
                    suffix.append(extWork)
                    extWork = ""
                }
                extWork.append(char)
            } else if extWork.count > 0 {
                extWork.append(char)
            } else if sepCharFound {
                suffix.append(char)
            } else {
                // Something wrong here.
                return false
            }
            index = fullName.index(after: index)
        }
        guard sepCharFound && suffix.count > 0 else { return false }
        self.ext = FileExtension(extWork)
        return true
    }
    
    /// Set the various components of the Attachment Name.
    ///
    /// - Parameters:
    ///   - fromFile: The URL of the file to be attached, which supplies the file extension.
    ///   - note: The note to which the file is to be attached, which supplies the prefix.
    ///   - suffix: The suffix to be used.
    func setName(fromFile: URL, note: Note, suffix: String) {
        self.prefix = ""
        self.separator = ""
        self.suffix = ""
        guard let fnBase = note.noteID.getBaseFilename() else { return }
        let fromFileName = FileName(fromFile)
        self.prefix = fnBase
        self.separator = preferredSeparator
        self.suffix = suffix
        self.ext = FileExtension(fromFileName.ext)
    }
    
    /// Change the prefix based on the passed note, but leave
    /// other elements of the attachment name as-is. 
    func changeNote(note: Note) {
        guard let fnBase = note.noteID.getBaseFilename() else { return }
        self.prefix = fnBase
    }
    
    func display() {
        print("Attachment prefix: \(prefix), sep: \(separator), suffix: \(suffix), ext: \(ext)")
    }
}
