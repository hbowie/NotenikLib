//
//  ShortIDs.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/25/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Collection of short IDs.
class ShortIDs {
    
    var shortIDs:    [String: String] = [:]
    
    init() {
        
    }
    
    /// Add a Short ID entry for another Note. If the Note doesn't already
    /// have a Short ID, generate one. It it has one that is not unique,
    /// then generate a new one.
    func add(note: Note) {
        var shortID = ""
        if note.hasShortID() {
            shortID = note.shortID.value
        } else {
            shortID = new(for: note.title.value)
            _ = note.setShortID(shortID)
        }
        let storedTitle = shortIDs[shortID]
        if storedTitle == nil {
            shortIDs[shortID] = note.title.value
        } else if storedTitle == note.title.value {
            // This Note has already been stored
        } else {
            shortID = new(for: note.title.value)
            shortIDs[shortID] = note.title.value
            _ = note.setShortID(shortID)
        }
    }
    
    /// Remove this Note's Short ID from the Collection. 
    func delete(note: Note) {
        if note.hasShortID() {
            let shortID = note.shortID.value
            shortIDs[shortID] = nil
        }
    }
    
    /// Attempt to add the given combination of shortID and title to the collection,
    /// returning true if successful, and returning false if the given Short ID is already
    /// in the Collection, but associated with a different Title.
    func add(shortID: String, title: String) -> Bool {
        let existingTitle = getTitle(for: shortID)
        if existingTitle == nil {
            shortIDs[shortID] = title
            return true
        } else if existingTitle! == title {
            return true
        } else {
            return false
        }
    }
    
    /// Get the title for a given short ID.
    /// - Parameter shortID: The Short ID of interest.
    /// - Returns: The title, if an entry exists in the Collection;
    ///            nil if no entry exists.
    func getTitle(for shortID: String) -> String? {
        return shortIDs[shortID]
    }
    
    /// Calculate a new Short ID for a given title. 
    func new(for title: String) -> String {
        var words: [String] = []
        
        // Break the title up into its constituent words.
        var word = ""
        for char in title {
            if char.isWhitespace || char.isPunctuation {
                if char == "'" && word.count > 0 {
                    // Skip apostrophes
                } else {
                    if goodWord(word: word) {
                        words.append(word)
                    }
                    word = ""
                }
            } else {
                word.append(char.lowercased())
            }
        }
        if goodWord(word: word) {
            words.append(word)
        }
        
        // Now figure out a unique short ID.
        var idLength = words.count
        if idLength < 4 {
            idLength = 4
        } else if idLength > 8 {
            idLength = 8
        }
        var unique = false
        var shortID = ""
        var shortage = 0
        
        // Gradually increase the ID length until we have a unique iD.
        while !unique {
            let charsPerWord = idLength / words.count
            let leftOver = idLength % words.count
            shortID = ""
            var wordIx = 0
            for word in words {
                var charsToTake = charsPerWord + shortage
                if wordIx < leftOver {
                    charsToTake += 1
                }
                var charsTaken = 0
                for char in word {
                    shortID.append(char)
                    charsTaken += 1
                    if charsTaken >= charsToTake || shortID.count >= idLength {
                        break
                    }
                }
                shortage = charsToTake - charsTaken
                wordIx += 1
                if shortID.count >= idLength {
                    break
                }
            }
            shortage = idLength - shortID.count
            if shortIDs[shortID] == nil {
                unique = true
            } else if shortage == 0 {
                idLength += 1
            }
        }
        return shortID
    }
    
    func goodWord(word: String) -> Bool {
        guard word.count > 0 else { return false }
        switch word {
        case "a":   return false
        case "an":  return false
        case "and": return false
        case "are": return false
        case "as":  return false
        case "at":  return false
        case "for": return false
        case "is":  return false
        case "its": return false
        case "of":  return false
        case "our": return false
        case "the": return false
        case "to":  return false
        case "we":  return false
        default:    return true
        }
    }
    
}
