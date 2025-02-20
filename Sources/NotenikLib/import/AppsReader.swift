//
//  AppsReader.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/8/25.

//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation
import NotenikUtils

/// A class to read a comma-delimited or tab-delimited file and
/// return column headings and row values.
///
/// The file must have UTF-8 encoding.
/// The first line of the file must contain column headings.
public class AppsReader: RowImporter {
    
    let fm = FileManager.default
    
    var consumer:           RowConsumer!
    
    var labels:             [String] = []
    var fields:             [String] = []
    
    let linkToLaunchProper = "Link to Launch"
    let webLinkProper      = "Web Link"
    let appVersionProper   = "App Version"
    let appDateProper      = "App Date"
    let minSysVersionProper = "Minimum System Version"
    let licenseKeyProper   = "License Key"
    
    let statusConfig = "0 - Suggested; 6 - Installed; 7 - Trial; 8 - Rejected; 9 - Enabled; "
    
    var linkToLaunchDef = FieldDefinition()
    var webLinkDef      = FieldDefinition()
    var dateModifiedDef = FieldDefinition()
    var appVersionDef   = FieldDefinition()
    var minSysVersionDef = FieldDefinition()
    var licenseKeyDef   = FieldDefinition()
    var statusDef       = FieldDefinition()
    
    public init() {
        
    }
    
    public func prepDict(collection: NoteCollection) {
        
        // Make sure we have the fields we'll be using in
        // the Collection dictionary. Add them if they are
        // missing.
        let dict = collection.dict
        let types = collection.typeCatalog
        
        dict.unlock()
        
        // Status
        if let stDef = dict.getDef(NotenikConstants.status) {
            statusDef = stDef
        } else {
            if let stDef = dict.addDef(typeCatalog: types, label: NotenikConstants.status) {
                statusDef = stDef
                collection.registerDef(statusDef)
                let config = collection.statusConfig
                config.set(statusConfig)
                collection.typeCatalog.statusValueConfig = config
            }
        }

        // Link to Launch
        if let llDef = dict.getDef(linkToLaunchProper) {
            linkToLaunchDef = llDef
        } else {
            if let llDef = dict.addDef(typeCatalog: types, label: linkToLaunchProper) {
                linkToLaunchDef = llDef
                collection.registerDef(linkToLaunchDef)
            }
        }
        
        // Web Link
        if let wlDef = dict.getDef(webLinkProper) {
            webLinkDef = wlDef
        } else {
            if let wlDef = dict.addDef(typeCatalog: types, label: webLinkProper) {
                webLinkDef = wlDef
                collection.registerDef(webLinkDef)
            }
        }
        
        // App Date
        if let dmDef = dict.getDef(appDateProper) {
            dateModifiedDef = dmDef
        } else {
            if let dmDef = dict.addDef(typeCatalog: types, label: appDateProper) {
                dateModifiedDef = dmDef
                collection.registerDef(dateModifiedDef)
            }
        }
        
        // Minimum System Version
        if let msDef = dict.getDef(minSysVersionProper) {
            minSysVersionDef = msDef
        } else {
            let msDef = FieldDefinition(typeCatalog: types,
                                        label: minSysVersionProper,
                                        type: NotenikConstants.seqCommon)
            if let msDef2 = dict.addDef(msDef) {
                minSysVersionDef = msDef2
                collection.registerDef(minSysVersionDef)
            }
        }
        
        // App Version
        if let vsDef = dict.getDef(appVersionProper) {
            appVersionDef = vsDef
        } else {
            let vsDef = FieldDefinition(typeCatalog: types,
                                        label: appVersionProper,
                                        type: NotenikConstants.seqCommon)
            if let vsDef2 = dict.addDef(vsDef) {
                appVersionDef = vsDef2
                collection.registerDef(appVersionDef)
            }
        }
        
        // License Key
        if let lkDef = dict.getDef(licenseKeyProper) {
            licenseKeyDef = lkDef
        } else {
            let lkDef = FieldDefinition(typeCatalog: types,
                                        label: licenseKeyProper,
                                        type: NotenikConstants.longTextType)
            if let lkDef2 = dict.addDef(lkDef) {
                licenseKeyDef = lkDef2
                collection.registerDef(licenseKeyDef)
            }
        }
        
        dict.lock()
        
    }
    
    /// Initialize the class with a Row Consumer.
    public func setContext(consumer: RowConsumer) {
        self.consumer = consumer
    }
    
    /// Read the file and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    public func read(fileURL: URL) {
        
