//
//  KnownFiles.swift
//  Notenik
//
//  Created by Herb Bowie on 4/21/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A bunch of known Notenik Collections, organized by their location. 
public class KnownFolders: Sequence {
    
    public static let shared = KnownFolders()
    
    let keyPrefix = "bookmark"
    let defaults = UserDefaults.standard
    
    var folders: [KnownFolder] = []
    
    public var root: KnownFolderNode!
    
    var baseList: [KnownFolderBase] = []
    
    let fm      = FileManager.default
    let home    = FileManager.default.homeDirectoryForCurrentUser
    var cloudNik: CloudNik!
    
    var viewer: KnownFoldersViewer?
    
    init() {
        // print("Known Folders init")
        root = KnownFolderNode(tree: self)
        
        var homeDir = home
        while homeDir.pathComponents.count > 3 {
            homeDir.deleteLastPathComponent()
        }
        let osBase = KnownFolderBase(name: "Home ~", url: homeDir)
        addBase(base: osBase)
        
        var cloudDir = homeDir.appendingPathComponent("Library")
        cloudDir.appendPathComponent("Mobile Documents")
        cloudDir.appendPathComponent("com~apple~CloudDocs")
        let cloudBase = KnownFolderBase(name: "iCloud Drive", url: cloudDir)
        addBase(base: cloudBase)

        /* cloudNik = CloudNik.shared
        if cloudNik.url != nil {
            let cloudBase = KnownFolderBase(name: "iCloud Drive", url: cloudNik.url!)
            baseList.append(cloudBase)
            addBase(base: cloudBase)
            /* do {
                
                let iCloudContents = try fm.contentsOfDirectory(at: cloudNik.url!,
                                                             includingPropertiesForKeys: nil,
                                                             options: .skipsHiddenFiles)
                print("  - \(iCloudContents.count) entries in iCloud")
                for doc in iCloudContents {
                    print("  - contents of iCloud Drive = \(doc.path)")
                    // add(doc)
                }
            } catch {
                logError("Error reading contents of iCloud drive folder")
            } */
        } */
    }
    
    /// Try to load security-scoped bookmarks stored from previous sessions. 
    public func loadBookmarkDefaults() {
        logInfo("Loading Bookmarks saved from Prior Sessions")
        var bookmarkNumber = 1
        var bookmark: Data?
        var stale = false
        var loaded = 0
        repeat {
            bookmark = defaults.data(forKey: key(forNumber: bookmarkNumber))
            guard bookmark != nil else { continue }
            do {
                let url = try URL(resolvingBookmarkData: bookmark!,
                                  options: URL.BookmarkResolutionOptions.withSecurityScope,
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &stale)
                if stale {
                    logInfo("URL \(url.path) is stale, and must be explicitly re-opened")
                } else {
                    let newFolder = KnownFolder(url: url, isCollection: false, fromBookmark: true)
                    add(newFolder, suspendReload: true)
                    loaded += 1
                    logInfo("URL \(url) successfully loaded")
                }
            } catch {
                logError("Bookmark # \(bookmarkNumber) could not be resolved")
            }
            bookmarkNumber += 1
        } while bookmark != nil
        reload()
        logInfo("\(loaded) Bookmarks loaded from user defaults")
    }
    
    /// Add another collection to the list of known collections.
    public func add(_ collection: NoteCollection, suspendReload: Bool) {
        let url = collection.collectionFullPathURL
        if url != nil {
            let newFolder = KnownFolder(url: url!, isCollection: true, fromBookmark: false)
            add(newFolder, suspendReload: suspendReload)
        }
    }
    
    /// Add another folder to the tree, along with its specified metadata.
    public func add(url: URL, isCollection: Bool, fromBookmark: Bool = false, suspendReload: Bool) {
        let newFolder = KnownFolder(url: url, isCollection: isCollection, fromBookmark: fromBookmark)
        add(newFolder, suspendReload: suspendReload)
    }
    
    /// Add another folder to the tree.
    public func add(_ known: KnownFolder, suspendReload: Bool) {
        
        // print("KnownFolders.add \(known)")
        guard !known.url.path.contains("Notenik.app/Contents/Resources") else {
            return
        }
        
        /// Make sure the url points to a directory.
        guard known.url.isFileURL && known.url.hasDirectoryPath else {
            logError("URL does not point to a file directory: \(known.url.absoluteString)")
            return
        }
        
        // Is this url even reachable?
        var folderReachable = false
        do {
            folderReachable = try known.url.checkResourceIsReachable()
        } catch {
            logError("Trouble determining URL reachability for: \(known.url.absoluteString)")
            return
        }
        guard folderReachable else {
            logError("URL is not reachable: \(known.url.absoluteString)")
            return
        }
        
        // Do we already have it in the list?
        for folder in folders {
            if known.path == folder.path {
                // print("  - URL already known")
                return
            }
        }
        
        /// Let's see if the passed URL  points to a Notenik Collection.
        let folderPath = known.path
        let infoPath = FileUtils.joinPaths(path1: folderPath, path2: FileIO.infoFileName)
        let infoURL = URL(fileURLWithPath: infoPath)
        do {
            known.isCollection = try infoURL.checkResourceIsReachable()
        } catch {
            // Leave as-is
        }

        if !known.isCollection {
            // print("  - URL does not point to a collection")
        }
        
        // guard urlPointsToCollection else { return }
        
        let urlPath = known.path
        var longestBase = KnownFolderBase()
        for base in baseList {
            if urlPath.starts(with: base.path) && base.count > longestBase.count {
                longestBase = base
            }
        }
        let collectionFileName = FileName(known.url)
        folders.append(known)
        add(url: known.url, fileName: collectionFileName, base: longestBase, startingIndex: longestBase.count - 1, known: known, suspendReload: suspendReload)
    }
    
    func addBase(base: KnownFolderBase) {
        // print("KnownFolders add base \(base)")
        baseList.append(base)
        let baseNode = KnownFolderNode(tree: self)
        baseNode.type = .folder
        baseNode.base = base
        _ = root.addChild(baseNode)
    }
    
    /// Add a new Collection to the tree, along with any nodes leading to it.
    /// - Parameters:
    ///   - url: The URL locating the collection.
    ///   - fileName: The FileName object locating the collection.
    ///   - base: The base description to be assigned to this collection.
    ///   - startingIndex: An index pointing to the first folder to be used as part
    ///                    of the collection's path.
    func add(url: URL,
             fileName: FileName,
             base: KnownFolderBase,
             startingIndex: Int,
             known: KnownFolder?,
             suspendReload: Bool) {
        
        /*
        print("KnownFolders adding url of \(url.path)")
        print("  - File Name: \(fileName)")
        print("  - Base: \(base)")
        print("  - Starting Index: \(startingIndex)")
        if known != nil {
            print("  - Known folder: \(known!)")
        }
        */
        
        // Add base node or obtain it if already added.
        let baseNode = KnownFolderNode(tree: self)
        baseNode.type = .folder
        baseNode.base = base
        var nextParent = root.addChild(baseNode)
        
        // Now add intervening path folders.
        let end = fileName.folders.count - 1
        if end >= startingIndex {
            for i in startingIndex ..< end {
                let nextChild = KnownFolderNode(tree: self)
                nextChild.type = .folder
                nextChild.base = base
                nextChild.populatePath(folders: fileName.folders, start: startingIndex, number: i - startingIndex)
                nextChild.folder = fileName.folders[i]
                nextParent = nextParent.addChild(nextChild)
            }
        }
        
        // Finally, add the actual node representing the collection.
        let lastChild = KnownFolderNode(tree: self, url: url)
        lastChild.type = .collection
        lastChild.base = base
        lastChild.populatePath(folders: fileName.folders, start: startingIndex, number: end - startingIndex)
        lastChild.folder = fileName.folders[end]
        lastChild.known = known
        _ = nextParent.addChild(lastChild)
        
        if !suspendReload {
            if viewer != nil {
                viewer!.reload()
            }
        }
    }
    
    /// Forget about the passed node.
    public func remove(_ known: KnownFolderNode) {
        var i = 0
        let knownFolder = known.known
        if knownFolder != nil {
            for folder in folders {
                if knownFolder!.path == folder.path {
                    folders.remove(at: i)
                    break
                } else {
                    i += 1
                }
            }
        }
        
        if !known.hasChildren {
            var j = 0
            while j < known.parent!.countChildren {
                if known.parent!.getChild(at: j) == known {
                    known.parent!.remove(at: j)
                    break
                } else {
                    j += 1
                }
            }
        }

    }
    
    public func saveDefaults() {
        // print("Known Folders saving defaults")
        var bookmarkNumber = 1
        for folder in folders {
            if folder.fromBookmark && folder.inUse {
                folder.url.stopAccessingSecurityScopedResource()
            }
            do {
                let bookmark = try folder.url.bookmarkData(options: URL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                defaults.set(bookmark, forKey: key(forNumber: bookmarkNumber))
                // print("  - Saved User Default for key \(key(forNumber: bookmarkNumber)) with url \(folder)")
                bookmarkNumber += 1
            } catch {
                logError("  - Couldn't create bookmark for \(folder.path) due to \(error)")
            }
        }
        defaults.removeObject(forKey: key(forNumber: bookmarkNumber))
    }
    
    public func registerViewer(_ viewer: KnownFoldersViewer) {
        self.viewer = viewer
    }
    
    public func reload() {
        if viewer != nil {
            viewer!.reload()
        }
    }
    
    func key(forNumber: Int) -> String {
        return "\(keyPrefix)\(forNumber)"
    }
    
    /// Log an information message.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "KnownFolders",
                          level: .info,
                          message: msg)
    }
    
    /// Log an information message.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "KnownFolders",
                          level: .error,
                          message: msg)
    }
    
    public func makeIterator() -> KnownFoldersTreeIterator {
        return KnownFoldersTreeIterator(tree: self)
    }
    
    func add(more: [String], to: String) -> String {
        var added = to
        for toAdd in more {
            added = FileUtils.joinPaths(path1: added, path2: toAdd)
        }
        return added
    }
    
}
