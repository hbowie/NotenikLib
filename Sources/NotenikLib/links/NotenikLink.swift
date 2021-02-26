//
//  NotenikLink.swift
//
//  Created by Herb Bowie on 12/14/20.

//  Copyright © 2020-2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// URLs in Swift on the Mac can be used for many different things:
/// - To open a page on the world-wide web
/// - To locate a file or folder stored on the user's local drive(s)
/// - To send requests to other locally available apps
/// This class tries to provide useful ways of dealing with all these sorts of URLs. 
public class NotenikLink: CustomStringConvertible, Comparable, Identifiable {

    let fm = FileManager.default
    var bundlePrefix = ""
    var preferredExt: String?
    
    public var url: URL?
    public var str = ""
    public var type: NotenikLinkType = .unknown
    public var noteID = ""
    public var location: NotenikFolderLocation = .undetermined
    
    var collectionTypeDetermined = false
    
    var readme = false
    var infofile = false
    var indexFile = false
    
    /// The lowest level folder in the supplied file name path.
    public var folder = ""
    
    /// An array of all the folders found in the path.
    public var folders: [String] = []
    
    /// Base file name, without preceding path or following extension.
    public var base = ""
    
    /// Base file name converted to all lower-case.
    public var baseLower = ""
    
    /// File extension without a leading dot
    public var ext = ""
    
    /// Lowercase file extension, without a leading dot
    public var extLower = ""
    
    public var scheme: String {
        guard url != nil else { return "" }
        guard url!.scheme != nil else { return "" }
        return url!.scheme!
    }
    
    /**
     Part 1 of the url, delimited by a colon and zero or more slashes
     (as in "http://" or "mailto:")
     */
    var linkPart1 : Substring? = nil
    
    /// The user name part of an e-mail address, if one is present, or the sub-domain.
    var linkPart2 : Substring? = nil
    
    /// The domain name
    var linkPart3 : Substring? = nil
    
    /// Anything following the domain name, except for a trailing slash.
    var linkPart4 : Substring? = nil
    
    /// An ending slash, if one is present. */
    var linkPart5 : Substring? = nil
    
    public var linkStr: String {
        if url == nil {
            return str
        } else {
            return url!.absoluteString
        }
    }
    
    /// Provide a standard string value to represent this object, conforming to CustomStringConvertible.
    public var description: String {
        return linkStr
    }
    
    /// A unique identifier for this object.
    public var id: String {
        return linkStr
    }
    
    /// Default initializer. Values must be set later. 
    public init() {
        bundlePrefix = Bundle.main.bundleURL.absoluteString + "#"
    }
    
    /// Initialize with a url string or a file path.
    public convenience init(str: String, assume: LinkAssumption) {
        self.init()
        set(with: str, assume: assume)
    }
    
    /// Initialize with a URL. 
    public convenience init(url: URL) {
        self.init()
        set(with: url)
    }
    
    /// Initialize with a path to a directory and the name of an item within that directory.
    public convenience init(dir: String, name: String, prefExt: String? = nil) {
        self.init()
        preferredExt = prefExt
        set(dir: dir, name: name)
    }
    
    public convenience init(url: URL, isCollection: Bool) {
        self.init()
        set(with: url)
        if isCollection && type == .folder {
            type = .ordinaryCollection
        }
    }
    
    public convenience init(url: URL,
                            type: NotenikLinkType,
                            location: NotenikFolderLocation) {
        self.init()
        set(with: url)
        self.type = type
        self.location = location
    }
    
    public func set(dir: String, name: String) {
        let joined = FileUtils.joinPaths(path1: dir,
                                         path2: name)
        let joinedURL = URL(fileURLWithPath: joined)
        set(with: joinedURL)
    }
    
