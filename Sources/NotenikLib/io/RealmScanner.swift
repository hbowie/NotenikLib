//
//  RealmScanner.swift
//  Notenik
//
//  Created by Herb Bowie on 5/16/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Scan a folder looking for possible Notenik Collections that might be contained within.
public class RealmScanner {
    
    let fileManager = FileManager.default
    
    public var realmIO: NotenikIO = BunchIO()
    var realmCollection: NoteCollection? = NoteCollection()
    
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
        
        realmIO = BunchIO()
        realmCollection = realmIO.openCollection(realm: realm, collectionPath: "", readOnly: true)
        
        if realmCollection != nil {
            scanFolder(folderPath: path, realm: realm)
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
    func scanFolder(folderPath: String, realm: Realm) {
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: folderPath)
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: folderPath,
                                                       path2: itemPath)
                if itemPath == ResourceFileSys.infoFileName {
                    infoFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                } else if itemPath.hasPrefix(".") {
                    // Ignore invisible files
                } else if itemPath.hasSuffix(".app") {
                    // Ignore application bundles
                } else if itemPath.hasSuffix(".dmg") {
                    // Ignore disk image bundles
                } else if itemPath.hasSuffix(ResourceFileSys.scriptExt) {
                    scriptFileFound(folderPath: folderPath, realm: realm, itemFullPath: itemFullPath)
                } else if FileUtils.isDir(itemFullPath) {
                    if !foldersToSkip.contains(itemPath) {
                        scanFolder(folderPath: itemFullPath, realm: realm)
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
            let infoCollection = infoIO.collection
            if infoCollection != nil {
                let realmNote = Note(collection: realmIO.collection!)
                let titleOK = realmNote.setTitle(infoIO.collection!.title)
                if !titleOK {
                    logError("Unable to find a Title for Collection located at \(folderPath)")
                }
                var link = folderURL.absoluteString
                if folderURL.lastPathComponent == ResourceFileSys.notesFolderName {
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
                let (addedNote, _) = realmIO.addNote(newNote: realmNote)
                if addedNote == nil {
                    logError("Unable to record the Collection located at \(folderPath)")
                }
            } else {
                logError("Unable to initialize Collection located at \(folderPath)")
            }
        } else {
            logError("Unable to initialize Collection located at \(folderPath)")
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
        var title = ""
        while folderIndex < scriptFileName.folders.count {
            title.append(String(scriptFileName.folders[folderIndex]))
            title.append(" ")
            folderIndex += 1
        }
        title.append(scriptFileName.fileName)
        let titleOK = scriptNote.setTitle(title)
        if !titleOK {
            print("Title could not be set to \(title)")
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
        let (addedNote, _) = realmIO.addNote(newNote: scriptNote)
        if addedNote == nil {
            print("Note titled \(scriptNote.title.value) could not be added")
        }
        if titleOK && linkOK && tagsOK && (addedNote != nil) { return }
        logError("Couldn't record script file at \(itemFullPath)")
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "RealmScanner",
                          level: .error,
                          message: msg)
    }
}
