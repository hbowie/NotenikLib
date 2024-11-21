//
//  FileName.swift
//  Notenik
//
//  Created by Herb Bowie on 12/26/18.
//  Copyright © 2018 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A class offering easy access to the various components of
/// a path to a file or directory.
public class FileName: CustomStringConvertible {
    
    /// The complete path, including base file name and extension.
    public var fileNameStr = ""
    
    /// File extension without a leading dot
    public var ext = ""
    
    /// Lowercase file extension, without a leading dot
    public var extLower = ""
    
    /// Base file name, without preceding path or following extension.
    public var base = ""
    
    /// Base file name converted to all lower-case.
    public var baseLower = ""
    
    /// The path leading up to, but not including, any file name.
    public var path = ""
    
    /// The lowest level folder in the supplied file name path.
    public var folder = ""
    
    /// An array of all the folders found in the path.
    public var folders: [String] = []
    
    /// Do we think this is a file or a directory?
    var fileOrDir: FileOrDirectory = .unknown
    
    public var typeIsFile: Bool {
        return fileOrDir == .file
    }
    
    public var typeIsDirectory: Bool {
        return fileOrDir == .directory
    }
    
    public var description: String {
        return fileNameStr
    }
    
    public var isEmpty: Bool {
        return fileNameStr.isEmpty
    }
    
    public var url: URL? {
        let link = NotenikLink()
        link.set(with: fileNameStr, assume: .assumeFile)
        return link.url
    }
    
    /// The file name, excluding the path to the folders containing the file. 
    public var fileName: String {
        if base.count == 0 {
            return ""
        } else {
            return base + "." + ext
        }
    }
    
    /// Initialize with no initial value
    public init() {
        
    }
    
    /// Initialize with a String value
    public convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Initialize with a URL
    public convenience init (_ url: URL) {
        self.init()
        set(url)
    }
    
    /// Set a new value with a URL providing the path
    func set(_ url: URL) {
        set(url.path)
    }
    
    func set(_ value: String) {
        
        fileNameStr = value
        var remainingStartIndex = value.startIndex
        var remainingEndIndex = value.endIndex
        var lastDotIndex = value.endIndex
        var possibleExtStart = value.startIndex
        var index = value.startIndex
        var lastCharWasSlash = false
        var pathEnd = value.endIndex
        for char in value {
            if char == "/" {
                if index > remainingStartIndex {
                    let nextFolder = String(value[remainingStartIndex..<index])
                    anotherFolder(nextFolder)
                }
                remainingStartIndex = value.index(after: index)
                lastDotIndex = value.endIndex
                lastCharWasSlash = true
                pathEnd = index
            } else if char == "." {
                lastDotIndex = index
                possibleExtStart = value.index(after: lastDotIndex)
                lastCharWasSlash = false
            } else {
                lastCharWasSlash = false
            }
            index = value.index(after: index)
        }
        
        if lastCharWasSlash {
            fileOrDir = .directory
            remainingEndIndex = value.index(before: value.endIndex)
            pathEnd = value.index(before: value.endIndex)
        }
        
        // See if we have a file extension
        var possibleExt = ""
        if lastDotIndex < value.endIndex && lastDotIndex > remainingStartIndex {
            possibleExt = String(value[possibleExtStart..<value.endIndex])
        }
        if possibleExt.count > 0 && fileOrDir != .directory {
            setExt(possibleExt)
            remainingEndIndex = lastDotIndex
        }
        
        // See if we have a file name base
        var remaining = ""
        if remainingStartIndex < remainingEndIndex {
            remaining = String(value[remainingStartIndex..<remainingEndIndex])
        }
        if remaining.count > 0 {
            if fileOrDir == .file {
                setBase(remaining)
                if remainingStartIndex > value.startIndex {
                    pathEnd = value.index(before: remainingStartIndex)
                } else {
                    pathEnd = remainingStartIndex
                }
            } else {
                anotherFolder(remaining)
                pathEnd = remainingEndIndex
                fileOrDir = .directory
            }
        }
        
        // Capture the path
        if value.startIndex < pathEnd {
            path = String(value[value.startIndex..<pathEnd])
        }
    }
    
