//
//  CloudNik.swift
//
//  Created by Herb Bowie on 4/24/20.
//
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Interact with the Notenik iCloud container.
public class CloudNik {
    
    // Singleton instance
    public static let shared = CloudNik()
    
    let fm = FileManager.default
    var ubiquityIdentityToken: Any?
    public var url: URL?
    public var path = ""
    public var exists = false
    
    init() {
        guard iCloudAvailable else {
            logError("iCloud not available")
            return
        }
        
        url = fm.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        guard url != nil else {
            logError("iCloud container not available")
            return
        }
        
        path = url!.path
        exists = fm.fileExists(atPath: path)
        logInfo("iCloud container available at \(path) exists? \(exists)")
    }
    
    /// Create a folder for a new Collection within the Notenik iCloud container. 
    func createNewFolder(folderName: String) -> URL? {
        guard iCloudAvailable else { return nil }
        guard url != nil else { return nil }
        guard exists else { return nil }
        let newFolderURL = url!.appendingPathComponent(folderName)
        do {
            try fm.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logError("Could not create new collection at \(newFolderURL.path)")
            return nil
        }
        return newFolderURL
    }
    
    /// Is iCloud available?
    public var iCloudAvailable: Bool {
        ubiquityIdentityToken = fm.ubiquityIdentityToken
        return ubiquityIdentityToken != nil
    }
    
    /// Send an info message to the Log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CloudNik",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func logError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CloudNik",
                          level: .error,
                          message: msg)
        
    }
    
}
