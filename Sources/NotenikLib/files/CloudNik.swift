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

public class CloudNik {
    
    // Singleton instance
    public static let shared = CloudNik()
    
    let fm = FileManager.default
    var ubiquityIdentityToken: Any?
    public var url: URL?
    public var path = ""
    
    init() {
        ubiquityIdentityToken = fm.ubiquityIdentityToken
        guard ubiquityIdentityToken != nil else {
            logError("iCloud not available")
            return
        }
        
        url = fm.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        guard url != nil else {
            logError("iCloud container not available")
            return
        }
        
        path = url!.path
        var exists = fm.fileExists(atPath: path)
        logInfo("iCloud container available at \(path) exists? \(exists)")
    }
    
    func createDirectory(){
        if let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            if (!FileManager.default.fileExists(atPath: iCloudDocumentsURL.path, isDirectory: nil)) {
                do {
                    try FileManager.default.createDirectory(at: iCloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    //Error handling
                    print("Error in creating doc")
                }
            }
        }
    }
    
    public var iCloudAvailable: Bool {
        ubiquityIdentityToken = fm.ubiquityIdentityToken
        return ubiquityIdentityToken != nil
    }
    
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