    public func set(with url: URL) {
        self.url = url
        str = url.absoluteString
        scanForParts()
        scanFilePath()
        determineType()
    }

    
    /// Let's try to convert a string into a URL, replacing any spaces with encoded ('%20') strings.
    /// If we can't find a scheme, then treat the passed string as a file path.
    public func set(with str: String, assume: LinkAssumption) {
        self.str = str
        var encoded = ""
        var lookingForColon = true
        var colonFound = false
        for char in str {
            if char.isWhitespace {
                encoded.append("%20")
                lookingForColon = false
            } else {
                encoded.append(char)
                if lookingForColon {
                    if char == ":" {
                        colonFound = true
                    } else if char.isPunctuation && char != "-" {
                        lookingForColon = false
                    }
                }
            }
        }
        if colonFound {
            url = URL(string: encoded)
        } else if assume == .assumeFile {
            url = URL(fileURLWithPath: str)
        } else {
            self.str = "https://" + str
            url = URL(string: "https://" + encoded)
        }
        scanFilePath()
        scanForParts()
        determineType()
    }
    
    /// If this is a file URL, scan the path for useful bits.
    func scanFilePath() {
        ext = ""
        extLower = ""
        folder = ""
        folders = []
        base = ""
        baseLower = ""
        guard isFileLink else { return }
        let filePath = path
        guard filePath.count > 0 else { return }
        let isDirectory = isDir
        var remainingStartIndex = filePath.startIndex
        var remainingEndIndex = filePath.endIndex
        var lastDotIndex = filePath.endIndex
        var possibleExtStart = filePath.startIndex
        var lastCharWasSlash = false
        var index = filePath.startIndex
        for char in filePath {
            if char == "/" {
                if index > remainingStartIndex {
                    let nextFolder = String(filePath[remainingStartIndex..<index])
                    anotherFolder(nextFolder)
                }
                remainingStartIndex = filePath.index(after: index)
                lastDotIndex = filePath.endIndex
                lastCharWasSlash = true
            } else if char == "." {
                lastDotIndex = index
                possibleExtStart = filePath.index(after: lastDotIndex)
                lastCharWasSlash = false
            } else {
                lastCharWasSlash = false
            }
            index = filePath.index(after: index)
        }
        
        if lastCharWasSlash {
            remainingEndIndex = filePath.index(before: filePath.endIndex)
        }
        
        // See if we have a file extension
        var possibleExt = ""
        if lastDotIndex < filePath.endIndex && lastDotIndex > remainingStartIndex {
            possibleExt = String(filePath[possibleExtStart..<filePath.endIndex])
        }
        if possibleExt.count > 0 && !isDirectory {
            setExt(possibleExt)
            remainingEndIndex = lastDotIndex
        }
        
        // See if we have a file name base
        var remaining = ""
        if remainingStartIndex < remainingEndIndex {
            remaining = String(filePath[remainingStartIndex..<remainingEndIndex])
        }
        if remaining.count > 0 {
            if !isDirectory {
                setBase(remaining)
            } else {
                anotherFolder(remaining)
            }
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
    }
    
    var isHtmlExt: Bool {
        switch extLower {
        case "htm", "html":
            return true
        default:
            return false
        }
    }
    
    var isNoteExt: Bool {
        if preferredExt != nil && preferredExt! == extLower {
            return true
        }
        switch extLower {
        case "txt", "text", "markdown", "md", "mdown", "mkdown", "mdtext", "notenik", "nnk":
            return true
        default:
            return false
        }
    }
    
    /// Set the value for the base part of the file name
    /// (without path or extension).
    func setBase(_ base: String) {
        self.base = base
        baseLower = base.lowercased()
        
        let readMeStr = "readme"
        let infoStr = "info"
        let indexStr = "index"
        var j = 0
        var k = 0
        var l = 0
        readme = true
        infofile = true
        indexFile = true
        for c in baseLower {
            if StringUtils.isWhitespace(c) {
                // Ignore spaces
            } else if c == "-" {
                // Ignore hyphens
            } else if StringUtils.isAlpha(c) {
                if j < readMeStr.count && c == StringUtils.charAt(index: j, str: readMeStr) {
                    j += 1
                } else {
                    readme = false
                }
                if k < infoStr.count && c == StringUtils.charAt(index: k, str: infoStr) {
                    k += 1
                } else {
                    infofile = false
                }
                if l < indexStr.count && c == StringUtils.charAt(index: l, str: indexStr) {
                    l += 1
                } else {
                    indexFile = false
                }
            } else {
                readme = false
                infofile = false
                indexFile = false
            }
        }
        if j < readMeStr.count {
            readme = false
        }
        if k < infoStr.count {
            infofile = false
        }
        if l < indexStr.count {
            indexFile = false
        }
        if !isNoteExt {
            readme = false
            infofile = false
        }
    }
    
    /// Figure out what sort of URL we have.
    func determineType() {

        let urlString = description
        if description.starts(with: NotenikConstants.urlNavPrefix) {
            type = .wikiLink
            let notePath = String(urlString.dropFirst(NotenikConstants.urlNavPrefix.count))
            noteID = StringUtils.toCommon(notePath)
        } else if description.starts(with: bundlePrefix) {
            type = .wikiLink
            let notePath = String(urlString.dropFirst(bundlePrefix.count))
            noteID = StringUtils.toCommon(notePath)
        } else if isFileLink {
            type = .filelink
            determineFileOrFolderSubType()
        } else if isWebLink {
            type = .weblink
        } else if scheme == "about" {
            type = .aboutlink
        }
        collectionTypeDetermined = false
    }
    
    func determineFileOrFolderSubType() {
        // if str.starts(with: "file:///Users/hbowie/Library/Developer/Xcode/") {
        //     type = .xcodeDev
        // } else
        if str.hasSuffix("/Notenik.app/") {
            type = .notenikApp
        // } else if str.contains("/Notenik-iOS.app/") {
        //     type = .notenikApp
        } else if FileUtils.isDir(path) {
            type = .folder
            determineFolderSubType()
        } else {
            type = .file
            determineFileSubType()
        }
    }
    
    func determineFileSubType() {
        let name = fileOrFolderName
        if name == ".DS_Store" {
            type = .dsstore
        } else if base == "LICENSE" {
            type = .licenseFile
        } else if base == "Collection Parms" {
            type = .collectionParms
        } else if base.count == 0 || base.hasPrefix(".") {
            type = .dotFile
        } else if baseLower == "template" {
            type = .templateFile
        } else if readme {
            type = .readmeFile
        } else if infofile {
            type = .infoFile
        } else if name == NotenikConstants.aliasFileName {
            type = .aliasFile
        } else if isNoteExt {
            type = .noteFile
        } else if hasScriptExt {
            type = .script
        }
    }
    
    func determineFolderSubType() {
        let name = fileOrFolderName
        if name == NotenikConstants.reportsFolderName {
            type = .reportsFolder
        } else if name == NotenikConstants.mirrorFolderName {
            type = .mirrorFolder
        }
    }
    
    /// This method should only be called when needed in a particular context. It is not automatically
    /// performed upon initialization or when a new value is set.
    public func determineCollectionType() {
        guard !collectionTypeDetermined else { return }
        guard type == .folder ||
              (type == .xcodeDev && isDir) else {
            return
        }
        
        let folderPath = path
        
        // See if this points to an existing Collection.
        let infoPath = FileUtils.joinPaths(path1: folderPath, path2: NotenikConstants.infoFileName)
        if fm.fileExists(atPath: infoPath)
            && fm.isReadableFile(atPath: infoPath) {
            type = .ordinaryCollection
            return
        }
        
        // See if there is a sub-folder containing the notes.
        let notesPath = FileUtils.joinPaths(path1: folderPath, path2: NotenikConstants.notesFolderName)
        if fm.fileExists(atPath: notesPath)
            && fm.isReadableFile(atPath: notesPath) {
            type = .webCollection
            return
        }
        
        // Let's examine folder contents to see what else it might be.
        var contents: [String] = []
        do {
            contents = try fm.contentsOfDirectory(atPath: folderPath)
        } catch {
            return
        }

        // See if the folder is truly empty.
        if contents.count == 0 {
            type = .emptyFolder
            return
        }
        
        // If not empty, then let's see what sort of stuff it contains.
        var foldersFound = 0
        var notesFound = 0
        var itemsFound = 0
        for itemPath in contents {
            let itemLink = NotenikLink(dir: folderPath, name: itemPath)
            if itemLink.type == .dsstore {
                // pretend it's not there
            } else {
                itemsFound += 1
                if itemLink.type == .folder {
                    foldersFound += 1
                } else if itemLink.type == .noteFile {
                    notesFound += 1
                }
            }
        }
        
        if notesFound > 0 {
            type = .ordinaryCollection
        } else if foldersFound > 0 {
            type = .realm
        } else if itemsFound == 0 {
            type = .emptyFolder
        }
        collectionTypeDetermined = true
    }
    
    public var fileOrFolderName: String {
        guard isFileLink else { return "" }
        guard let defURL = url else { return "" }
        return defURL.lastPathComponent
    }
    
    public var path: String {
        guard isFileLink else { return "" }
        guard let defURL = url else { return "" }
        return defURL.path
    }
    
    var isDir: Bool {
        guard isFileLink else { return false }
        let defPath = path
        guard defPath.count > 0 else { return false }
        return FileUtils.isDir(defPath)
    }
    
    /// Is this a local file resource that is reachable?
    var isReachable: Bool {
        guard isFileLink else { return false }
        guard let defURL = url else { return false }
        var folderReachable = false
        do {
            folderReachable = try defURL.checkResourceIsReachable()
        } catch {
            return false
        }
        return folderReachable
    }
    
    /// Is this the sort of link that points to a local file?
    var isFileLink: Bool {
        if let defURL = url {
            return defURL.isFileURL
        } else {
            return str.starts(with: "file://")
        }
    }
    
    var isWebLink: Bool {
        return scheme == "http" || scheme == "https"
    }
    
    var hasScriptExt: Bool {
        if let defURL = url {
            return defURL.lastPathComponent.hasSuffix(NotenikConstants.scriptExt)
        } else {
            return str.hasSuffix(NotenikConstants.scriptExt)
        }
    }
    
    /// Parse the input string and break it down into its various components
    func scanForParts() {
        
        linkPart1 = nil
        linkPart2 = nil
        linkPart3 = nil
        linkPart4 = nil
        linkPart5 = nil
        
        var p1End = -1
        var p2End = -1
        var p3End = -1
        var p4End = -1
        var p5End = -1
        
        var firstPeriod = -1
        var periodCount = 0
        
        var i = 0
        let last = str.count - 1
        
        for c in str {
            if c == ":" && p1End < 0  {
                p1End = i
            } else if c == "/" && i == (p1End + 1) {
                p1End = i
            } else if c == "@" && p2End < 0 {
                p2End = i
            } else if c == "." && p3End < 0 {
                if periodCount == 0 {
                    firstPeriod = i
                }
                periodCount += 1
            } else if (c == "/"  || i == last) && p3End < 0 {
                p3End = i
                if periodCount > 1 && p2End < 0 {
                    p2End = firstPeriod
                }
                if p2End < 0 {
                    p2End = p1End
                }
            } else if c == "/" && i == last {
                p4End = i - 1
                p5End = i
            } else if i == last {
                p4End = i
            }
            i += 1
        }
        
        let p1StartIndex = str.startIndex
        var p2StartIndex = str.startIndex
        var p3StartIndex = str.startIndex
        var p4StartIndex = str.startIndex
        var p5StartIndex = str.startIndex
        
        if p1End >= 0 {
            let p1EndIndex = str.index(p1StartIndex, offsetBy: p1End)
            linkPart1 = str [str.startIndex...p1EndIndex]
            p2StartIndex = str.index(str.startIndex, offsetBy: p1End + 1)
            p3StartIndex = p2StartIndex
            p4StartIndex = p2StartIndex
            p5StartIndex = p2StartIndex
        }
        
        if p2End >= 0 && p2End > p1End {
            let p2EndIndex = str.index(str.startIndex, offsetBy: p2End)
            linkPart2 = str [p2StartIndex...p2EndIndex]
            p3StartIndex = str.index(str.startIndex, offsetBy: p2End + 1)
            p4StartIndex = p3StartIndex
            p5StartIndex = p3StartIndex
        }
        
        if p3End >= 0 && p3End > p2End {
            let p3EndIndex = str.index(str.startIndex, offsetBy: p3End)
            linkPart3 = str [p3StartIndex...p3EndIndex]
            p4StartIndex = str.index(str.startIndex, offsetBy: p3End + 1)
            p5StartIndex = p4StartIndex
        }
        
        if p4End >= 0 && p4End > p3End {
            let p4EndIndex = str.index(str.startIndex, offsetBy: p4End)
            linkPart4 = str [p4StartIndex...p4EndIndex]
            p5StartIndex = str.index(str.startIndex, offsetBy: p4End + 1)
        }
        
        if p5End >= 0 && p5End > p4End && p5End > p3End {
            let p5EndIndex = str.index(str.startIndex, offsetBy: p5End)
            linkPart5 = str [p5StartIndex...p5EndIndex]
        }
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public var sortKey: String {
        return getLinkPart3() + getLinkPart1() + getLinkPart2() + getLinkPart4()
    }
    
    /// Return the first part of the link (up to the initial colon) as a string
    func getLinkPart1() -> String {
        if linkPart1 == nil {
            return ""
        } else {
            return String(linkPart1!)
        }
    }
    
    /// Return the second part of the link (up to the at sign or initial period) as a string
    func getLinkPart2() -> String {
        if linkPart2 == nil {
            return ""
        } else {
            return String(linkPart2!)
        }
    }
    
    /// Return the third part of the link (the domain name) as a string
    func getLinkPart3() -> String {
        if linkPart3 == nil {
            return ""
        } else {
            return String(linkPart3!)
        }
    }
    
    /// Return the fourth part of the link (following the domain name) as a string
    func getLinkPart4() -> String {
        if linkPart4 == nil {
            return ""
        } else {
            return String(linkPart4!)
        }
    }
    
    /// Return the final part of the link (an optional trailing slash) as a string
    func getLinkPart5() -> String {
        if linkPart5 == nil {
            return ""
        } else {
            return String(linkPart5!)
        }
    }
    
    /// Display values for debugging purposes.
    public func display() {
        print("Display NotenikLink for \(self)")
        print("  - str = \(str)")
        if url == nil {
            print("  - url is nil")
        } else {
            print("  - url = \(url!.absoluteString)")
        }
        print("  - scheme = \(scheme)")
        print("  - is file link? \(isFileLink)")
        print("  - is directory? \(isDir)")
        print("  - is web  link? \(isWebLink)")
        print("  - type = \(type)")
        print("  - location = \(location)")
        print("  - sort key = '\(sortKey)'")
        print("  - file or folder name = \(fileOrFolderName)")
        if linkPart1 != nil {
            print("  - Link Part 1: '\(linkPart1!)'")
        }
        if linkPart2 != nil {
            print("  - Link Part 2: '\(linkPart2!)'")
        }
        if linkPart3 != nil {
            print("  - Link Part 3: '\(linkPart3!)'")
        }
        if linkPart4 != nil {
            print("  - Link Part 4: '\(linkPart4!)'")
        }
        if linkPart5 != nil {
            print("  - Link Part 5: '\(linkPart5!)'")
        }
    }
    
    /// Is the left-hand side less than the right-hand side?
    public static func < (lhs: NotenikLink, rhs: NotenikLink) -> Bool {
        return lhs.linkStr < rhs.linkStr
    }
    
    /// Is the left-hand side equal to the right-hand side?
    public static func == (lhs: NotenikLink, rhs: NotenikLink) -> Bool {
        return lhs.linkStr == rhs.linkStr
    }
    
}

public enum LinkAssumption {
    case assumeFile
    case assumeWeb
}
