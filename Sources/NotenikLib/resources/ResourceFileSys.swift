//
//  ResourceFileSys.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/26/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// An object representing a resource obtained from the file system.
public class ResourceFileSys: CustomStringConvertible, Comparable, Equatable {
    
    // -----------------------------------------------------------
    //
    // MARK: Constants and simple Variables
    //
    // -----------------------------------------------------------
    
    let fm = FileManager.default
    
    static let aliasFileName     = "alias.txt"
    static let cloudyPrefix      = "."
    static let cloudySuffix      = ".icloud"
    public static let displayCSSFileName = "display.css"
    public static let displayHTMLFileName = "display.html"
    static let dsstoreFileName   = ".DS_Store"
    static let exportFolderName  = "export"
    static let infoFileName      = "- INFO.nnk"
    static let infoParentFileName = "- INFO-parent-realm.nnk"
    static let klassFolderName   = "class"
    static let mirrorFolderName  = "mirror"
    static let notesFolderName   = "notes"
    static let oldSourceParms    = "pspub_source_parms.xml"
    static let readmeFileName    = "- README.txt"
    static let reportsFolderName = "reports"
    static let scriptExt         = ".tcz"
    static let templateFileName  = "template"
    
    public var isAvailable: Bool { return exists && isReadable }
    public var exists = false
           var isCloudy = false
    public var isReadable = false
    public var isDirectory = false
    
    public var type: ResourceType = .unknown

    var base = ""
    var baseLower = ""
    var baseCommon = ""
    var extLower = ""
    
    // -----------------------------------------------------------
    //
    // MARK: Initializers
    //
    // -----------------------------------------------------------
    
    /// This initializer just provides a way to define an instance that does not exist. It should be
    /// replaced with one created by another init before expecting it to point to anything.
    init() {
        
    }
    
    /// Initialize with a parent resource and a file/folder name. 
    convenience init(parent: ResourceFileSys, 
                     fileName: String,
                     type: ResourceType = .unknown,
                     preferredNoteExt: String = "txt") {
        
        self.init(folderPath: parent.actualPath,
                  fileName: fileName,
                  type: type,
                  preferredNoteExt: preferredNoteExt)
    }
    
