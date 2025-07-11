//
//  ResourceLibrary.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/27/21.
//
//  Copyright © 2021-2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A repository from which to obtain the various resources that might be found
/// within a particular Notenik Collection.
public class ResourceLibrary: Equatable {
    
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
    var infoParentFile    = ResourceFileSys()
    var templateFile      = ResourceFileSys()
    var displayFile       = ResourceFileSys()
    var displayCSSFile    = ResourceFileSys()
    var aliasFile         = ResourceFileSys()
    var attachmentsFolder = ResourceFileSys()
    var mirrorFolder      = ResourceFileSys()
    var notenikFiles      = ResourceFileSys()
    var notenikFilesSubfolder = ResourceFileSys()
    var reportsFolder     = ResourceFileSys()
    var klassFolder       = ResourceFileSys()
    var exportFolder      = ResourceFileSys()
    var cssFolder         = ResourceFileSys()
    var shareTemplatesFolder = ResourceFileSys()
    var addinsFolder      = ResourceFileSys()
    
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
        infoParentFile  = ResourceFileSys()
        templateFile    = ResourceFileSys()
        displayFile     = ResourceFileSys()
        displayCSSFile  = ResourceFileSys()
        aliasFile       = ResourceFileSys()
        attachmentsFolder = ResourceFileSys()
        mirrorFolder    = ResourceFileSys()
        notenikFiles    = ResourceFileSys()
        notenikFilesSubfolder = ResourceFileSys()
        reportsFolder   = ResourceFileSys()
        klassFolder     = ResourceFileSys()
        exportFolder    = ResourceFileSys()
        cssFolder       = ResourceFileSys()
        shareTemplatesFolder = ResourceFileSys()
        addinsFolder    = ResourceFileSys()
        
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
    
