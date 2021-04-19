//
//  ResourceLibrary.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/27/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A repository from which to obtain the various resources that might be found
/// within a particular Notenik Collection.
public class ResourceLibrary {
    
    // -----------------------------------------------------------
    //
    // MARK: Constants and ordinary Variables
    //
    // -----------------------------------------------------------
    
    let fm = FileManager.default
    
    var readyForUse = false
    
    var realm: Realm
    
    var subFoldersFound = 0
    var notesFound = 0
    var itemsFound = 0
    
    var parentFolder      = ResourceFileSys()
    var collection        = ResourceFileSys()
    var notesFolder       = ResourceFileSys()
    var notesSubFolder    = ResourceFileSys()
    var readmeFile        = ResourceFileSys()
    var infoFile          = ResourceFileSys()
    var templateFile      = ResourceFileSys()
    var displayFile       = ResourceFileSys()
    var displayCSSFile    = ResourceFileSys()
    var aliasFile         = ResourceFileSys()
    var attachmentsFolder = ResourceFileSys()
    var mirrorFolder      = ResourceFileSys()
    var reportsFolder     = ResourceFileSys()
    
    var infoCollection:   NoteCollection?
    
    /// Reset derived values when the collection path changes.
    func initVariables() {
        readyForUse = false
        collection = ResourceFileSys()
        subFoldersFound = 0
        notesFound = 0
        itemsFound = 0
        parentFolder    = ResourceFileSys()
        notesFolder     = ResourceFileSys()
        notesSubFolder  = ResourceFileSys()
        readmeFile      = ResourceFileSys()
        infoFile        = ResourceFileSys()
        templateFile    = ResourceFileSys()
        displayFile     = ResourceFileSys()
        displayCSSFile  = ResourceFileSys()
        aliasFile       = ResourceFileSys()
        attachmentsFolder = ResourceFileSys()
        mirrorFolder    = ResourceFileSys()
        reportsFolder   = ResourceFileSys()
        
        infoCollection  = NoteCollection()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Initializers
    //
    // -----------------------------------------------------------
    
    init() {
        self.realm = Realm()
    }
    
    init(realm: Realm) {
        self.realm = realm
        infoCollection = NoteCollection(realm: realm)
    }
    
    init(realm: Realm, pathWithinRealm: String) {
        self.realm = realm
        infoCollection = NoteCollection(realm: realm)
        self.pathWithinRealm = pathWithinRealm
    }
    
    /// The initializers only determines whether this is a Collection, and what sort
    /// of Collection it might be. Once a caller is ready to use the Collection, this method
    /// must be called.
    func prepareForUse() {
        if !readyForUse {
            scanForResources()
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Accessors for various sorts of Collection Resources
    //
    // -----------------------------------------------------------
    
    public func hasAvailable(type: ResourceType) -> Bool {
        switch type {
        case .alias:
            return aliasFile.isAvailable
        case .attachments:
            return attachmentsFolder.isAvailable
        case .collection:
            return collection.isAvailable
        case .display:
            return displayFile.isAvailable
        case .displayCSS:
            return displayCSSFile.isAvailable
        case .info:
            return infoFile.isAvailable
        case .mirror:
            return mirrorFolder.isAvailable
        case .notes:
            return notesFolder.isAvailable
        case .notesSubfolder:
            return notesSubFolder.isAvailable
        case .parent:
            return parentFolder.isAvailable
        case .readme:
            return readmeFile.isAvailable
        case .reports:
            return reportsFolder.isAvailable
        case .template:
            return templateFile.isAvailable
        default:
            return false
        }
    }
    
    public func getPath(type: ResourceType) -> String {
        switch type {
        case .alias:
            return aliasFile.actualPath
        case .attachments:
            return attachmentsFolder.actualPath
        case .collection:
            return collection.actualPath
        case .display:
            return displayFile.actualPath
        case .displayCSS:
            return displayCSSFile.actualPath
        case .info:
            return infoFile.actualPath
        case .mirror:
            return mirrorFolder.actualPath
        case .notes:
            return notesFolder.actualPath
        case .notesSubfolder:
            return notesSubFolder.actualPath
        case .parent:
            return parentFolder.actualPath
        case .readme:
            return readmeFile.actualPath
        case .reports:
            return reportsFolder.actualPath
        case .template:
            return templateFile.actualPath
        default:
            return ""
        }
    }
    
    public func getURL(type: ResourceType) -> URL? {
        switch type {
        case .alias:
            return aliasFile.url
        case .attachments:
            return attachmentsFolder.url
        case .collection:
            return collection.url
        case .display:
            return displayFile.url
        case .displayCSS:
            return displayCSSFile.url
        case .info:
            return infoFile.url
        case .mirror:
            return mirrorFolder.url
        case .notes:
            return notesFolder.url
        case .notesSubfolder:
            return notesSubFolder.url
        case .parent:
            return parentFolder.url
        case .readme:
            return readmeFile.url
        case .reports:
            return reportsFolder.url
        case .template:
            return templateFile.url
        default:
            return nil
        }
    }
    
    public func getResource(type: ResourceType) -> ResourceFileSys {
        switch type {
        case .alias:
            return aliasFile
        case .attachments:
            return attachmentsFolder
        case .collection:
            return collection
        case .display:
            return displayFile
        case .displayCSS:
            return displayCSSFile
        case .info:
            return infoFile
        case .mirror:
            return mirrorFolder
        case .notes:
            return notesFolder
        case .notesSubfolder:
            return notesSubFolder
        case .parent:
            return parentFolder
        case .readme:
            return readmeFile
        case .reports:
            return reportsFolder
        case .template:
            return templateFile
        default:
            return ResourceFileSys()
        }
    }
    
    public func ensureResource(type: ResourceType) -> ResourceFileSys {
        switch type {
        case .attachments:
            if attachmentsFolder.isAvailable {
                return attachmentsFolder
            }
            attachmentsFolder = ResourceFileSys(parent: notesFolder, fileName: ResourceFileSys.filesFolderName, type: .attachments)
            _ = attachmentsFolder.ensureExistence()
            return attachmentsFolder
        default:
            return ResourceFileSys()
        }
    }
    
    /// Attempt to create a Resource for the given Note.
    func getNoteResource(note: Note) -> ResourceFileSys? {
        guard notesFolder.isAvailable else { return nil }
        guard let fileName = note.fileInfo.baseDotExt else { return nil }
        return ResourceFileSys(parent: notesFolder, fileName: fileName, type: .note)
    }
    
    func getAttachmentResource(fileName: String) -> ResourceFileSys? {
        guard attachmentsFolder.isAvailable else { return nil }
        return ResourceFileSys(parent: attachmentsFolder, fileName: fileName, type: .attachment)
    }
    
    func getContents(type: ResourceType) -> [ResourceFileSys]? {
        switch type {
        case .attachments:
            return attachmentsFolder.getResourceContents()
        case .mirror:
            return mirrorFolder.getResourceContents()
        case .notes:
            return notesFolder.getResourceContents()
        case .parent:
            return parentFolder.getResourceContents()
        case .reports:
            return reportsFolder.getResourceContents()
        default:
            return nil
        }
    }
    
    func getNote(type: ResourceType) -> Note? {
        
        switch type {
        case .info:
            guard infoFile.isAvailable else { return nil }
            let infoCollection = NoteCollection(realm: realm)
            infoCollection.path = notesFolder.actualPath
            return infoFile.readNote(collection: infoCollection)
        default:
            return nil
        }
    }
    
    func getNote(type: ResourceType, collection: NoteCollection) -> Note? {
        
        switch type {
        case .info:
            return getNote(type: type)
        case .template:
            guard templateFile.isAvailable else { return nil }
            return templateFile.readNote(collection: collection)
        default:
            return nil
        }
    }
    
    /// Get a regular note, given its name.
    func getNote(type: ResourceType,
                 collection: NoteCollection,
                 fileName: String,
                 reportErrors: Bool = true)  -> Note? {
        
        guard notesFolder.isAvailable else { return nil }
        
        switch type {
        case .info:
            return getNote(type: type)
        case .note:
            let noteResource = ResourceFileSys(parent: notesFolder, fileName: fileName, type: .note)
            return noteResource.readNote(collection: collection, reportErrors: reportErrors)
        case .template:
            return getNote(type: type, collection: collection)
        default:
            return nil
        }
    }
    
    func getDelimited(type: ResourceType,
                      consumer: RowConsumer) -> Bool {
        switch type {
        case .alias:
            return aliasFile.getDelimited(consumer: consumer)
        default:
            return false
        }
    }
    
    var templateExt: String {
        if templateFile.isAvailable {
            return templateFile.extLower
        } else {
            return "txt"
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Store and Update Routines
    //
    // -----------------------------------------------------------
    
    /// Copy a new attachment and store it in the attachment (aka files) subfolder.
    func storeAttachment(fromURL: URL, attachmentName: String) -> ResourceFileSys? {
        
        guard notesFolder.isAvailable else { return nil }
        
        if !attachmentsFolder.exists {
            let ok = attachmentsFolder.createDirectory()
            if !ok {
                return nil
            }
        }
        
        let attachmentResource = ResourceFileSys(parent: attachmentsFolder, fileName: attachmentName, type: .unknown)
        
        if attachmentResource.url == nil {
            logError("Couldn't get a URL for the attachment named '\(attachmentName)'")
            return nil
        }
        
        if attachmentResource.exists {
            logError("Attachment already exists at \(attachmentResource.actualPath)")
            return nil
        }

        do {
            try fm.copyItem(at: fromURL, to: attachmentResource.url!)
        } catch {
            logError("Couldn't copy the attachment to \(attachmentResource.actualPath)")
            return nil
        }
        
        return ResourceFileSys(parent: attachmentsFolder, fileName: attachmentName, type: .attachment)
    }
    
    /// Save a README file into the current collection
    func saveReadMe() -> Bool {
        guard !readmeFile.exists else { return true }
        readmeFile = ResourceFileSys(parent: notesFolder, fileName: ResourceFileSys.readmeFileName, type: .readme)
        var str = "This folder contains a collection of notes created by the Notenik application."
        str.append("\n\n")
        str.append("Learn more at https://Notenik.net")
        str.append("\n")
        return readmeFile.write(str: str)
    }
    
    func saveInfo(str: String) -> Bool {
        infoFile = ResourceFileSys(parent: notesFolder, fileName: ResourceFileSys.infoFileName, type: .info)
        return infoFile.write(str: str)
    }
    
    func saveTemplate(str: String, ext: String) -> Bool {
        if !templateFile.exists {
            templateFile = ResourceFileSys(parent: notesFolder,
                                           fileName: ResourceFileSys.templateFileName + "." + ext,
                                           type: .template,
                                           preferredNoteExt: ext)
        }
        return templateFile.write(str: str)
    }
    
    func changeTemplateExt(to: String) -> Bool {
        guard notesFolder.isAvailable && templateFile.isAvailable else { return false }
        let templateMod = templateFile.changeExt(to: to)
        if templateMod == nil {
            return false
        } else {
            templateFile = templateMod!
            return true
        }
    }
    
    /// Save the indicated Note to disk.
    func saveNote(note: Note) -> Bool {
        guard notesFolder.isAvailable else { return false }
        guard !note.fileInfo.isEmpty else { return false }
        
        let noteResource = ResourceFileSys(parent: notesFolder, fileName: note.fileInfo.baseDotExt!, type: .note)
        return noteResource.writeNote(note)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Probe and Load Routines
    //
    // -----------------------------------------------------------
    
    var pathWithinRealm: String {
        get { return _pwr }
        set {
            _pwr = newValue
            initVariables()
            setPaths()
        }
    }
    var _pwr = ""
    
    /// Set various path values related to the Collection.
    func setPaths() {
        
        // The collection path points to the top folder for the collection.
        let collectionPath = joinPaths(path1: realm.path, path2: pathWithinRealm)
        collection = ResourceFileSys(folderPath: collectionPath, fileName: "")
        
        guard collection.isAvailable else { return }
        
        // The parent path points to the folder just above the collection folder.
        
        let parentURL = collection.url!.deletingLastPathComponent()
        let parentPath = parentURL.path
        parentFolder = ResourceFileSys(folderPath: parentPath, fileName: "", type: .parent)
        
        // The info file identifies this as a Notenik Collection, and stores the
        // preferences that are particular to this Collection.
        
        infoFile = ResourceFileSys(folderPath: collectionPath, fileName: ResourceFileSys.infoFileName)
        
        if !infoFile.exists {
            notesSubFolder = ResourceFileSys(folderPath: collectionPath, fileName: ResourceFileSys.notesFolderName)
            if notesSubFolder.exists && notesSubFolder.isReadable {
                infoFile = ResourceFileSys(folderPath: notesSubFolder.actualPath, fileName: ResourceFileSys.infoFileName)
            }
        }
        
        // Determine which folder actually contains the Notes.
        if notesSubFolder.isAvailable {
            notesFolder = ResourceFileSys(folderPath: notesSubFolder.actualPath, fileName: "")
        } else {
            notesFolder = ResourceFileSys(folderPath: collection.actualPath, fileName: "")
        }
        
        // Set the location for a possible reports folder. 
        reportsFolder = ResourceFileSys(folderPath: notesFolder.actualPath, fileName: ResourceFileSys.reportsFolderName)
        
        // Set the location for a possible attachments folder.
        attachmentsFolder = ResourceFileSys(folderPath:notesFolder.actualPath, fileName: ResourceFileSys.filesFolderName)
        
        // Set the location for a possible mirror folder.
        mirrorFolder = ResourceFileSys(parent: notesFolder, fileName: ResourceFileSys.mirrorFolderName)
        
        // See if we can find a template file.
        templateFile = ResourceFileSys(folderPath: notesFolder.actualPath, fileName: ResourceFileSys.templateFileName + ".txt")
        if !templateFile.isAvailable {
            templateFile = ResourceFileSys(folderPath: notesFolder.actualPath, fileName: ResourceFileSys.templateFileName + ".md")
        }
        
        if !(infoFile.isAvailable && templateFile.isAvailable) {
            scanForResources()
        }
    }
    
    func scanForResources() {
        guard notesFolder.isAvailable else { return }
        let notesContents = notesFolder.getResourceContents(preferredNoteExt: templateExt)
        guard notesContents != nil else { return }
        
        for resource in notesContents! {
            if resource.isDirectory {
                subFoldersFound += 1
                itemsFound += 1
            } else {
                switch resource.type {
                case .display:
                    displayFile = resource
                case .displayCSS:
                    displayCSSFile = resource
                case .info:
                    if !infoFile.isAvailable {
                        infoFile = resource
                    }
                case .noise:
                    break
                case .note:
                    notesFound += 1
                    itemsFound += 1
                case .readme:
                    readmeFile = resource
                case .template:
                    if !templateFile.isAvailable {
                        templateFile = resource
                    }
                default:
                    itemsFound += 1
                }
            }
        }
        readyForUse = true
    }
    
    /// Join two path Strings, ensuring one and only one slash between the two.
    ///
    /// - Parameters:
    ///   - path1: A string containing the beginning of a file path.
    ///   - path2: A string containing a continuation of a file path.
    /// - Returns: A combination of the two.
    func joinPaths(path1: String, path2: String) -> String {
        if path1 == "" || path1 == " " {
            return path2
        }
        if path2 == "" || path2 == " " {
            return path1
        }
        if path2.starts(with: path1) {
            return path2
        }
        var e1 = path1.endIndex
        if path1.hasSuffix("/") {
            e1 = path1.index(path1.startIndex, offsetBy: path1.count - 1)
        }
        let sub1 = path1[..<e1]
        var s2 = path2.startIndex
        if path2.hasPrefix("/") {
            s2 = path2.index(path2.startIndex, offsetBy: 1)
        }
        let sub2 = path2[s2..<path2.endIndex]
        return sub1 + "/" + sub2
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ResourceLibrary",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ResourceLibrary",
                          level: .error,
                          message: msg)
    }
}
