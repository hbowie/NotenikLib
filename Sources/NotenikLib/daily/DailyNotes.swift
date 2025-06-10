//
//  DailyNotes.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/6/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class DailyNotes {
    
    /// Return date and time for use in identifying a note and, optionally, a folder.
    /// - Returns: Date first, then time of day.
    public static func now() -> (String, String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd EEEE"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let now = Date()
        return (dateFormatter.string(from: now), timeFormatter.string(from: now))
    }
    
    public static func applyDateAndTime(to note: Note) {
        switch note.collection.dailyNotesType {
        case .none:
            return
        case .folders:
            let (date, time) = now()
            _ = note.setFolder(str: date)
            _ = note.setSeq(time)
        case .notes:
            if note.title.isEmpty {
                let (date, _) = now()
                _ = note.setTitle(date)
            }
        }
    }
    
}
