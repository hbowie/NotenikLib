//
//  AppPop.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/6/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// An instance of this class can be used to scan a macOS Applications folder,
/// extract info about the apps, and load key bits of info into the passed
/// Notenik Collection.
public class AppPop {
    
    let fm = FileManager.default
    
    let byteCountFormatter = ByteCountFormatter()
    
    let linkToLaunchProper = "Link to Launch"
    let webLinkProper      = "Web Link"
    let appVersionProper   = "App Version"
    let appDateProper      = "App Date"
    let minSysVersionProper = "Minimum System Version"
    let licenseKeyProper   = "License Key"
    
    var linkToLaunchDef = FieldDefinition()
    var webLinkDef      = FieldDefinition()
    var dateModifiedDef = FieldDefinition()
    var appVersionDef   = FieldDefinition()
    var minSysVersionDef = FieldDefinition()
    var licenseKeyDef   = FieldDefinition()
    
    var noteIO: NotenikIO!
    
    /// Initialize a new instance.
    public init() {
        byteCountFormatter.countStyle = .file
    }
    
    /// Scan the provided app folder, and update the specified Collection
    /// with the latest app info.
    /// - Parameters:
    ///   - noteIO: An I/O module for the given Collection.
    ///   - appFolder: A folder containing macOS apps.
    public func populate(noteIO: NotenikIO, appFolder: URL) {
 
        self.noteIO = noteIO
        guard let collection = noteIO.collection else { return }
        let dict = collection.dict
        let types = collection.typeCatalog
        
        // Make sure we have the fields we'll be using in
        // the Collection dictionary. Add them if they are
        // missing.
        dict.unlock()

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
        
        noteIO.persistCollectionInfo()
        
        // Now scan the applications folder.
        scanFolder(appFolder)
    }
    
    /// Scan the given folder for applications, including a recursive scan of subfolders.
    /// - Parameter appFolder: The folder to be scanned.
    func scanFolder(_ appFolder: URL) {
        do {
            let contents = try fm.contentsOfDirectory(atPath: appFolder.path)
            for item in contents {
                if item.starts(with: ".") { continue }
                if item.hasSuffix(".app") {
                    handleApp(appFolder: appFolder, bundleName: item)
                } else {
                    let itemPath = FileUtils.joinPaths(path1: appFolder.path, path2: item)
                    if FileUtils.isDir(itemPath) {
                        let subFolder = appFolder.appendingPathComponent(item, isDirectory: true)
                        scanFolder(subFolder)
                    }
                }
            }
        } catch {
            return
        }
    }
    
    /// Extract info about each app found.
    /// - Parameters:
    ///   - appFolder: The folder being scanned.
    ///   - bundleName: The name of an identified app within the folder.
    func handleApp(appFolder: URL, bundleName: String) {
        
        let appURL = appFolder.appendingPathComponent(bundleName)
        
        // Get the app name, without the trailing '.app'
        var components = bundleName.components(separatedBy: ".")
        guard components.count > 1 else { return }
        components.removeLast()
        let appName = components.joined(separator: ".")
        
        // Get an existing Note with this name, if there is one.
        let existingNote = noteIO.getNote(knownAs: appName)
        
        // Determine a good Note object to populate with app info.
        var noteToUpdate: Note?
        if existingNote == nil {
            noteToUpdate = Note(collection: noteIO.collection!)
            _ =  noteToUpdate!.setTitle(appName)
        } else {
            noteToUpdate = existingNote!.copy() as? Note
        }
        
        // Now apply the info from the scan.
        if noteToUpdate != nil {
            updateNote(appFolder: appFolder, bundleName: bundleName, note: noteToUpdate!)
        }
        
        // Now add the Note or apply updates.
        if noteToUpdate != nil {
            if existingNote == nil {
                (_, _) = noteIO.addNote(newNote: noteToUpdate!)
            } else {
                _ = noteIO.modNote(oldNote: existingNote!, newNote: noteToUpdate!)
            }
        }

    }
    
    /// Update the given Note with the info we can find out about the app.
    /// - Parameters:
    ///   - appFolder: The Applications folder being scanned.
    ///   - bundleName: The name of this app within the folder.
    ///   - note: The Note to be updated with the app info.
    func updateNote(appFolder: URL, bundleName: String, note: Note) {

        // Update with Link to Launch value.
        let linkToLaunch = appFolder.appendingPathComponent(bundleName, isDirectory: false)
        _ = note.setField(label: linkToLaunchProper, value: linkToLaunch.description)
        
        // Get what we can from the file system.
        do {
            let attribs = try fm.attributesOfItem(atPath: linkToLaunch.path)
            let dict = attribs as NSDictionary

            // Use the last modified date as the App Date.
            if let modDate = dict.fileModificationDate() {
                _ = note.setField(label: appDateProper, value: "\(modDate)")
            }
        } catch {
            // keep going
        }
        
        // Get what we can from the Info.plist file.
        let appBundle = appFolder.appendingPathComponent(bundleName, isDirectory: true)
        let contents = appBundle.appendingPathComponent("Contents", isDirectory: true)
        let plist = contents.appendingPathComponent("Info.plist")
        guard let infoDict = NSDictionary(contentsOfFile: plist.path) else { return }
        
        // Get the app version.
        if let shortVersion = infoDict.object(forKey: "CFBundleShortVersionString") {
            _ = note.setField(label: appVersionProper, value: "\(shortVersion)")
        }
        
        // Try to guess at the website for the app.
        if !note.contains(label: webLinkProper) {
            if let bundleID = infoDict.object(forKey: "CFBundleIdentifier") {
                let idStr = "\(bundleID)"
                let components = idStr.components(separatedBy: ".")
                if components.count >= 2 {
                    var webLink = "https://"
                    webLink.append(components[1])
                    webLink.append(".")
                    webLink.append(components[0])
                    _ = note.setField(label: webLinkProper, value: webLink)
                }
            }
        }
        
        // Get the Minimum System Version of macOS required to run the app.
        if let minSysVersion = infoDict.object(forKey: "LSMinimumSystemVersion") {
            _ = note.setField(label: minSysVersionProper, value: "\(minSysVersion)")
        }
        
        // Get the app category.
        if !note.hasTags() {
            if let appCategory = infoDict.object(forKey: "LSApplicationCategoryType") {
                let catStr = "\(appCategory)"
                let uselessPrefix = "public.app-category."
                var cat = "category."
                if catStr.starts(with: uselessPrefix) {
                    cat.append(String(catStr.dropFirst(uselessPrefix.count)))
                    _ = note.setTags(cat)
                } else if !catStr.isEmpty {
                    cat.append(catStr)
                    _ = note.setTags(cat)
                }
                
            }
        }
    }
    
}
