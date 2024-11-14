//
//  RealmScanner.swift
//  Notenik
//
//  Created by Herb Bowie on 5/16/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Scan a folder looking for possible Notenik Collections and associateed resourcesthat might be contained within.
public class RealmScanner {
    
    let fileManager = FileManager.default
    
    public var realmIO: NotenikIO = BunchIO()
    var realmCollection: NoteCollection? = NoteCollection()
    var realmURL: URL?
    
    let foldersToSkip = Set(["cgi-bin", "core", "css", "downloads", "files", "fonts", "images", "includes", "javascript", "js", "lib", "modules", "themes", "wp-admin", "wp-content", "wp-includes"])
    
    var collectionPath = ""
    var collectionTag  = ""
    
    public init() {
        
    }
    
    /// Open a realm, looking for its collections
    public func openRealm(path: String) -> Bool {
        var ok = true
        let provider = Provider()
        let realm = Realm(provider: provider)
        realm.path = path
        realm.name = path
        realmURL = URL(fileURLWithPath: path, isDirectory: true)
        
        realmIO = BunchIO()
        realmCollection = realmIO.openCollection(realm: realm, collectionPath: "", readOnly: true, multiRequests: nil)
        
        if realmCollection != nil {
            scanFolder(folderPath: path, realm: realm, depth: 0)
            realmCollection!.readOnly = true
            realmCollection!.isRealmCollection = true
        } else {
            logError("Unable to open the realm collection for \(path)")
            ok = false
        }
        
        if realmCollection == nil || realmIO.notesCount == 0 {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "RealmIO",
                              level: .info,
                              message: "No Notenik Collections found within \(path)")
            ok = false
        }
        return ok
    }
    
    /// Scan folders recursively looking for signs that they are Notenik Collections
    func scanFolder(folderPath: String, realm: Realm, depth: Int) {
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: folderPath)
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: folderPath,
                                                       path2: itemPath)
                if itemPath == NotenikConstants.infoFileName {
                    infoFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                } else if itemPath == NotenikConstants.infoParentFileName {
                    infoParentFileFound(folderPath: folderPath, realm: realm, itemPath: itemPath)
                } else if itemPath.hasPrefix(".") {
                    // Ignore invisible files
                } else if itemPath.hasSuffix(".app") {
                    // Ignore application bundles
                } else if itemPath.hasSuffix(".dmg") {
                    // Ignore disk image bundles
                } else if itemPath.hasSuffix(ResourceFileSys.scriptExt) {
                    scriptFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                } else if itemPath.hasSuffix(".bbprojectd") {
                    bbEditProjectFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                } else if itemPath.hasSuffix(".webloc") {
                    webLocationFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                } else if depth == 0 && (itemPath.hasSuffix((".txt"))
                            || itemPath.hasSuffix(".md")
                            || itemPath.hasSuffix(".text")
                            || itemPath.hasSuffix(".mdtext")
                            || itemPath.hasSuffix(".mkdown")) {
                    textFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                } else if FileUtils.isDir(itemFullPath) {
                    if itemPath == NotenikConstants.notenikFiles {
                        infoFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                    } else if !foldersToSkip.contains(itemPath) {
                        scanFolder(folderPath: itemFullPath, realm: realm, depth: depth + 1)
                    }
                }
            }
        } catch {
            logError("Failed reading contents of folder at '\(folderPath)'")
        }
    }
    
    /// Add the Info file's collection to the collection of collections.
    func infoFileFound(folderPath: String, realm: Realm, itemFullPath: String) {
        let folderURL = URL(fileURLWithPath: folderPath)
        let infoIO = FileIO()
        let initOK = infoIO.initCollection(realm: realm, collectionPath: folderPath, readOnly: true)
        if initOK {
            _ = infoIO.loadInfoFile()
            let infoCollection = infoIO.collection
            if infoCollection != nil {
                let realmNote = Note(collection: realmIO.collection!)
                let titleOK = realmNote.setTitle(infoCollection!.userFacingLabel(below: realmURL))
                // (folderURL.lastPathComponent)
                // let titleOK = realmNote.setTitle(infoIO.collection!.title)
                if !titleOK {
                    logError("Unable to find a Title for Collection located at \(folderPath)")
                }
                var link = folderURL.absoluteString
                if folderURL.lastPathComponent == NotenikConstants.notesFolderName {
                    link = folderURL.deletingLastPathComponent().absoluteString
                }
                let linkOK = realmNote.setLink(link)
                if !linkOK {
                    logError("Unable to record a Link for Collection located at \(folderPath)")
                }
                collectionPath = folderPath
                collectionTag = TagsValue.tagify(realmNote.title.value)
                let tagsOK = realmNote.setTags("Collections, " + collectionTag)
                if !tagsOK {
                    logError("Unable to add a tag to Collection located at \(folderPath)")
                }
                realmNote.identify()
                let (addedNote, _) = realmIO.addNote(newNote: realmNote)
                if addedNote == nil {
                    logError("Unable to record the Collection located at \(folderPath)")
                }
                
                _ = infoIO.loadInfoFile()
                let folderLink = NotenikLink(url: folderURL, isCollection: true)
                folderLink.shortcut = infoCollection!.shortcut
                MultiFileIO.shared.register(link: folderLink)
            } else {
                logError("Unable to initialize Collection located at \(folderPath)")
            }
        } else {
            logError("Unable to initialize Collection located at \(folderPath)")
        }
    }
    
    /// Collect info about the parent realm from its info file.
    func infoParentFileFound(folderPath: String, realm: Realm, itemPath: String) {
        guard realmCollection != nil else { return }
        guard realmCollection!.windowPosStr.isEmpty else { return }
        let infoCollection = NoteCollection(realm: realm)
        infoCollection.path = folderPath
        let infoParentFile = ResourceFileSys(folderPath: folderPath, fileName: itemPath)
        guard let infoNote = infoParentFile.readNote(collection: infoCollection) else { return }
        let windowNumbers = infoNote.getField(label: NotenikConstants.windowNumbersCommon)
        if windowNumbers != nil && !windowNumbers!.value.isEmpty {
            realmCollection!.windowPosStr = windowNumbers!.value.value
        }
    }
    
    /// Add the script file to the Realm Collection. 
    func scriptFileFound(folderPath: String, realm: Realm, itemFullPath: String) {
        let scriptURL = URL(fileURLWithPath: itemFullPath)
        let scriptNote = Note(collection: realmCollection!)
        let scriptFileName = FileName(itemFullPath)
        var folderIndex = scriptFileName.folders.count - 1
        if scriptFileName.folders[folderIndex] == "reports" || scriptFileName.folders[folderIndex] == "scripts" {
            folderIndex -= 1
        }
        // var title = ""
        /* while folderIndex < scriptFileName.folders.count {
            title.append(String(scriptFileName.folders[folderIndex]))
            title.append(" ")
            folderIndex += 1
        } */
        let scriptTitle = AppPrefs.shared.idFolderFrom(url: scriptURL, below: realmURL)
        // title.append(scriptFileName.fileName)
        let titleOK = scriptNote.setTitle(scriptTitle)
        if !titleOK {
            print("Title could not be set to \(scriptTitle)")
        }
        let linkOK = scriptNote.setLink(scriptURL.absoluteString)
        if !linkOK {
            print("Link could not be set to \(scriptURL.absoluteString)")
        }
        var tags = "Scripts"
        if itemFullPath.hasPrefix(collectionPath) {
            tags.append(", ")
            tags.append(collectionTag)
            tags.append(".scripts")
        } else {
            tags.append(", ")
            tags.append(TagsValue.tagify(scriptFileName.folder))
        }
        let tagsOK = scriptNote.setTags(tags)
        if !tagsOK {
            print("Tags could not be set to \(tags)")
        }
        scriptNote.identify()
        let (addedNote, _) = realmIO.addNote(newNote: scriptNote)
        if addedNote == nil {
            print("Note titled \(scriptNote.title.value) could not be added")
        }
        if titleOK && linkOK && tagsOK && (addedNote != nil) { return }
        logError("Couldn't record script file at \(itemFullPath)")
    }
    
    /// Add the BBEdit Project  file to the Realm Collection.
    func bbEditProjectFileFound(folderPath: String, realm: Realm, itemFullPath: String) {
        let bbURL = URL(fileURLWithPath: itemFullPath)
        let bbNote = Note(collection: realmCollection!)
        let bbFileName = FileName(itemFullPath)
        var folderIndex = bbFileName.folders.count - 1
        if bbFileName.folders[folderIndex] == "reports" || bbFileName.folders[folderIndex] == "scripts" {
            folderIndex -= 1
        }
        // var title = ""
        let title = AppPrefs.shared.idFolderFrom(url: bbURL, below: realmURL)
        let titleOK = bbNote.setTitle(title)
        if !titleOK {
            print("BBEdit Note Title could not be set to \(title)")
        }
        let linkOK = bbNote.setLink(bbURL.absoluteString)
        if !linkOK {
            print("BBEdit Link could not be set to \(bbURL.absoluteString)")
        }
        var tags = "BBEdit Projects"
        if itemFullPath.hasPrefix(collectionPath) {
            tags.append(", ")
            tags.append(collectionTag)
            tags.append(".scripts")
        } else {
            tags.append(", ")
            tags.append(TagsValue.tagify(bbFileName.folder))
        }
        let tagsOK = bbNote.setTags(tags)
        if !tagsOK {
            print("BBEdit Note Tags could not be set to \(tags)")
        }
        bbNote.identify()
        let (addedNote, _) = realmIO.addNote(newNote: bbNote)
        if addedNote == nil {
            print("BBEdit Note titled \(bbNote.title.value) could not be added")
        }
        if titleOK && linkOK && tagsOK && (addedNote != nil) { return }
        logError("Couldn't record BBEdit Project file at \(itemFullPath)")
    }
    
    /// Add the Web Location  file to the Realm Collection.
    func webLocationFileFound(folderPath: String, realm: Realm, itemFullPath: String) {
        let fileURL = URL(fileURLWithPath: itemFullPath)
        let fileNote = Note(collection: realmCollection!)
        let fileName = FileName(itemFullPath)
        // var folderIndex = fileName.folders.count - 1
        // if fileName.folders[folderIndex] == "reports" || fileName.folders[folderIndex] == "scripts" {
         //   folderIndex -= 1
        // }
        let title = AppPrefs.shared.idFolderFrom(url: fileURL, below: realmURL)
        let titleOK = fileNote.setTitle(title)
        if !titleOK {
            print("Special File Note Title could not be set to \(title)")
        }
        let linkOK = fileNote.setLink(fileURL.absoluteString)
        if !linkOK {
            print("Special File Link could not be set to \(fileURL.absoluteString)")
        }
        var tags = "Web Locations"
        if itemFullPath.hasPrefix(collectionPath) {
            tags.append(", ")
            tags.append(collectionTag)
            tags.append(".scripts")
        } else {
            tags.append(", ")
            tags.append(TagsValue.tagify(fileName.folder))
        }
        let tagsOK = fileNote.setTags(tags)
        if !tagsOK {
            print("Special File Note Tags could not be set to \(tags)")
        }
        fileNote.identify()
        let (addedNote, _) = realmIO.addNote(newNote: fileNote)
        if addedNote == nil {
            print("Special File Note titled \(fileNote.title.value) could not be added")
        }
        if titleOK && linkOK && tagsOK && (addedNote != nil) { return }
        logError("Couldn't record Special File Project file at \(itemFullPath)")
    }
    
    /// Add the BBEdit Project  file to the Realm Collection.
    func textFileFound(folderPath: String, realm: Realm, itemFullPath: String) {
        let tfURL = URL(fileURLWithPath: itemFullPath)
        let tfNote = Note(collection: realmCollection!)
        let tfFileName = FileName(itemFullPath)
        /* var folderIndex = tfFileName.folders.count - 1
        if tfFileName.folders[folderIndex] == "reports" || tfFileName.folders[folderIndex] == "scripts" {
            folderIndex -= 1
        } */
        // var title = ""
        let title = AppPrefs.shared.idFolderFrom(url: tfURL, below: realmURL)
        let titleOK = tfNote.setTitle(title)
        if !titleOK {
            print("Text File Note Title could not be set to \(title)")
        }
        let linkOK = tfNote.setLink(tfURL.absoluteString)
        if !linkOK {
            print("Text File Link could not be set to \(tfURL.absoluteString)")
        }
        var tags = "Text Files"
        let tagsOK = tfNote.setTags(tags)
        if !tagsOK {
            print("Text File Note Tags could not be set to \(tags)")
        }
        tfNote.identify()
        let (addedNote, _) = realmIO.addNote(newNote: tfNote)
        if addedNote == nil {
            print("Text File Note titled \(tfNote.title.value) could not be added")
        }
        if titleOK && linkOK && tagsOK && (addedNote != nil) { return }
        logError("Couldn't record Text File Project file at \(itemFullPath)")
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "RealmScanner",
                          level: .error,
                          message: msg)
    }
    
    public static func saveInfoFile(collection: NoteCollection) -> Bool {
        guard collection.isRealmCollection else { return false }
        guard let lib = collection.lib else { return false }
        let str = NoteString(title: collection.title)
        if !collection.windowPosStr.isEmpty {
            str.append(label: NotenikConstants.windowNumbers, value: collection.windowPosStr)
        }
        let saveOK = lib.saveInfoParent(str: str.str)
        return saveOK
    }
}
