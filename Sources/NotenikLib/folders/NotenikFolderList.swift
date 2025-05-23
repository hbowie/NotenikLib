//
//  NotenikFolderList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/26/20.

//  Copyright © 2020 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// The list of available Notenik folders. 
public class NotenikFolderList: Sequence {
    
    public static let shared = NotenikFolderList()
    
    let fm    = FileManager.default
    let prefs = AppPrefs.shared
    
    var ubiquityIdentityToken: Any?
    public var iCloudContainerURL: URL?
    public var iCloudContainerPath = ""
    public var iCloudContainerExists = false
    
    var folders: [NotenikLink] = []
    
    public var starterPacksUserFolder: URL?
    
    public let root = NotenikFolderNode()
    
    public var helpParent = NotenikFolderNode()
    public var kbNode     = NotenikFolderNode()
    public var tipsNode   = NotenikFolderNode()
    public var mcNode     = NotenikFolderNode()
    
    public var count: Int { return folders.count }
    
    /// Initialize.
    private init() {
        loadHelpNotes()
        loadICloudContainerFolders()
    }
    
    /// Load the help notes stored in the application's bundle.
    func loadHelpNotes() {
        
        let helpGroup = NotenikFolderNode(type: .group, desc: "Help Notes")
        helpParent = root.addChild(newNode: helpGroup)
        
        #if os(OSX)
        
            kbNode = NotenikFolderNode(bundlePath: NotenikConstants.kbPath,
                                       desc: NotenikConstants.kbDesc)
            _ = helpParent.addChild(newNode: kbNode)
        
            tipsNode = NotenikFolderNode(bundlePath: NotenikConstants.tipsPath,
                                     desc: NotenikConstants.tipsDesc)
            _ = helpParent.addChild(newNode: tipsNode)
        
            mcNode = NotenikFolderNode(bundlePath: NotenikConstants.mcPath,
                                       desc: NotenikConstants.mcDesc)
            _ = helpParent.addChild(newNode: mcNode)
            
        #elseif os(iOS)
            
            introNode = NotenikFolderNode(bundlePath: NotenikConstants.iosIntroPath,
                                              desc: NotenikConstants.iosIntroDesc)
            _ = helpParent.addChild(newNode: introNode)
            
        #endif
    
    }
    
    /// Load the folders found in Notenik's iCloud containter.
    func loadICloudContainerFolders() {
        guard iCloudContainerAvailable else {
            logError("iCloud Container for Notenik not available")
            return
        }
        
        iCloudContainerURL = fm.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        guard iCloudContainerURL != nil else {
            logError("iCloud Notenik Documents Container does not exist")
            return
        }
        
        iCloudContainerPath = iCloudContainerURL!.path
        iCloudContainerExists = fm.fileExists(atPath: iCloudContainerPath)
        if !iCloudContainerExists {
            logInfo("iCloud Notenik container could not be found at \(iCloudContainerPath)?")
            do {
                try fm.createDirectory(at: iCloudContainerURL!,
                                   withIntermediateDirectories: true,
                                   attributes: nil)
                iCloudContainerExists = true
            } catch {
                logError("Attempt to create iCloud container for Notenik threw an error: \(error)")
            }
        }
        logInfo("iCloud Notenik Documents container available at \(iCloudContainerPath)? \(iCloudContainerExists)")
        
        do {
            let iCloudContents = try fm.contentsOfDirectory(at: iCloudContainerURL!,
                                                         includingPropertiesForKeys: nil,
                                                         options: .skipsHiddenFiles)
            for doc in iCloudContents {
                if doc.lastPathComponent == NotenikConstants.starterPacksFolderName {
                    starterPacksUserFolder = doc
                } else {
                    let notenikFolder = NotenikLink(url: doc,
                                                    location: .iCloudContainer)
                    switch notenikFolder.type {
                    case .folder, .ordinaryCollection, .webCollection, .parentRealm:
                        add(notenikFolder)
                    default:
                        break
                    }
                }
            }
        } catch {
            logError("Error reading contents of iCloud drive folder")
        }
        
        if starterPacksUserFolder == nil {
            let starterPacksURL = iCloudContainerURL!.appendingPathComponent(NotenikConstants.starterPacksFolderName)
            let ok = FileUtils.ensureFolder(forURL: starterPacksURL)
            if ok {
                starterPacksUserFolder = starterPacksURL
            }
        }
    }
    