        labels = []
        labels.append(NotenikConstants.title)
        labels.append(NotenikConstants.tags)
        labels.append(NotenikConstants.status)
        labels.append(linkToLaunchProper)
        labels.append(webLinkProper)
        labels.append(appDateProper)
        labels.append(minSysVersionProper)
        labels.append(appVersionProper)
        labels.append(licenseKeyProper)
        labels.append(NotenikConstants.body)
        
        scanFolder(folderURL: fileURL)
    }
    
    func scanFolder(folderURL: URL) {
        do {
            let dirContents = try fm.contentsOfDirectory(atPath: folderURL.path)
            for item in dirContents {
                if item.starts(with: ".") { continue }
                if item.hasSuffix(".app") {
                    handleApp(appFolder: folderURL, bundleName: item)
                } else {
                    let itemPath = FileUtils.joinPaths(path1: folderURL.path, path2: item)
                    if FileUtils.isDir(itemPath) {
                        let subFolder = folderURL.appendingPathComponent(item, isDirectory: true)
                        scanFolder(folderURL: subFolder)
                    } else {
                        // print("    - item path is not a directory: \(itemPath)")
                    }
                }
            }
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "AppReader",
                              level: .error,
                              message: "Error reading Applications folder from \(folderURL)")
        }
    }
    
    /// Extract info about each app found.
    /// - Parameters:
    ///   - appFolder: The folder being scanned.
    ///   - bundleName: The name of an identified app within the folder.
    func handleApp(appFolder: URL, bundleName: String) {
        
        // Get the app name, without the trailing '.app'
        var components = bundleName.components(separatedBy: ".")
        guard components.count > 1 else { return }
        components.removeLast()
        let appName = components.joined(separator: ".")
        
        // Get what we can from the Info.plist file.
        let appBundle = appFolder.appendingPathComponent(bundleName, isDirectory: true)
        let contents = appBundle.appendingPathComponent("Contents", isDirectory: true)
        let plist = contents.appendingPathComponent("Info.plist")
        guard let infoDict = NSDictionary(contentsOfFile: plist.path) else { return }
        
        fields = []
        
        // Field 0 - Title (app name)
        putField(labelIx: 0, value: appName)
        
        // Field 1 - Tags (app category)
        if let appCategory = infoDict.object(forKey: "LSApplicationCategoryType") {
            let catStr = "\(appCategory)"
            let uselessPrefix = "public.app-category."
            var cat = ""
            if catStr.starts(with: uselessPrefix) {
                cat.append(String(catStr.dropFirst(uselessPrefix.count)))
            } else if !catStr.isEmpty {
                cat.append(catStr)
            }
            putField(labelIx: 1, value: cat, rule: .onlyIfExistingBlank)
        } else {
            fields.append("")
        }
        
        // Field 2 - Status
        putField(labelIx: 2, value: "6 - Installed", rule: .onlyIfImportHigher)

        // Field 3 - Link to Launch
        let linkToLaunch = appFolder.appendingPathComponent(bundleName, isDirectory: false)
        putField(labelIx: 3, value: linkToLaunch.description)
        
        // Field 4 - Web Link
        if let bundleID = infoDict.object(forKey: "CFBundleIdentifier") {
            let idStr = "\(bundleID)"
            let components = idStr.components(separatedBy: ".")
            if components.count >= 2 {
                var webLink = "https://"
                webLink.append(components[1])
                webLink.append(".")
                webLink.append(components[0])
                putField(labelIx: 4, value: webLink, rule: .onlyIfExistingBlank)
            } else {
                fields.append("")
            }
        } else {
            fields.append("")
        }
        
        // Field 5 - App Date (last modified)
        do {
            let attribs = try fm.attributesOfItem(atPath: linkToLaunch.path)
            let dict = attribs as NSDictionary

            // Use the last modified date as the App Date.
            if let modDate = dict.fileModificationDate() {
                putField(labelIx: 5, value: "\(modDate)")
            } else {
                fields.append("")
            }
        } catch {
            fields.append("")
        }
        
        // Field 6 - the Minimum System Version of macOS required to run the app.
        if let minSysVersion = infoDict.object(forKey: "LSMinimumSystemVersion") {
            putField(labelIx: 6, value: "\(minSysVersion)")
        } else {
            fields.append("")
        }
        
        // Field 7 -  the app version.
        if let shortVersion = infoDict.object(forKey: "CFBundleShortVersionString") {
            putField(labelIx: 7, value: "\(shortVersion)")
        } else {
            fields.append("")
        }
        
        consumer.consumeRow(labels: labels, fields: fields)

    }
    
    func putField(labelIx: Int, value: String, rule: FieldUpdateRule = .always) {
        consumer.consumeField(label: labels[labelIx], value: value, rule: rule)
        fields.append(value)
    }
    
}