    /// Save the next folder.
    func anotherFolder(_ nextFolder: String) {
        folders.append(nextFolder)
        folder = nextFolder
    }
    
    /// Set the file extension value
    func setExt(_ ext: String) {
        self.ext = ext
        extLower = ext.lowercased()
        if ext.count > 0 {
            fileOrDir = .file
        }
    }
    
    /// Set the value for the base part of the file name
    /// (without path or extension).
    func setBase(_ base: String) {
        self.base = base
        baseLower = base.lowercased()
    }
    
    /// Determine whether this file/folder is beneath/within the passed folder.
    ///
    /// - Parameter fn2: The possible parent to this file/folder.
    /// - Returns: True if this file is beneath fn2, otherwise false. 
    public func isBeneath(_ fn2: FileName) -> Bool {
        guard folders.count > fn2.folders.count
                || (folders.count == fn2.folders.count
                    && self.typeIsFile && fn2.typeIsDirectory) else { return false }
        var i = 0
        var matched = true
        while i < folders.count && i < fn2.folders.count && matched {
            let folder = String(folders[i])
            let folder2 = String(fn2.folders[i])
            if folder == folder2 {
                i += 1
            } else {
                matched = false
            }
        }
        return matched
    }
    
    /// Resolve a possible relative path relative to the path
    /// for this file name.
    ///
    /// - Parameter path: A possible relative path.
    /// - Returns: An absolute path.
    public func resolveRelative(path: String) -> String {
        
        // If this is an absolute path, then don't mess with it
        guard !path.hasPrefix("/") else { return path }
        
        var resolved = ""
        var foldersToCopy = folders.count
        var looking = true
        var i = 0
        var index = path.startIndex
        while i < path.count && looking {
            let j = i + 3
            if j <= path.count {
                let index2 = path.index(index, offsetBy: 3)
                let nextThree = path[index..<index2]
                if nextThree == "../" {
                    foldersToCopy -= 1
                    index = index2
                    i = j
                } else {
                    looking = false
                }
            }
        }
        resolved.append("/")
        var folderIndex = 0
        while folderIndex < foldersToCopy {
            resolved.append(String(folders[folderIndex]))
            resolved.append("/")
            folderIndex += 1
        }
        resolved.append(String(path[index..<path.endIndex]))
        return resolved
    }
    
    /// Take an absolute path and return a path relative
    /// to the path for this file name.
    public func makeRelative(path: String) -> String {
        
        // If this is already a relative path, then don't mess with it
        guard path.hasPrefix("/") else { return path }
        
        let fileName2 = FileName(path)
        
        return makeRelative(fileName2: fileName2)
    }
    
    public func makeRelative(fileName2: FileName) -> String {
        
        var folderIndex = 0
        while (folderIndex < folders.count
            && folderIndex < fileName2.folders.count
            && folder(at: folderIndex) == fileName2.folder(at: folderIndex)) {
            folderIndex += 1
        }
        let matchedFolders = folderIndex
        var relPath = ""
        while folderIndex < folders.count {
            relPath.append("../")
            folderIndex += 1
        }
        folderIndex = matchedFolders
        while folderIndex < fileName2.folders.count {
            relPath.append(fileName2.folder(at: folderIndex))
            relPath.append("/")
            folderIndex += 1
        }
        relPath.append(fileName2.fileName)
        return relPath
    }
    
    /// Return a single folder (aka directory) in the path,
    /// at a given index position, or a string with no length
    /// if index out of range.
    func folder(at: Int) -> String {
        if at < 0 || at >= folders.count {
            return ""
        } else {
            return String(folders[at])
        }
    }
    
    public func display() {
        print("FileName.display")
        print("  - Complete file name string = \(fileNameStr)")
        print("    - File or Directory? \(fileOrDir)")
        print("    - Path = \(path)")
        print("    - Folder = \(folder)")
        print("    - Base File Name = \(base)")
        print("    - File Ext = \(ext)")
        print("    - Folders:")
        for f in folders {
            print("      - \(f)")
        }
    }
    
}

/// Is this thing a file or a directory?
/// (Or is a decision on that question still pending.)
enum FileOrDirectory {
    case unknown
    case file
    case directory
}