    /// Load the Collection shortcuts last saved by the user.
    public func loadShortcutsFromPrefs() {

        let shortcutStr = AppPrefs.shared.shortcuts
        let shortcuts = shortcutStr.components(separatedBy: "; ")
        for shortcut in shortcuts {
            let shortcutSplit = shortcut.components(separatedBy: ", ")
            if shortcutSplit.count == 2 {
                logInfo("Loading Shortcut of \(shortcutSplit[0]) with path of \(shortcutSplit[1])")
                let id = shortcutSplit[0]
                let linkStr = shortcutSplit[1]
                updateWithShortcut(linkStr: linkStr, shortcut: id)
            }
        }
    }
    
    public func forgetShortcuts() {
        AppPrefs.shared.shortcuts = ""
        var forgotten = 0
        for folder in folders {
            if !folder.shortcut.isEmpty {
                folder.shortcut = ""
                forgotten += 1
            }
        }
        logInfo("\(forgotten) Collection Shortcuts Forgotten")
    }
    
    public func savePrefs() {
        var shortcuts = ""
        for folder in folders {
            if folder.shortcut.count > 0 {
                if shortcuts.count > 0 {
                    shortcuts.append("; ")
                }
                shortcuts.append(folder.shortcut)
                shortcuts.append(", ")
                shortcuts.append(folder.linkStr)
            }
        }
        AppPrefs.shared.shortcuts = shortcuts
    }
    
    public func updateWithShortcut(linkStr: String, shortcut: String) {
        let folder = NotenikLink(str: linkStr, assume: .assumeFile)
        for existingFolder in folders {
            if folder == existingFolder {
                existingFolder.shortcut = shortcut
                MultiFileIO.shared.register(link: existingFolder)
                return
            } else if folder < existingFolder {
                folder.shortcut = shortcut
                add(folder)
                return
            } 
        }
        folder.shortcut = shortcut
        add(folder)
    }
    
    public func downloadFolders() {
        for folder in folders {
            do {
                try fm.startDownloadingUbiquitousItem(at: folder.url!)
            } catch {
                logError("Error downloading folder at \(folder.path)")
                logError("Error: \(error)")
            }
        }
    }
    
    /// Given an iCloud folder name, return a complete URL.
    public func getICloudURLFromFolderName(_ folderName: String) -> URL? {
        guard iCloudContainerURL != nil else { return nil }
        return iCloudContainerURL!.appendingPathComponent(folderName)
    }
    
    /// Add another collection to the list of known collections.
    public func add(_ collection: NoteCollection) {
        let url = collection.lib.getURL(type: .collection)
        guard url != nil else { return }
        let newFolder = NotenikLink(url: url!, isCollection: true)
        newFolder.shortcut = collection.shortcut
        add(newFolder)
    }
    
    /// Add another folder to the tree, along with its specified metadata.
    public func add(url: URL, type: NotenikLinkType, location: NotenikFolderLocation) {
        let newFolder = NotenikLink(url: url, type: type, location: location)
        add(newFolder)
    }
    
