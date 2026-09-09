//
//  CollectionScanner.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/6/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class CollectionScanner {
    
    let fileManager = FileManager.default
    
    let foldersToSkip = Set(["cgi-bin", "core", "css", "downloads", "files", "fonts", "images", "includes", "javascript", "js", "lib", "modules", "themes", "wp-admin", "wp-content", "wp-includes"])
    
    var io: NotenikIO = BunchIO()
    var collection: NoteCollection?
    var initialFolders: [String] = []
    
    public init() {
        
    }
    
    /// Open a folder, scanning  for its collections
    public func scan (within: URL) -> NotenikIO {
        let provider = Provider()
        let realm = Realm(provider: provider)
        realm.path = within.path
        realm.name = within.path
        
        io = BunchIO()
        collection = io.openCollection(realm: realm, collectionPath: "", readOnly: true, multiRequests: nil)
        
        if collection != nil {
            collection!.dict.unlock()
            _ = collection!.dict.addDef(typeCatalog: collection!.typeCatalog, label: "Title")
            _ = collection!.dict.addDef(typeCatalog: collection!.typeCatalog, label: "Tags")
            _ = collection!.dict.addDef(typeCatalog: collection!.typeCatalog, label: "Link")
            _ = collection!.dict.addDef(typeCatalog: collection!.typeCatalog, label: "Body")
            collection!.linkFormatter = LinkFormatter(with: "s|x|x|x|x")
            // collection!.dict.display()
            initialFolders = within.pathComponents
            collection!.readOnly = true
            collection!.isRealmCollection = true
            scanFolder(folderURL: within, folderName: "", parents: [])
        } else {
            logError("Unable to scan the folder at \(within)")
        }
        /*
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
        } */
        return io
    }
    
    /// Scan folders recursively looking for signs that they are Notenik Collections
    func scanFolder(folderURL: URL, folderName: String, parents: [String]) {
        var subParents: [String] = parents
        if !folderName.isEmpty {
            subParents.append(folderName)
        }
        var infoFound = false
        var templateFound = false
        var projectInfoFound = false
        do {
            let dirContents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for item in dirContents {
                let name = item.deletingPathExtension().lastPathComponent
                let ext = item.pathExtension.lowercased()
                switch ext {
                case "app", "dmg":
                    break
                case "nnk":
                    if name.starts(with: "- project-INFO") {
                        projectInfoFound = true
                    } else if name.starts(with: "- INFO") {
                        if name.contains("parent") {
                            projectInfoFound = true
                        } else {
                            infoFound = true
                        }
                    }
                case "":
                    if foldersToSkip.contains(name) {
                        // skip certain folder names
                    } else {
                        let isDir = isDirectory(url: item)
                        if isDir {
                            scanFolder(folderURL: item, folderName: name, parents: subParents)
                        }
                    }
                default:
                    if name == "template" {
                        templateFound = true
                    }
                }
                /*
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
                } */
            }
        } catch {
            logError("Failed reading contents of folder at '\(folderURL)'")
        }
        if projectInfoFound {
            projectInfoFileFound(url: folderURL)
        } else if infoFound && templateFound {
            infoFileFound(url: folderURL)
        }
    }
    
    func infoFileFound(url: URL) {
        var collectionURL: URL = url
        if url.lastPathComponent == "- notenik_files" {
            collectionURL = url.deletingLastPathComponent()
        }
        addNote(url: collectionURL)
    }
    
    func projectInfoFileFound(url: URL) {
        addNote(url: url, project: true)
    }
    
    func addNote(url: URL, project: Bool = false) {
        
        let newNote = Note(collection: collection!)
        
        let folders = url.pathComponents
        var title = ""
        var i = initialFolders.count
        while i < folders.count {
            let folder = folders[i]
            if !title.isEmpty {
                title.append(" / ")
            }
            title.append(folder)
            i += 1
        }
        
        _ = newNote.setTitle(title)
        
        let linkFormatter = CustomURLFormatter()
        let link = linkFormatter.open(url: url)
        _ = newNote.setLink(link)
        
        if project {
            _ = newNote.setTags("projects")
        } else {
            _ = newNote.setTags("collections")
        }
        
        /*
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
        } */
        
        // Now stash the note into memory.
        newNote.identify()
        let (addedNote, _) = io.addNote(newNote: newNote)
        if addedNote == nil {
            logError("Note titled \(newNote.title.value) could not be added")
        }
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "CollectionScanner",
                          level: .error,
                          message: msg)
    }
    
    func isDirectory(url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
}