    public func initResource(type: ResourceType, ext: String = "txt") {
        switch type {
        case .alias:
            aliasFile = ResourceFileSys(parent: notenikFiles, fileName: NotenikConstants.aliasFileName, type: .alias)
        case .info:
            infoFile = ResourceFileSys(parent: notenikFiles, fileName: NotenikConstants.infoFileName, type: .info)
        case .notenikFilesSubfolder:
            notenikFilesSubfolder = ResourceFileSys(parent: collection,
                                                    fileName: NotenikConstants.notenikFiles,
                                                    type: .notenikFilesSubfolder)
        case .template:
            templateFile = ResourceFileSys(parent: notenikFiles,
                                           fileName: NotenikConstants.templateFileName + "." + ext,
                                           type: .template,
                                           preferredNoteExt: ext)
        default:
            break
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Accessors for various sorts of Collection Resources
    //
    // -----------------------------------------------------------
    
    public func checkStatus(type: ResourceType) {
        switch type {
        case .addinsFolder:
            addinsFolder.checkStatus()
        case .cssFolder:
            cssFolder.checkStatus()
        case .shareTemplatesFolder:
            shareTemplatesFolder.checkStatus()
        default:
            return
        }
    }
    
    public func hasAvailable(type: ResourceType) -> Bool {
        switch type {
        case .addinsFolder:
            return addinsFolder.isAvailable
        case .alias:
            return aliasFile.isAvailable
        case .attachments:
            return attachmentsFolder.isAvailable
        case .collection:
            return collection.isAvailable
        case .cssFolder:
            return cssFolder.isAvailable
        case .display:
            return displayFile.isAvailable
        case .displayCSS:
            return displayCSSFile.isAvailable
        case .exportFolder:
            return exportFolder.isAvailable
        case .info:
            return infoFile.isAvailable
        case .infoParent:
            return infoParentFile.isAvailable
        case .klassFolder:
            return klassFolder.isAvailable
        case .mirror:
            return mirrorFolder.isAvailable
        case .notenikFiles:
            return notenikFiles.isAvailable
        case .notenikFilesSubfolder:
            return notenikFilesSubfolder.isAvailable
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
        case .shareTemplatesFolder:
            return shareTemplatesFolder.isAvailable
        case .template:
            return templateFile.isAvailable
        default:
            return false
        }
    }
    
    public func getPath(type: ResourceType) -> String {
        switch type {
        case .addinsFolder:
            return addinsFolder.actualPath
        case .alias:
            return aliasFile.actualPath
        case .attachments:
            return attachmentsFolder.actualPath
        case .collection:
            return collection.actualPath
        case .cssFolder:
            return cssFolder.actualPath
        case .display:
            return displayFile.actualPath
        case .displayCSS:
            return displayCSSFile.actualPath
        case .exportFolder:
            return exportFolder.actualPath
        case .info:
            return infoFile.actualPath
        case .infoParent:
            return infoParentFile.actualPath
        case .klassFolder:
            return klassFolder.actualPath
        case .mirror:
            return mirrorFolder.actualPath
        case .notenikFiles:
            return notenikFiles.actualPath
        case .notenikFilesSubfolder:
            return notenikFilesSubfolder.actualPath
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
        case .shareTemplatesFolder:
            return shareTemplatesFolder.actualPath
        case .template:
            return templateFile.actualPath
        default:
            return ""
        }
    }
    
    public func getURL(type: ResourceType) -> URL? {
        switch type {
        case .addinsFolder:
            return addinsFolder.url
        case .alias:
            return aliasFile.url
        case .attachments:
            return attachmentsFolder.url
        case .collection:
            return collection.url
        case .cssFolder:
            return cssFolder.url
        case .display:
            return displayFile.url
        case .displayCSS:
            return displayCSSFile.url
        case .exportFolder:
            return exportFolder.url
        case .info:
            return infoFile.url
        case .infoParent:
            return infoParentFile.url
        case .klassFolder:
            return klassFolder.url
        case .mirror:
            return mirrorFolder.url
        case .notenikFiles:
            return notenikFiles.url
        case .notenikFilesSubfolder:
            return notenikFilesSubfolder.url
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
        case .shareTemplatesFolder:
            return shareTemplatesFolder.url
        case .template:
            return templateFile.url
        default:
            return nil
        }
    }
    
    public func getResource(type: ResourceType) -> ResourceFileSys {
        switch type {
        case .addinsFolder:
            return addinsFolder
        case .alias:
            return aliasFile
        case .attachments:
            return attachmentsFolder
        case .collection:
            return collection
        case .cssFolder:
            return cssFolder
        case .display:
            return displayFile
        case .displayCSS:
            return displayCSSFile
        case .exportFolder:
            return exportFolder
        case .info:
            return infoFile
        case .infoParent:
            return infoParentFile
        case .klassFolder:
            return klassFolder
        case .mirror:
            return mirrorFolder
        case .notenikFiles:
            return notenikFiles
        case .notenikFilesSubfolder:
            return notenikFilesSubfolder
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
        case .shareTemplatesFolder:
            return shareTemplatesFolder
        case .template:
            return templateFile
        default:
            return ResourceFileSys()
        }
    }
    
    public func ensureResource(type: ResourceType) -> ResourceFileSys {
        switch type {
        case .addinsFolder:
            if addinsFolder.isAvailable {
                return addinsFolder
            }
            addinsFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.addinsFolderName, type: .addinsFolder)
            _ = addinsFolder.ensureExistence()
            return addinsFolder
        case .attachments:
            if attachmentsFolder.isAvailable {
                return attachmentsFolder
            }
            attachmentsFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.filesFolderName, type: .attachments)
            _ = attachmentsFolder.ensureExistence()
            return attachmentsFolder
        case .cssFolder:
            if cssFolder.isAvailable {
                return cssFolder
            }
            cssFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.cssFolderName, type: .cssFolder)
            _ = cssFolder.ensureExistence()
            return cssFolder
        case .klassFolder:
            if klassFolder.isAvailable {
                return klassFolder
            }
            klassFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.klassFolderName, type: .klassFolder)
            _ = klassFolder.ensureExistence()
            return klassFolder
        case .mirror:
            if mirrorFolder.isAvailable {
                return mirrorFolder
            }
            mirrorFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.mirrorFolderName, type: .mirror)
            _ = mirrorFolder.ensureExistence()
            return mirrorFolder
        case .notenikFilesSubfolder:
            if notenikFilesSubfolder.isAvailable {
                return notenikFilesSubfolder
            }
            notenikFilesSubfolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.notenikFiles, type: .notenikFilesSubfolder)
            _ = notenikFilesSubfolder.ensureExistence()
            notenikFiles = ResourceFileSys(parent: collection, fileName: NotenikConstants.notenikFiles, type: .notenikFiles)
            return notenikFilesSubfolder
        case .shareTemplatesFolder:
            if shareTemplatesFolder.isAvailable {
                return shareTemplatesFolder
            }
            shareTemplatesFolder = ResourceFileSys(parent: notesFolder,
                                                   fileName: NotenikConstants.shareTemplatesFolderName,
                                                   type: .shareTemplatesFolder)
            _ = shareTemplatesFolder.ensureExistence()
            return shareTemplatesFolder
        default:
            return ResourceFileSys()
        }
    }
    
    /// Attempt to create a Resource for the given Note.
    func getNoteResource(note: Note) -> ResourceFileSys? {
        guard notesFolder.isAvailable else {
            logError("No notes folder available")
            return nil
        }
        guard let fileName = note.noteID.getBaseDotExt() else { return nil }
        return ResourceFileSys(parent: notesFolder, fileName: fileName, type: .note)
    }
    
    func getAttachmentResource(fileName: String) -> ResourceFileSys? {
        guard attachmentsFolder.isAvailable else { return nil }
        return ResourceFileSys(parent: attachmentsFolder, fileName: fileName, type: .attachment)
    }
    
    func getContents(type: ResourceType) -> [ResourceFileSys]? {
        switch type {
        case .addinsFolder:
            return addinsFolder.getResourceContents()
        case .attachments:
            return attachmentsFolder.getResourceContents()
        case .cssFolder:
            return cssFolder.getResourceContents()
        case .exportFolder:
            return exportFolder.getResourceContents()
        case .klassFolder:
            return klassFolder.getResourceContents()
        case .mirror:
            return mirrorFolder.getResourceContents()
        case .notenikFiles:
            return notenikFiles.getResourceContents()
        case .notenikFilesSubfolder:
            return notenikFilesSubfolder.getResourceContents()
        case .notes:
            return notesFolder.getResourceContents()
        case .parent:
            return parentFolder.getResourceContents()
        case .reports:
            return reportsFolder.getResourceContents()
        case .shareTemplatesFolder:
            return shareTemplatesFolder.getResourceContents()
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
        case .infoParent:
            guard infoParentFile.isAvailable else { return nil }
            let infoCollection = NoteCollection(realm: realm)
            infoCollection.path = notesFolder.actualPath
            return infoParentFile.readNote(collection: infoCollection)
        default:
            return nil
        }
    }
    
    func getNote(type: ResourceType, collection: NoteCollection) -> Note? {
        
        switch type {
        case .info:
            return getNote(type: type)
        case .infoParent:
            return getNote(type: type)
        case .template:
            guard templateFile.isAvailable else { return nil }
            return templateFile.readNote(collection: collection, template: true)
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
        case .info, .infoParent:
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
    
    /// Copyor move  a new attachment and store it in the attachment (aka files) subfolder.
    func storeAttachment(fromURL: URL, attachmentName: String, move: Bool) -> ResourceFileSys? {
        
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
        
        if move {
            do {
                try fm.moveItem(at: fromURL, to: attachmentResource.url!)
            } catch {
                logError("Couldn't move the attachment to \(attachmentResource.actualPath)")
                return nil
            }
        } else {
            do {
                try fm.copyItem(at: fromURL, to: attachmentResource.url!)
            } catch {
                logError("Couldn't copy the attachment to \(attachmentResource.actualPath)")
                return nil
            }
        }
        
        return ResourceFileSys(parent: attachmentsFolder, fileName: attachmentName, type: .attachment)
    }
    
    /// Save a README file into the current collection
    func saveReadMe() -> Bool {
        guard !readmeFile.exists else { return true }
        readmeFile = ResourceFileSys(parent: notenikFiles, fileName: NotenikConstants.readmeFileName, type: .readme)
        var str = "This folder contains files created by the Notenik application."
        str.append("\n\n")
        str.append("Learn more at https://Notenik.app")
        str.append("\n")
        return readmeFile.write(str: str)
    }
    
    func saveInfo(str: String) -> Bool {
        initResource(type: .info)
        return infoFile.write(str: str)
    }
    
    func saveInfoParent(str: String) -> Bool {
        infoParentFile = ResourceFileSys(parent: collection, fileName: NotenikConstants.infoProjectFileName, type: .infoParent)
        // infoParentFile = ResourceFileSys(parent: collection, fileName: NotenikConstants.infoParentFileName, type: .infoParent)
        let ok = infoParentFile.write(str: str)
        if ok {
            let oldInfoFile = ResourceFileSys(parent: collection, fileName: NotenikConstants.infoParentFileName, type: .infoParent)
            if oldInfoFile.isAvailable {
                _ = oldInfoFile.remove()
            }
        }
        return ok
        
    }
    
    func saveTemplate(str: String, ext: String) -> Bool {
        if !templateFile.exists {
            initResource(type: .template, ext: ext)
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
        guard !note.noteID.isEmpty else { return false }
        
        if note.hasFolder() {
            return saveSubNote(note: note)
        }
        
        let noteResource = ResourceFileSys(parent: notesFolder, fileName: note.noteID.getBaseDotExtForWrite()!, type: .note)
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
    public func setPaths() {
        
        // The collection path points to the top folder for the collection.
        let collectionPath = joinPaths(path1: realm.path, path2: pathWithinRealm)
        collection = ResourceFileSys(folderPath: collectionPath, fileName: "")
        
        guard collection.isAvailable else { return }
        
        // The parent path points to the folder just above the collection folder.
        let parentURL = collection.url!.deletingLastPathComponent()
        let parentPath = parentURL.path
        parentFolder = ResourceFileSys(folderPath: parentPath, fileName: "", type: .parent)
        
        // Create pointers to other potential files and folders.
        notesSubFolder = ResourceFileSys(folderPath: collectionPath, fileName: NotenikConstants.notesFolderName, type: .notesSubfolder)
        infoParentFile = ResourceFileSys(folderPath: parentPath, fileName: NotenikConstants.infoParentFileName)
        
        // Determine which folder actually contains the Notes.
        if notesSubFolder.isAvailable && !notesSubFolder.isEmpty() {
            notesFolder = ResourceFileSys(folderPath: notesSubFolder.actualPath, fileName: "", type: .notes)
        } else {
            notesFolder = ResourceFileSys(folderPath: collection.actualPath, fileName: "", type: .notes)
        }
        notenikFilesSubfolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.notenikFiles, type: .notenikFilesSubfolder)
        
        // See if Notenik special files are being stashed in a subfolder.
        notenikFiles = ResourceFileSys(parent: notesFolder, fileName: "", type: .notenikFiles)
        if notenikFilesSubfolder.isAvailable {
            notenikFiles = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.notenikFiles, type: .notenikFiles)
        }
        
        // The info file identifies this as a Notenik Collection, and stores the
        // preferences that are particular to this Collection.
        
        infoFile = ResourceFileSys(folderPath: collectionPath, fileName: NotenikConstants.infoFileName)
        
        if !infoFile.exists {
            if notenikFilesSubfolder.isAvailable {
                initResource(type: .info)
            } else {
                if notesSubFolder.isAvailable {
                    infoFile = ResourceFileSys(folderPath: notesSubFolder.actualPath, fileName: NotenikConstants.infoFileName)
                }
            }
        }
        
        // Set the location for a possible reports folder. 
        reportsFolder = ResourceFileSys(folderPath: notesFolder.actualPath, fileName: NotenikConstants.reportsFolderName, type: .reports)
        
        // Set the location for a possible export folder.
        exportFolder = ResourceFileSys(folderPath: notesFolder.actualPath, fileName: NotenikConstants.exportFolderName, type: .exportFolder)
        
        // Set the location for a possible attachments folder.
        attachmentsFolder = ResourceFileSys(folderPath:notesFolder.actualPath, fileName: NotenikConstants.filesFolderName, type: .attachments)
        
        // Set the location for a possible mirror folder.
        mirrorFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.mirrorFolderName, type: .mirror)
        
        // Set the location for a possible alias file.
        initResource(type: .alias)
        
        // Set the location for a possible class folder.
        klassFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.klassFolderName, type: .klassFolder)
        
        // Set the location for a possible css folder.
        cssFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.cssFolderName, type: .cssFolder)
        
        // Set the location for a possible share folder
        shareTemplatesFolder = ResourceFileSys(parent: notesFolder,
                                               fileName: NotenikConstants.shareTemplatesFolderName,
                                               type: .shareTemplatesFolder)
        
        // Set the location for a possible add-ins folder.
        addinsFolder = ResourceFileSys(parent: notesFolder, fileName: NotenikConstants.addinsFolderName, type: .addinsFolder)
        
        // See if we can find a template file.
        templateFile = ResourceFileSys(parent: notenikFiles, fileName: NotenikConstants.templateFileName + ".txt")
        if !templateFile.isAvailable {
            templateFile = ResourceFileSys(parent: notenikFiles, fileName: NotenikConstants.templateFileName + ".md")
        }
        
        if !(infoFile.isAvailable && templateFile.isAvailable) {
            scanForResources()
        }
    }
    
    func scanForResources() {
        
        if notenikFiles.isAvailable {
            scanForResources(folder: notenikFiles)
        }
        scanForResources(folder: notesFolder)
        readyForUse = true
    }
    
    func scanForResources(folder: ResourceFileSys) {
        guard folder.isAvailable else { return }
        let folderContents = folder.getResourceContents(preferredNoteExt: templateExt)
        guard folderContents != nil else { return }
        
        for resource in folderContents! {
            if resource.isDirectory {
                subFoldersFound += 1
                itemsFound += 1
            } else {
                switch resource.type {
                case .alias:
                    aliasFile = resource
                case .display:
                    displayFile = resource
                case .displayCSS:
                    displayCSSFile = resource
                case .info:
                    if !infoFile.isAvailable {
                        infoFile = resource
                    }
                case .infoParent:
                    if !infoParentFile.isAvailable {
                        infoParentFile = resource
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
    
    // -----------------------------------------------------------
    //
    // MARK: Manage Subfolders
    //
    // -----------------------------------------------------------
    
    var subLibs: [String: ResourceLibrary] = [:]
    
    public func getSubLib(folderName: String) -> ResourceLibrary? {
        return subLibs[folderName]
    }
    
    /// If this sub-folder doesn't already exist, then try to create it.
    /// - Parameter note: A note that might be stored in a sub-folder.
    public func checkForFolder(note: Note) {
        guard note.hasFolder() else { return }
        let folderName = note.folder.value
        var subLib: ResourceLibrary? = subLibs[folderName]
        guard subLib == nil else { return }
        subLib = newSubLib(note: note)
        guard subLib != nil else { return }
        addSubLib(folderName: folderName, subLib: subLib!)
    }
    
    /// Add a sub-library to our internal list.
    /// - Parameters:
    ///   - folderName: The name of the folder.
    ///   - subLib: The Resource library defined for the folder.
    public func addSubLib(folderName: String, subLib: ResourceLibrary) {
        subLibs[folderName] = subLib
    }
    
    /// Save a Note in a sub-folder, creating a new sub-folder if needed.
    /// - Parameter note: The note to be saved.
    /// - Returns: True if saved successfully; false otherwise.
    public func saveSubNote(note: Note) -> Bool {
        
        // First of all, obtain a sub-library.
        var subLib: ResourceLibrary? = subLibs[note.folder.value]
        if subLib == nil {
            subLib = newSubLib(note: note)
        }
        guard subLib != nil else { return false }
        
        let noteResource = ResourceFileSys(parent: subLib!.notesFolder, fileName: note.noteID.getBaseDotExt()!, type: .note)
        return noteResource.writeNote(note)
    }
    
    /// Create a new sub-folder, including the folder on disk and the Resource library.
    /// - Parameter note: The note for which we need a new sub-folder.
    /// - Returns: The new resource library, if successful 
    public func newSubLib(note: Note) -> ResourceLibrary? {
        
        let folder = note.folder.value
        let collection = note.collection
        
        let resource = ResourceFileSys(parent: notesFolder, fileName: folder, type: .collection)
        guard resource.ensureExistence() else {
            logError("Sub-folder could not be created for notes folder of '\(notesFolder)' and folder name of '\(folder)'")
            return nil
        }
        let subLib = ResourceLibrary()
        let subPath = joinPaths(path1: notesFolder.normalPath, path2: folder)
        subLib.pathWithinRealm = subPath
        subLib.prepareForUse()
        _ = subLib.saveReadMe()
        
        let templateMaker = TemplateLineMaker()
        templateMaker.putTemplate(collection: collection, subFolder: true)
        _ =  subLib.saveTemplate(str: templateMaker.str, ext: collection.preferredExt)
        
        let infoMaker = InfoLineMaker()
        infoMaker.putInfo(collection: collection, bunch: nil, subFolder: true, folderName: folder)
        _ = subLib.saveInfo(str: infoMaker.str)
        
        return subLib
    }
    
    
    // -----------------------------------------------------------
    //
    // MARK: Utility Routines
    //
    // -----------------------------------------------------------
    
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
    
    public static func == (lhs: ResourceLibrary, rhs: ResourceLibrary) -> Bool {
        return lhs.collection == rhs.collection
    }
    
    public func display() {
        print("ResourceLibrary.display")
        parentFolder.displayShort()
        collection.displayShort()
        notesFolder.displayShort()
        notesSubFolder.displayShort()
        notenikFiles.displayShort()
        infoFile.displayShort()
    }
}