    /// Add another folder to the list.
    func add(_ folder: NotenikLink) {
        
        guard !folder.path.contains("Notenik.app/Contents/Resources") else {
            return
        }
        
        /// Make sure the url points to a directory.
        guard folder.isFileLink
                // This says no just because there is no trailing slash
                // && folder.url.hasDirectoryPath
        else {
            logError("URL does not point to a file directory: \(folder)")
            return
        }
        
        // Is this url even reachable?
        guard folder.isReachable else {
            logError("URL is not reachable: \(folder)")
            return
        }
        
        // Do we already have it in the list?
        var index = 0
        for existingFolder in folders {
            if folder == existingFolder {
                return
            } else if folder < existingFolder {
                break
            } else {
                index += 1
            }
        }
        
        /// Let's see if the passed URL  points to a Notenik Collection.
        folder.determineCollectionType(source: .fromWithout)
        
        if index < folders.count {
            folders.insert(folder, at: index)
        } else {
            folders.append(folder)
        }
        
        MultiFileIO.shared.register(link: folder)
        
        var parent: NotenikFolderNode!
        if folder.location == .iCloudContainer {
            parent = root.addChild(type: .group, desc: "iCloud Container")
        } else {
            parent = root.addChild(type: .group, desc: "Recent")
        }
        
        _ = parent.addChild(type: .folder, desc: folder.briefDesc, folder: folder)
    }
    
    /// Remove the given folder from our internal lists. 
    public func remove(folder: NotenikLink) -> Bool {
        var index = 0
        
        for existingFolder in folders {
            if folder == existingFolder {
                folders.remove(at: index)
                break
            }
            index += 1
        }
        
        for group in root.children {
            index = 0
            for folderNode in group.children {
                if folderNode.type == .folder && folderNode.folder != nil && folderNode.folder! == folder {
                    group.remove(at: index)
                    return true
                }
                index += 1
            }
        }
        return false
    }
    
    /// Create a folder for a new Collection within the Notenik iCloud container.
    /// - Parameter folderName: The name of the new folder to be created.
    /// - Returns: The URL pointing to the new folder, if successful, and the problem description, if unsuccessful.
    public func createNewFolderWithinICloudContainer(folderName: String) -> (URL?, String?) {
        guard iCloudContainerAvailable else { return (nil, "iCloud container not available") }
        guard iCloudContainerURL != nil else { return (nil, "iCloud container not available") }
        guard iCloudContainerExists else { return (nil, "iCloud available but Notenik container does not exist") }
        let newFolderURL = iCloudContainerURL!.appendingPathComponent(folderName)
        guard !fm.fileExists(atPath: newFolderURL.path) else {
            logError("Folder named \(folderName) already exists within the Notenik iCloud container")
            return (nil, "Folder named \(folderName) already exists within the Notenik iCloud container")
        }
        do {
            try fm.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logError("Could not create new collection at \(newFolderURL.path)")
            return (nil, "Could not create new Collection at \(newFolderURL.path) due to error: \(error)")
        }
        return (newFolderURL, nil)
    }
    
    public func getFolderFor(shortcut: String) -> NotenikLink? {
        for folder in folders {
            if folder.shortcut == shortcut {
                return folder
            }
        }
        return nil
    }
    
    public func getFolderFor(path: String) -> NotenikLink? {
        var target = path
        if !target.starts(with: "file://") {
            target = "file://" + path
        }
        for folder in folders {
            if folder.str == target {
                return folder
            }
        }
        return nil
    }
    
    /// Is iCloud available?
    public var iCloudContainerAvailable: Bool {
        ubiquityIdentityToken = fm.ubiquityIdentityToken
        return ubiquityIdentityToken != nil
    }
    
    /// Make the list accessible via an index.
    subscript(index: Int) -> NotenikLink {
        return folders[index]
    }
    
    /// Provide a way of iterating through the list. 
    public func makeIterator() -> NotenikFolderIterator {
        return NotenikFolderIterator(self)
    }
    
    /// Send an info message to the Log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "NotenikFolderList",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "NotenikFolderList",
                          level: .error,
                          message: msg)
    }
    
    /// Debugging info.
    public func displayTree() {
        print("Displaying NotenikFolderList tree")
        for group in root.children {
            print(group.desc)
            for folder in group.children {
                print("    \(folder.desc)")
            }
        }
    }
}
