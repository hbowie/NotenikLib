//
//  NotenikFolderList.swift
//
//  Created by Herb Bowie on 8/26/20.

//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// The list of available Notenik folders. 
public class NotenikFolderList: Sequence {
    
    public static let shared = NotenikFolderList()
    
    let fm = FileManager.default
    
    var ubiquityIdentityToken: Any?
    var iCloudContainerURL: URL?
    var iCloudContainerPath = ""
    var iCloudContainerExists = false
    
    var folders: [NotenikFolder] = []
    
    var count: Int { return folders.count }
    
    /// Initialize.
    private init() {
        loadICloudContainerFolders()
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
                let notenikFolder = NotenikFolder(url: doc, type: .undetermined, location: .iCloudContainer)
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
        let url = collection.collectionFullPathURL
        if url != nil {
            let newFolder = NotenikFolder(url: url!, isCollection: true)
            add(newFolder)
        }
    }
    
    /// Add another folder to the tree, along with its specified metadata.
    public func add(url: URL, type: NotenikFolderType, location: NotenikFolderLocation) {
        let newFolder = NotenikFolder(url: url, type: type, location: location)
        add(newFolder)
    }
    
    /// Add another folder to the list.
    public func add(_ folder: NotenikFolder) {
        
        guard !folder.path.contains("Notenik.app/Contents/Resources") else {
            return
        }
        
        /// Make sure the url points to a directory.
        guard folder.url.isFileURL && folder.url.hasDirectoryPath else {
            logError("URL does not point to a file directory: \(folder.url.absoluteString)")
            return
        }
        
        // Is this url even reachable?
        var folderReachable = false
        do {
            folderReachable = try folder.url.checkResourceIsReachable()
        } catch {
            logError("Trouble determining URL reachability for: \(folder.url.absoluteString)")
            return
        }
        guard folderReachable else {
            logError("URL is not reachable: \(folder.url.absoluteString)")
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
        let infoPath = FileUtils.joinPaths(path1: folder.path, path2: FileIO.infoFileName)
        let infoURL = URL(fileURLWithPath: infoPath)
        var folderIsACollection = false
        do {
            folderIsACollection = try infoURL.checkResourceIsReachable()
            if folderIsACollection {
                folder.type = .collection
            }
        } catch {
            // Leave as-is
        }
        
        // guard urlPointsToCollection else { return }
        
        if index < folders.count {
            folders.insert(folder, at: index)
        } else {
            folders.append(folder)
        }
    }
    
    /// Create a folder for a new Collection within the Notenik iCloud container.
    func createNewFolderWithinICloudContainer(folderName: String) -> URL? {
        guard iCloudContainerAvailable else { return nil }
        guard iCloudContainerURL != nil else { return nil }
        guard iCloudContainerExists else { return nil }
        let newFolderURL = iCloudContainerURL!.appendingPathComponent(folderName)
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
    subscript(index: Int) -> NotenikFolder {
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
}
