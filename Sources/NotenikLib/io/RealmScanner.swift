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
    
    var readmeNote: Note?
    
    public init() {
        
    }
    
    /// Open a realm, looking for its collections
    public func openRealm(path: String) -> Bool {
        readmeNote = nil
        var ok = true
        let provider = Provider()
        let realm = Realm(provider: provider)
        realm.path = path
        realm.name = path
        realmURL = URL(fileURLWithPath: path, isDirectory: true)
        
        realmIO = BunchIO()
        realmCollection = realmIO.openCollection(realm: realm, collectionPath: "", readOnly: true, multiRequests: nil)
        
        if realmCollection != nil {
            if AppPrefs.shared.openInNova {
                let novaPath = "nova://open?path=\(path)"
                addNote(itemFullPath: novaPath,
                        category: "text editors",
                        title: "Open in Nova",
                        filePath: false,
                        setBody: false,
                        readmeCandidate: false)
            }
            
            addNote(itemFullPath: "file://" + path,
                    category: "finder",
                    title: "Open in Finder",
                    filePath: false,
                    setBody: false,
                    readmeCandidate: false)
                    
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
        
        var positioned = false
        if ok {
            if let readme = readmeNote {
                if let io = realmIO as? BunchIO {
                    _ = io.selectNote(note: readme)
                    positioned = true
                }
            }
        }
        if !positioned {
            _ = realmIO.firstNote()
        }
        return ok
    }
    
    /// Scan folders recursively looking for signs that they are Notenik Collections
    func scanFolder(folderPath: String, realm: Realm, depth: Int, folderName: String = "") {
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: folderPath)
            for itemPath in dirContents {
                let fileInfo = NotenikFileInfo(path1: folderPath, path2: itemPath)
                if fileInfo.isInfoFile {
                    infoFileFound(folderPath: folderPath, realm: realm, itemFullPath: fileInfo.filePath)
                } else if fileInfo.isInfoParent {
                    infoParentFileFound(folderPath: folderPath, realm: realm, itemPath: itemPath)
                } else if fileInfo.isHidden {
                    // Ignore invisible files
                } else if fileInfo.isAppBundle {
                    // Ignore application bundles
                } else if fileInfo.isDiskImage {
                    // Ignore disk image bundles
                } else if fileInfo.isScript {
                    scriptFileFound(folderPath: folderPath, realm: realm, itemFullPath: fileInfo.filePath)
                } else if fileInfo.isBBEditProject {
                    bbEditProjectFileFound(folderPath: folderPath, realm: realm, itemFullPath: fileInfo.filePath, depth: depth)
                } else if fileInfo.isWebLocation {
                    webLocationFileFound(folderPath: folderPath, realm: realm, itemFullPath: fileInfo.filePath)
                } else if depth == 0 && fileInfo.isPlainText {
                    textFileFound(folderPath: folderPath, realm: realm, itemFullPath: fileInfo.filePath)
                } else if fileInfo.isDir {
                    if fileInfo.isNotenikFilesFolder {
                        infoFileFound(folderPath: folderPath, realm: realm, itemFullPath: fileInfo.filePath)
                    } else if !foldersToSkip.contains(fileInfo.folder) {
                        scanFolder(folderPath: fileInfo.filePath, realm: realm, depth: depth + 1, folderName: fileInfo.folder)
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
        addNote(itemFullPath: itemFullPath, category: "scripts")
    }
    
    /// Add the BBEdit Project  file to the Realm Collection.
    func bbEditProjectFileFound(folderPath: String, realm: Realm, itemFullPath: String, depth: Int) {
        if depth == 0 {
            addNote(itemFullPath: itemFullPath,
                    category: "text editors",
                    title: "Open in BBEdit",
                    filePath: true,
                    setBody: false,
                    readmeCandidate: false)
        } else {
            addNote(itemFullPath: itemFullPath, category: "text editors")
        }
    }
    
    /// Add the Web Location  file to the Realm Collection.
    func webLocationFileFound(folderPath: String, realm: Realm, itemFullPath: String) {
        addNote(itemFullPath: itemFullPath, category: "web locations")
    }
    
    /// Add the text file to the Realm Collection.
    func textFileFound(folderPath: String, realm: Realm, itemFullPath: String) {
        addNote(itemFullPath: itemFullPath, category: "text files", setBody: true, readmeCandidate: true)
    }
    
    func addNote(itemFullPath: String,
                 category: String,
                 title: String? = nil,
                 filePath: Bool = true,
                 setBody: Bool = false,
                 readmeCandidate: Bool = false) {
        
        var possibleURL: URL?
        if filePath {
            possibleURL = URL(fileURLWithPath: itemFullPath)
        } else {
            possibleURL = URL(string: itemFullPath)
        }
        guard let itemURL = possibleURL else {
            return
        }
        
        let newNote = Note(collection: realmCollection!)
        let itemFileName = FileName(itemFullPath)

        var folderIndex = itemFileName.folders.count - 1
        if itemFileName.folders[folderIndex] == "reports" || itemFileName.folders[folderIndex] == "scripts" {
            folderIndex -= 1
        }
        var titleOK = false
        if title != nil && !title!.isEmpty {
            titleOK = newNote.setTitle(title!)
        }
        if !titleOK {
            let itemTitle = AppPrefs.shared.idFolderFrom(url: itemURL, below: realmURL)
            titleOK = newNote.setTitle(itemTitle)
        }
        if !titleOK {
            logError("Title could not be set")
        }
        
        let linkOK = newNote.setLink(itemURL.absoluteString)
        if !linkOK {
            logError("Link could not be set to \(itemURL.absoluteString)")
        }
        var tags = category
        if itemFullPath.hasPrefix(collectionPath) {
            tags.append(", ")
            tags.append(collectionTag)
            tags.append(".\(category.lowercased())")
        } else {
            tags.append(", ")
            tags.append(TagsValue.tagify(itemFileName.folder))
        }
        let tagsOK = newNote.setTags(tags)
        if !tagsOK {
            logError("Tags could not be set to \(tags)")
        }
        
        // Set the body of the note.
        if setBody {
            var bodyOK = false
            do {
                let body = try String(contentsOf: itemURL)
                bodyOK = newNote.setBody(body)
                if !bodyOK {
                    logError("Note Body could not be set to \(body)")
                }
            } catch {
                logError("Couldn't read Text File Project file at \(itemFullPath)")
            }
        }
        
        // Now stash the note into memory.
        newNote.identify()
        let (addedNote, _) = realmIO.addNote(newNote: newNote)
        if addedNote == nil {
            logError("Note titled \(newNote.title.value) could not be added")
        } else {
            if readmeCandidate && itemFileName.baseLower.contains("readme") {
                readmeNote = addedNote
            }
        }
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
