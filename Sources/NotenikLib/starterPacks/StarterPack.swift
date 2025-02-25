//
//  StarterPack.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/23/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class StarterPack: Comparable, CustomStringConvertible {
    
    let fm = FileManager.default
    
    var realm: Realm = Realm()

    public var location: URL
    
    public var teaser = "A Notenik Starter Pack"
    
    public var body   = "A Notenik Starter Pack"
    
    public var projectFolder = false
    
    /// Initialize with location of the Starter Pack.
    /// - Parameter location: File URL pointing to the pack's location. 
    public init(location: URL) {
        self.location = location
    }
    
    public var title: String {
        get {
            return _title
        }
        set {
            _title = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            titleCommon = StringUtils.toCommon(_title)
            adjustDescription()
        }
    }
    var _title  = ""
    var titleCommon = ""
    
    public var seq: Int {
        get {
            return _seq
        }
        set {
            _seq = newValue
            adjustDescription()
        }
    }
    var _seq = 999
    
    func adjustDescription() {
        if _seq > 99 {
            description = "XX - "
        } else if _seq > 0 {
            description = String(format: "%02d", _seq) + " - "
        } else {
            description = ""
        }
        description.append(title)
    }
    
    public var description: String = ""
    
    /// Populate information about the starter pack. 
    public func loadInfo() {
        
        title = location.lastPathComponent
        
        let infoStarterURL = location.appendingPathComponent(NotenikConstants.infoStarterFileName)
        let infoCollection = NoteCollection(realm: realm)
        infoCollection.path = location.path
        let reader = BigStringReader(fileURL: infoStarterURL)
        if reader == nil {
            communicateError("Error reading Starter Info from \(infoStarterURL)")
        } else {
            let parser = NoteLineParser(collection: infoCollection, reader: reader!)
            let infoNote = parser.getNote(defaultTitle: title, template: false)
            
            title = infoNote.title.value
            
            let seqStr = infoNote.seq.value
            if !seqStr.isEmpty {
                if let seqInt = Int(seqStr) {
                    seq = seqInt
                }
            }
            
            let teaserVal = infoNote.teaser.value
            if !teaserVal.isEmpty {
                teaser = teaserVal
            }
            
            let bodyVal = infoNote.body.value
            if !bodyVal.isEmpty {
                body = bodyVal
            }
        }
        
        projectFolder = false
        let infoURL = location.appendingPathComponent(NotenikConstants.infoFileName)
        if fm.fileExists(atPath: infoURL.path) {
            projectFolder = false
        } else {
            projectFolder = true
        }
    }
    
    public func create(toURL: URL) -> Bool {

        var ok = true
        if projectFolder {
            ok = copyFolders(fromURL: location, toURL: toURL)
            logInfo(msg: "Copying folders")
        } else {
            logInfo(msg: "Relocating Collection")
            let relo = CollectionRelocation()
            ok = relo.copyOrMoveCollection(from: location.path, to: toURL.path, move: false)
        }
        return ok
    }
    
    func copyFolders(fromURL: URL, toURL: URL) -> Bool {
        var ok = FileUtils.ensureFolder(forURL: toURL)
        if ok {
            do {
                let items = try fm.contentsOfDirectory(at: fromURL,
                                                       includingPropertiesForKeys: nil,
                                                       options: .skipsHiddenFiles)
                for item in items {
                    let itemName = item.lastPathComponent
                    guard let toURL = URL(string: itemName, relativeTo: toURL) else { continue }
                    try fm.copyItem(at: item, to: toURL)
                }
            } catch {
                communicateError("Errors copying folder from \(fromURL) to \(toURL)")
                ok = false
            }
        }
        return ok
    }
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "StarterPack",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "StarterPack",
                          level: .error,
                          message: msg)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Conformance to Comparable protocol. 
    //
    // -----------------------------------------------------------
    
    public static func < (lhs: StarterPack, rhs: StarterPack) -> Bool {
        if lhs.seq != rhs.seq {
            return lhs.seq < rhs.seq
        }
        if lhs.titleCommon != rhs.titleCommon {
            return lhs.titleCommon < rhs.titleCommon
        }
        return lhs.title < rhs.title
    }
    
    public static func == (lhs: StarterPack, rhs: StarterPack) -> Bool {
        return lhs.seq == rhs.seq && lhs.title == rhs.title
    }
    
}