    /// Initialize with the path to the enclosing folder, plus the item within the folder.
    public init(folderPath: String, 
                fileName: String,
                type: ResourceType = .unknown,
                preferredNoteExt: String = "txt") {
        
        self.folderPath = folderPath
        self.type = type
        if fileName.hasPrefix(ResourceFileSys.cloudyPrefix) && fileName.hasSuffix(ResourceFileSys.cloudySuffix) {
            let start = fileName.index(fileName.startIndex, offsetBy: ResourceFileSys.cloudyPrefix.count)
            let end = fileName.index(fileName.endIndex, offsetBy: (0 - ResourceFileSys.cloudySuffix.count))
            self.fileName = String(fileName[start..<end])
        } else {
            self.fileName = fileName
        }
        checkStatus(preferredNoteExt: preferredNoteExt)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Accessors to be queried by other classes. 
    //
    // -----------------------------------------------------------
    
    public var url: URL? {
        if exists {
            return URL(fileURLWithPath: actualPath)
        } else {
            return URL(fileURLWithPath: proposedPath)
        }
    }
    
    public var description: String {
        return actualPath
    }
    
    public var actualPath: String {
        if isCloudy {
            return cloudyPath
        } else if exists {
            return normalPath
        } else {
            return ""
        }
    }
    
    public var proposedPath: String {
        if isCloudy {
            return cloudyPath
        } else {
            return normalPath
        }
    }
    
    var normalPath: String {
        if fileName.count > 0 {
            return folderPath + "/" + fileName
        } else {
            return folderPath
        }
    }
    
    var cloudyPath: String {
        if fileName.count > 0 {
            return folderPath + "/" + ResourceFileSys.cloudyPrefix + fileName + ResourceFileSys.cloudySuffix
        } else {
            return folderPath
        }
    }
    
    /// The path to the folder, without a trailing slash.
    var folderPath: String {
        get {
            return _fPath
        }
        set {
            var e1 = newValue.endIndex
            if newValue.hasSuffix("/") {
                e1 = newValue.index(newValue.startIndex, offsetBy: newValue.count - 1)
            }
            _fPath = String(newValue[..<e1])
        }
    }
    var _fPath = ""
    
    /// The file name, without a leading slash.
    var fileName: String {
        get {
            return _fName
        }
        set {
            var s2 = newValue.startIndex
            if newValue.hasPrefix("/") {
                s2 = newValue.index(newValue.startIndex, offsetBy: 1)
            }
            _fName = String(newValue[s2..<newValue.endIndex])
            
            var s3 = newValue.endIndex
            var s4 = newValue.endIndex
            var c: Character = " "
            while s4 > s2 && c != "." {
                s3 = s4
                s4 = newValue.index(before: s3)
                c = newValue[s4]
            }
            
            base = ""
            baseLower = ""
            var ext = ""
            extLower = ""
            
            if c == "." {
                base = String(newValue[s2..<s4])
                ext = String(newValue[s3..<newValue.endIndex])
                extLower = ext.lowercased()
            } else {
                base = _fName
            }
            baseLower = base.lowercased()
            baseCommon = StringUtils.toCommon(base)
        }
    }
    var _fName = ""
    
    /// Attempt to read text from this resource and format it as a Note.
    func readNote(collection: NoteCollection, template: Bool = false, reportErrors: Bool = true) -> Note? {
        
        guard let noteURL = url else { return nil }
        let reader = BigStringReader(fileURL: noteURL)
        guard reader != nil else {
            if reportErrors {
                logError("Error reading Note from \(noteURL)")
            }
            return nil
        }
        let parser = NoteLineParser(collection: collection, reader: reader!)
        let defaultTitle = noteURL.deletingPathExtension().lastPathComponent
        let note = parser.getNote(defaultTitle: defaultTitle, template: template)
        note.noteID.setExistingFileName(noteURL.lastPathComponent)
        if collection.textFormatFieldDef != nil {
            if noteURL.pathExtension == NotenikConstants.textFormatTxt {
                _ = note.setTextFormat(NotenikConstants.textFormatTxt)
            } else {
                _ = note.setTextFormat(NotenikConstants.textFormatMD)
            }
        }
        updateEnvDates(note: note, noteURL: noteURL)
        note.identify()
        return note
    }
    
    /// Write a note to disk.
    /// - Parameter note: The note to be written.
    /// - Returns: Success?
    func writeNote(_ note: Note) -> Bool {
        
        let collection = note.collection
        guard let lib = collection.lib else { return false }
        guard lib.hasAvailable(type: .notes) else { return false }
        guard !note.noteID.isEmpty else { return false }
        
        let preTimestamp = note.timestampAsString
        
        if collection.textFormatFieldDef != nil {
            if note.textFormat.isText {
                let pieces = fileName.components(separatedBy: ".")
                if pieces.count > 1 {
                    var newFileName = ""
                    var i = 0
                    while i < pieces.count {
                        if i < pieces.count - 1 {
                            newFileName.append(pieces[i])
                            newFileName.append(".")
                        } else {
                            newFileName.append("txt")
                        }
                        i += 1
                    }
                    fileName = newFileName
                }
            }
        }
        guard writeNoteAtomic(note) else { return false }
        
        let noteURL = URL(fileURLWithPath: proposedPath)
        updateEnvDates(note: note, noteURL: noteURL)
        if collection.hasTimestamp {
            let postTimestamp = note.timestampAsString
            if !postTimestamp.isEmpty && postTimestamp != preTimestamp {
                let ok = writeNoteAtomic(note)
                if !ok {
                    logError("Trouble rewriting Note with timestamp")
                }
            }
        }
        type = .note
        
        return true
    }
    
    func writeNoteAtomic(_ note: Note) -> Bool {
        let writer = BigStringWriter()
        let maker = NoteLineMaker(writer)
        let fieldsWritten = maker.putNote(note)
        guard fieldsWritten > 0 else { return false }
        
        let written = write(str: writer.bigString)
        return written
    }
    
    /// Update the Note with the latest creation and modification dates from our storage environment
    func updateEnvDates(note: Note, noteURL: URL) {
        do {
            let attributes = try fm.attributesOfItem(atPath: noteURL.path)
            let creationDate = attributes[FileAttributeKey.creationDate]
            let lastModDate = attributes[FileAttributeKey.modificationDate]
            if creationDate != nil {
                let creationDateStr = String(describing: creationDate!)
                note.envCreateDate = creationDateStr
            } else {
                logError("Inscrutable creation date for note at \(noteURL.path)")
            }
            if (lastModDate != nil) {
                let lastModDateStr = String(describing: lastModDate!)
                note.envModDate = lastModDateStr
            } else {
                logError("Inscrutable modification date for note at \(noteURL.path)")
            }
            note.identify()
        }
        catch {
            logError("Unable to obtain file attributes for for note at \(noteURL.path)")
        }
    }
    
    /// Return an array of resources found at the top level within this resource. 
    func getResourceContents(preferredNoteExt: String = "txt") -> [ResourceFileSys]? {
        guard isAvailable && isDirectory else { return nil }
        var contents: [ResourceFileSys] = []
        var items: [String] = []
        do {
            items = try fm.contentsOfDirectory(atPath: actualPath)
        } catch {
            logError("Could not load contents of directory at \(actualPath)")
            logError("- Error: \(error)")
            return nil
        }
        var contentType: ResourceType = .unknown
        switch type {
        case .attachments:
            contentType = .attachment
        case .reports:
            contentType = .report
        default:
            break
        }
        for item in items {
            var itemType = contentType
            if contentType == .report && item.hasSuffix(ResourceFileSys.scriptExt) {
                itemType = .script
            } else if type == .exportFolder && item.hasSuffix(ResourceFileSys.scriptExt) {
                itemType = .exportScript
            }
            let resource = ResourceFileSys(folderPath: actualPath, 
                                           fileName: item,
                                           type: itemType,
                                           preferredNoteExt: preferredNoteExt)
            contents.append(resource)
        }
        return contents
    }
    
    /// See if the specified folder is empty (ignoring hidded macOS trickery). .
    public func isEmpty() -> Bool {
        guard isAvailable && isDirectory else { return true }
        guard let items = getFolderContents() else { return false }
        if items.count == 0 {
            return true
        } else {
            for item in items {
                if item != ResourceFileSys.dsstoreFileName {
                    return false
                }
            }
            return true
        }
    }
    
    /// Attempt to return an array of directory entries within this resource..
    func getFolderContents() -> [String]? {
        guard isAvailable && isDirectory else { return nil }
        do {
            return try fm.contentsOfDirectory(atPath: actualPath)
        } catch {
            logError("Could not load contents of directory at \(actualPath)")
            logError("- Error: \(error)")
            return nil
        }
    }
    
    func getDelimited(consumer: RowConsumer) -> Bool {
        guard isAvailable else { return false }
        guard !isDirectory else { return false }
        guard let delimURL = url else { return false }
        let reader = DelimitedReader()
        reader.setContext(consumer: consumer)
        reader.read(fileURL: delimURL)
        return true
    }
    
    func getText() -> String {
        guard isAvailable else { return "" }
        guard !isDirectory else { return "" }
        guard let textURL = url else { return "" }
        do {
            let text = try String(contentsOf: textURL)
            return text
        } catch {
            return ""
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Store and Update Routines
    //
    // -----------------------------------------------------------
    
    public func ensureExistence() -> Bool {
        return createDirectory()
    }
    
    /// Attempt to create this folder.
    func createDirectory() -> Bool {
        if exists {
            return true
        }
        guard let newURL = url else { return false }
        do {
            try fm.createDirectory(at: newURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logError("Could not create a new directory at \(newURL.path)")
            return false
        }
        checkStatus()
        return true
    }
    
    func write(str: String) -> Bool {
        do {
            try str.write(toFile: proposedPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            logError("Problem writing file to to disk at: \(proposedPath)")
            return false
        }
        exists = true
        isReadable = true
        return true
    }
    
    func remove() -> Bool {
        guard exists else {
            return false
        }
        guard let urlToRemove = url else { return false }
        var trashOK = false
        do {
            try fm.trashItem(at: urlToRemove, resultingItemURL: nil)
            trashOK = true
        } catch {
            trashOK = false
        }
        if trashOK { return true }
        do {
            try fm.removeItem(at: urlToRemove)
        } catch {
            logError("Error trying to remove item at: \(urlToRemove.path)")
            return false
        }
        return true
    }
    
    /// Attempt to change the file extension for the resource, returning a new resource with the new extension.
    func changeExt(to: String) -> ResourceFileSys? {
        guard isAvailable else { return nil }
        let toResource = ResourceFileSys(folderPath: folderPath, fileName: base + "." + to, type: type, preferredNoteExt: to)
        do {
            try fm.moveItem(atPath: actualPath, toPath: toResource.proposedPath)
        } catch {
            logError("Unable to Change File Extension to \(to) for \(actualPath)")
            return nil
        }
        toResource.checkStatus(preferredNoteExt: to)
        return toResource
    }
    
    func copyTo(to: ResourceFileSys) -> Bool {
        guard isAvailable else { return false }
        do {
            try fm.copyItem(atPath: actualPath, toPath: to.proposedPath)
        } catch {
            logError("Unable to copy item \nfrom \(actualPath) \nto \(to.proposedPath) \ndue to following error: \(error)")
            return false
        }
        return true
    }
    
    func rename(to newPath: String) -> Bool {
        guard isAvailable else {
            logError("Resource not available to rename - \(self)")
            return false
        }
        let oldPath = actualPath
        guard oldPath != newPath else {
            logError("New path for resource rename is identical to old path")
            return false
        }
        do {
            try fm.moveItem(atPath: oldPath, toPath: newPath)
        } catch let error as NSError {
            logError("Could not rename file from \(oldPath) to \(newPath)")
            logError("Due to \(error)")
            return false
        }
        let newName = FileName(newPath)
        self.folderPath = newName.path
        let fileName = newName.fileName
        if fileName.hasPrefix(ResourceFileSys.cloudyPrefix) && fileName.hasSuffix(ResourceFileSys.cloudySuffix) {
            let start = fileName.index(fileName.startIndex, offsetBy: ResourceFileSys.cloudyPrefix.count)
            let end = fileName.index(fileName.endIndex, offsetBy: (0 - ResourceFileSys.cloudySuffix.count))
            self.fileName = String(fileName[start..<end])
        } else {
            self.fileName = fileName
        }
        checkStatus(preferredNoteExt: "txt")
        return true
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Figure out what sort of file system resource we have. 
    //
    // -----------------------------------------------------------
    
    func checkStatus(preferredNoteExt: String = "txt") {
        exists = false
        isCloudy = false
        isReadable = false
        self.isDirectory = false
        var isDirectory: ObjCBool = false
        exists = fm.fileExists(atPath: normalPath, isDirectory: &isDirectory)
        if !exists {
            exists = fm.fileExists(atPath: cloudyPath, isDirectory: &isDirectory)
            if exists {
                isCloudy = true
            }
        }
        if exists {
            self.isDirectory = isDirectory.boolValue
            isReadable = fm.isReadableFile(atPath: actualPath)
            if self.isDirectory {
                examineFolderName()
            } else {
                examineFileName(preferredNoteExt: preferredNoteExt)
            }
        }
    }
    
    func examineFolderName() {
        guard type == .unknown else { return }
        if _fName == ResourceFileSys.reportsFolderName {
            type = .reports
        } else if _fName == NotenikConstants.filesFolderName {
            type = .attachments
        } else if _fName == ResourceFileSys.exportFolderName {
            type = .exportFolder
        } else if _fName == ResourceFileSys.klassFolderName {
            type = .klassFolder
        } else {
            type = .folder
        }
    }
        
    func examineFileName(preferredNoteExt: String = "txt") {
        if extLower == ResourceFileSys.scriptExt {
            type = .script
        }
        guard type == .unknown else { return }
        if _fName == ResourceFileSys.dsstoreFileName {
            type = .noise
        } else if (_fName == "LICENSE" || _fName == "LICENSE.txt" || _fName == "LICENSE.md") {
            type = .license
        } else if (_fName == "README" || _fName == "README.txt" || _fName == "README.md" || _fName == "- README.txt") {
            type = .readme
        } else if _fName == "robots.txt" {
            type = .robots
        } else if (baseLower == "collection parms") {
            type = .collectionParms
        } else if (_fName == ResourceFileSys.aliasFileName) {
            type = .alias
        } else if (_fName == ResourceFileSys.infoFileName) {
            type = .info
        } else if (_fName == ResourceFileSys.infoParentFileName) {
            type = .infoParent
        } else if (_fName.starts(with: "- INFO") && extLower == "nnk" && _fName.contains("conflicted copy")) {
            type = .infoConflicted
        } else if (_fName == ResourceFileSys.displayHTMLFileName) {
            type = .display
        } else if (_fName == ResourceFileSys.displayCSSFileName) {
            type = .displayCSS
        } else if baseLower == ResourceFileSys.templateFileName && extLower.count > 0 {
            type = .template
        } else if base == NotenikConstants.tempDisplayBase && extLower == NotenikConstants.tempDisplayExt {
            type = .tempDisplay
        } else if ResourceFileSys.isLikelyNoteFile(fileExt: extLower, preferredNoteExt: preferredNoteExt) {
            type = .note
        } else if extLower == ResourceFileSys.scriptExt {
            type = .script
        } 
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Logging
    //
    // -----------------------------------------------------------
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ResourceFileSys",
                          level: .error,
                          message: msg)
    }
    
    public func display() {
        print("ResourceFileSys")
        print("  - file name: \(fileName)")
        print("  - base: \(base)")
        print("  - base lowered: \(baseLower)")
        print("  - ext lowered: \(extLower)")
        print("  - type: \(type)")
        print("  - exists? \(exists)")
        print("  - is readable? \(isReadable)")
        print("  - is directory? \(isDirectory)")
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Static methods.
    //
    // -----------------------------------------------------------
    
    public static func isLikelyNoteFile(fileURL: URL, preferredNoteExt: String?) -> Bool {
        return ResourceFileSys.isLikelyNoteFile(fileExt: fileURL.pathExtension,
                                                preferredNoteExt: preferredNoteExt)
    }
    
    public static func isLikelyNoteFile(fileExt: String, preferredNoteExt: String?) -> Bool {
        let extLower = fileExt.lowercased()
        switch extLower {
        case preferredNoteExt:
            return true
        case "txt", "text", "markdown", "md", "mdown", "mkdown", "mdtext", "mktext", "notenik", "nnk":
            return true
        default:
            break
        }
        return false
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Comparable and Equatable methods. 
    //
    // -----------------------------------------------------------
    
    public static func < (lhs: ResourceFileSys, rhs: ResourceFileSys) -> Bool {
        return lhs.normalPath < rhs.normalPath
    }
    
    public static func == (lhs: ResourceFileSys, rhs: ResourceFileSys) -> Bool {
        return lhs.normalPath == rhs.normalPath
    }

}
