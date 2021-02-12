//
//  NotenikFolderList.swift
//
//  Created by Herb Bowie on 8/26/20.

//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// The list of available Notenik folders. 
public class NotenikFolderList: Sequence {
    
    public static let shared = NotenikFolderList()
    
    public static let helpFolderDesc = "Help Notes"
    
    let fm = FileManager.default
    
    var ubiquityIdentityToken: Any?
    public var iCloudContainerURL: URL?
    public var iCloudContainerPath = ""
    public var iCloudContainerExists = false
    
    var folders: [NotenikLink] = []
    
    public let root = NotenikFolderNode()
    
    public var count: Int { return folders.count }
    
    /// Initialize.
    private init() {
        loadHelpNotes()
        loadICloudContainerFolders()
    }
    
    func loadHelpNotes() {
        let helpGroup = NotenikFolderNode(type: .group, desc: "Help")
        let helpParent = root.addChild(newNode: helpGroup)
        let helpNotes = NotenikFolderNode(type: .folder, desc: NotenikFolderList.helpFolderDesc)
        _ = helpParent.addChild(newNode: helpNotes)
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
        logInfo("iCloud Notenik Documents container available at \(iCloudContainerPath) exists? \(iCloudContainerExists)")
        
        do {
            let iCloudContents = try fm.contentsOfDirectory(at: iCloudContainerURL!,
                                                         includingPropertiesForKeys: nil,
                                                         options: .skipsHiddenFiles)
            for doc in iCloudContents {
                let notenikFolder = NotenikLink(url: doc,
                                                type: .folder,
                                                location: .iCloudContainer)
                self.add(notenikFolder)
            }
        } catch {
            logError("Error reading contents of iCloud drive folder")
        }
    }
    
    /// Given an iCloud folder name, return a complete URL.
    public func getICloudURLFromFolderName(_ folderName: String) -> URL? {
        guard iCloudContainerURL != nil else { return nil }
        return iCloudContainerURL!.appendingPathComponent(folderName)
    }
    
    /// Add another collection to the list of known collections.
    public func add(_ collection: NoteCollection) {
        let url = collection.fullPathURL
        guard url != nil else { return }
        let newFolder = NotenikLink(url: url!, isCollection: true)
        add(newFolder)
    }
    
    /// Add another folder to the tree, along with its specified metadata.
    public func add(url: URL, type: NotenikLinkType, location: NotenikFolderLocation) {
        let newFolder = NotenikLink(url: url, type: type, location: location)
        add(newFolder)
    }
    
    /// Add another folder to the list.
    public func add(_ folder: NotenikLink) {
        
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
        folder.determineCollectionType()
        
        if index < folders.count {
            folders.insert(folder, at: index)
        } else {
            folders.append(folder)
        }
        
        var parent: NotenikFolderNode!
        if folder.location == .iCloudContainer {
            parent = root.addChild(type: .group, desc: "iCloud Container")
        } else {
            parent = root.addChild(type: .group, desc: "Recent")
        }
        _ = parent.addChild(type: .folder, desc: folder.fileOrFolderName, folder: folder)
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
    public func createNewFolderWithinICloudContainer(folderName: String) -> URL? {
        guard iCloudContainerAvailable else { return nil }
        guard iCloudContainerURL != nil else { return nil }
        guard iCloudContainerExists else { return nil }
        let newFolderURL = iCloudContainerURL!.appendingPathComponent(folderName)
        guard !fm.fileExists(atPath: newFolderURL.path) else {
            logError("Folder named \(folderName) already exists within the Notenik iCloud container")
            return nil
        }
        do {
            try fm.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logError("Could not create new collection at \(newFolderURL.path)")
            return nil
        }
        return newFolderURL
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
