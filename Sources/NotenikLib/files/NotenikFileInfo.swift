//
//  NotenikFileInfo.swift
//  NotenikLib
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 11/19/24.
//

import Foundation

import NotenikUtils

public class NotenikFileInfo {
    
    let dot: Character = "."
    let dotStr = "."
    let slash: Character = "/"
    
    public var filePath = ""
    
    public var extOriginal = ""
    public var extLower = ""
    public var fileName = ""
    public var folder = ""
    
    public init(path1: String, path2: String) {
        filePath = FileUtils.joinPaths(path1: path1, path2: path2)
        scanPath()
    }
    
    public var fullFileName: String {
        if extOriginal.isEmpty {
            return fileName
        } else {
            return fileName + dotStr + extOriginal
        }
    }
    
    public var isInfoFile: Bool {
        return fullFileName == NotenikConstants.infoFileName
    }
    
    public var isInfoParent: Bool {
        return fullFileName == NotenikConstants.infoParentFileName
            || fullFileName == NotenikConstants.infoProjectFileName
    }
    
    public var isHidden: Bool {
        return fileName.hasPrefix(dotStr) || folder.hasPrefix(dotStr)
    }
    
    public var isAppBundle: Bool {
        return extLower == "app"
    }
    
    public var isDiskImage: Bool {
        return extLower == "dmg"
    }
    
    public var isImage: Bool {
        switch extLower {
        case "gif", "jpg", "jpeg", "png", "svg":
            return true
        default:
            return false
        }
    }
    
    public var isPlainText: Bool {
        switch extLower {
        case "txt", "md", "text", "mdtext", "mkdown":
            return true
        default:
            return false
        }
    }
    
    public var isScript: Bool {
        return extLower == NotenikConstants.scriptExt.withoutDot
                    || (folder == NotenikConstants.scriptsFolderName
                        && (extLower == NotenikConstants.scriptExtAlt1.withoutDot
                            || extLower == NotenikConstants.scriptExtAlt2.withoutDot))
    }
    
    public var isBBEditProject: Bool {
        return extLower == NotenikConstants.BBEditProjectExt.withoutDot
    }
    
    public var isWebLocation: Bool {
        return extLower == NotenikConstants.webLocExt.withoutDot
    }
    
    public var isNotenikFilesFolder: Bool {
        return folder == NotenikConstants.notenikFiles && extLower.isEmpty && fileName.isEmpty
    }
    
    public var isDir: Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
        guard exists else { return false }
        return isDirectory.boolValue
    }
    
    func scanPath() {
        var work = ""
        var dotFound = false
        var slashCount = 0
        var ix = filePath.endIndex
        var charCount = 0
        while ix > filePath.startIndex && slashCount < 2 {
            ix = filePath.index(before: ix)
            let c = filePath[ix]
            charCount += 1
            if c == dot && ix > filePath.startIndex && slashCount == 0 {
                dotFound = true
                extOriginal = work
                extLower = work.lowercased()
                work = ""
            } else if c == slash && charCount == 1 {
                // Ignore any trailing slash
            } else if c == slash {
                slashCount += 1
                if slashCount == 1 {
                    if dotFound {
                        fileName = work
                    } else {
                        folder = work
                    }
                } else if slashCount == 2 {
                    if dotFound {
                        folder = work
                    }
                }
                work = ""
            } else {
                work.insert(c, at: work.startIndex)
            }
        }
    }
    
    public func display() {
        print("filePath: \(filePath)")
        print("extOriginal: \(extOriginal)")
        print("extLowered: \(extLower)")
        print("fileName: \(fileName)")
        print("folder: \(folder)")
    }

}
