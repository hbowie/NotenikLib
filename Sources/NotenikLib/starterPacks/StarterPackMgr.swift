//
//  StarterPackMgr.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/23/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).

import Foundation

import NotenikUtils

public class StarterPackMgr {
    
    public var starterPacks: [StarterPack] = []
    var highestSeq = 0
    
    public var firstUsePack: StarterPack?
    
    public init() {
        
    }
    
    public func load(fromFolder: URL) {
        do {
            let starters = try FileManager.default.contentsOfDirectory(at: fromFolder,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for starter in starters {
                _ = addStarterPack(location: starter)
            }
        } catch {
            communicateError("Could not read any starter packs from \(fromFolder)")
        }
        
        starterPacks.sort()
    }
    
    public func addStarterPack(location: URL) -> StarterPack? {
        
        let newPack = StarterPack(location: location)
        newPack.loadInfo()
        if location.lastPathComponent == "XX - First Use" {
            firstUsePack = newPack
            return newPack
        }
        if newPack.seq > highestSeq && newPack.seq <= 99 {
            highestSeq = newPack.seq
        } else if newPack.seq == 0 || newPack.seq >= 99 {
            highestSeq += 1
            newPack.seq = highestSeq
        }
        starterPacks.append(newPack)
        return newPack
    }
    
    public func get(description: String) -> StarterPack? {
        for pack in starterPacks {
            if pack.description == description {
                return pack
            }
        }
        return nil
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "StarterPackMgr",
                          level: .error,
                          message: msg)
    }
}

