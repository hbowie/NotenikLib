//
//  LevelToClassLookup.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/8/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// If there is a correlation between level values and class values, then lookup the appropriate class for each level.
public class LevelToKlassLookup {
    
    // One array of klass links for each possible level in range 0 - 9
    var links: [[LevelToKlassLink]] = []
    
    /// Add possible level to class link for another  note in the collection. .
    /// - Parameter note: The note to be evaluated.
    public func oneMoreLink(note: Note) {
        
        let (lv, kv) = getLevelAndKlass(note: note)
        guard let levelValue = lv else { return }
        guard let klassValue = kv else { return }
        let level = levelValue.level
        guard level >= 0 && level <= 9 else { return }
        let klass = klassValue.value
        guard !klass.isEmpty else { return }
        while links.count <= level {
            links.append([])
        }
        var j = 0
        while j < links[level].count && links[level][j].klass != klass {
            j += 1
        }
        if j >= links[level].count {
            links[level].append(LevelToKlassLink(klass: klassValue))
        }
        links[level][j].count += 1
    }
    
    /// Remove a possible level to class link for a note being removed or replaced.
    /// - Parameter note: A note being removed or replaced.
    public func oneLessLink(note: Note) {
        
        let (lv, kv) = getLevelAndKlass(note: note)
        guard let levelValue = lv else { return }
        guard let klassValue = kv else { return }
        let level = levelValue.level
        guard level >= 0 && level <= 9 else { return }
        let klass = klassValue.value
        guard !klass.isEmpty else { return }
        guard links.count > level else { return }
        var j = 0
        while j < links[level].count && links[level][j].klass != klass {
            j += 1
        }
        if j < links[level].count {
            links[level][j].count -= 1
        }
    }
    
    /// If the given note has a level and a class, then obtain those values and return them.
    /// - Parameter note: The note from which the values should be extracted.
    /// - Returns: The note/s level and class values, if they both exist, otherwise nil for both.
    func getLevelAndKlass(note: Note) -> (LevelValue?, KlassValue?) {
        guard !note.collection.readOnly else {
            return (nil, nil)
        }
        guard let levelDef = note.collection.levelFieldDef else {
            return (nil, nil)
        }
        guard let klassDef = note.collection.klassFieldDef else {
            return (nil, nil)
        }
        guard let levelField = note.getField(def: levelDef) else {
            return (nil, nil)
        }
        guard let klassField = note.getField(def: klassDef) else {
            return (nil, nil)
        }
        guard let levelValue = levelField.value as? LevelValue else {
            return (nil, nil)
        }
        guard let klassValue = klassField.value as? KlassValue else {
            return (nil, nil)
        }
        return (levelValue, klassValue)
    }
    
    /// If there is an apparent correlation between level values and class values,
    /// then return the appropriate class for the given level.
    /// - Parameter level: The level for which we are seeking a corresponding class.
    /// - Returns: The corresponding class, if any, otherwise nil.
    public func klassForLevel(_ level: Int) -> String? {
        guard level >= 0 && level < links.count else {
            return nil
        }
        guard links[level].count > 0 else {
            return nil
        }
        if links[level].count > 1 {
            links[level].sort()
        }
        let klass = links[level][0].klass
        if links[level].count > 1 && links[level][1].count > 2 {
            return nil
        }
        var multiple = 0
        for i in 1..<links.count {
            if i != level {
                if links[i].count > 0 {
                    if klass == links[i][0].klass {
                        multiple += 1
                    }
                }
            }
        }
        if multiple > 0 {
            return nil
        }
        return klass
    }
}
