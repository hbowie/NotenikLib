//
//  SortedNote.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/19/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class SortedNote: Comparable {
    
    public var sortKey:  String
    public var note:     Note
    public var seqIndex: Int
    
    public var original: Bool {
        return seqIndex < 1
    }
    
    public var phantom: Bool {
        return seqIndex > 0
    }
    
    public init(note: Note, seqIndex: Int = 0) {
        self.note = note
        self.seqIndex = seqIndex
        sortKey = note.genSortKey(seqIndex: seqIndex)
    }
    
    /// Set the Note's Sequence value
    public func setSeq(_ seq: String) -> Bool {
        let ok = note.setSeq(seq)
        genSortKey()
        return ok
    }
    
    /// Set the Note's Sequence value
    public func setSingleSeq(_ newSeqStr: String) -> Bool {
        guard note.collection.seqFieldDef != nil else { return false }
        let seq = note.seq
        var ok = seq.setSingleSeq(newSeqStr, seqIndex: seqIndex)
        if !ok { return ok }
        ok = note.setSeq(seq.multiConcat)
        genSortKey()
        return ok
    }
    
    public func genSortKey() {
        sortKey = note.genSortKey(seqIndex: seqIndex)
    }
    
    /// Make a deep copy of this SortedNote
    public func copy() -> SortedNote {
        let newNote = note.copy() as! Note
        let newSorted = SortedNote(note: newNote, seqIndex: seqIndex)
        return newSorted
    }
    
    public static func < (lhs: SortedNote, rhs: SortedNote) -> Bool {
        if lhs.note.collection.sortParm == .custom {
            return Note.compareCustomFields(lhs: lhs.note, rhs: rhs.note) < 0
        } else if lhs.collection.sortDescending {
            return lhs.sortKey > rhs.sortKey
        } else {
            return lhs.sortKey < rhs.sortKey
        }
    }
    
    public static func == (lhs: SortedNote, rhs: SortedNote) -> Bool {
        return rhs.sortKey == lhs.sortKey
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Some convenience pass-through variables.
    //
    // -----------------------------------------------------------
    
    public var collection: NoteCollection {
        return note.collection
    }
    
    public var noteID: NoteIdentification {
        return note.noteID
    }
    
    public var noteIDstr: String {
        return note.noteID.id
    }
    
    public var isDone: Bool {
        return note.isDone
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Various ways to return and format seq values 
    //
    // -----------------------------------------------------------
    
    /// Get the title of the Note as a String, optionally preceded by the Note's Seq value.
    /// - Parameters:
    ///   - withSeq: Should the returned value be prefixed by the Note's Seq value? If the Note has no Seq value,
    ///   or if its class/klass indicates it should be treated as front matter or back matter, then a True value here
    ///   will have no effect.
    ///   - sep: The separator to place between the Seq and the Title. Defaults to a single space.
    /// - Returns: The title of the Note, optionally preceded by a Seq value.
    public func getTitle(withSeq: Bool = false, formattedSeq: Bool = false, full: Bool = false, sep: String = " ") -> String {
        if withSeq && note.hasSeq() && !note.klass.frontOrBack {
            if formattedSeq || full {
                return getFormattedSeqForDisplay(full: full) + sep + note.title.value
            } else {
                return seqSingleValue.value + sep + note.title.value
            }
        } else {
            return note.title.value
        }
    }
    
    public func getFormattedSeqForDisplay(full: Bool = false) -> String {
        if note.hasDisplaySeq() {
            return note.formattedDisplaySeq
        } else {
            return getFormattedSeq(seqIndex: seqIndex, full: full)
        }
    }
    
    /// Return a value that can be used as a key to compare sequence values.
    public var seqSortKey: String {
        return seqSingleValue.sortKey
    }
    
    /// Return the Note's Sequence Value
    public var seqSingleValue: SeqSingleValue {
        guard let seqFieldDef = note.collection.seqFieldDef else {
            return emptySingle
        }
        let val = note.getFieldAsValue(def: seqFieldDef)
        if let seqValue = val as? SeqValue {
            if let singleSeq = seqValue.getSingleSeq(seqIndex: seqIndex) {
                return singleSeq
            }
        }
        return emptySingle
    }
    
    var emptySingle: SeqSingleValue {
        let seqParms = SeqParms()
        let seqSingleValue = SeqSingleValue(seqParms: seqParms)
        return seqSingleValue
    }
    
    /// Return a derived depth, using level, if available, otherwise seq depth, if available,
    /// otherwise 1.
    public var depth: Int {
        
        // Use level, if we have it
        if let levelDef = note.collection.levelFieldDef {
            if let levelField = note.fields[levelDef.fieldLabel.commonForm] {
                if let levelValue = levelField.value as? LevelValue {
                    let config = note.collection.levelConfig
                    let level = levelValue.getInt()
                    if level >= config.low && level <= config.high {
                        return level
                    }
                }
            }
        }
        
        // If no level, derive from Seq field.
        if note.collection.seqFieldDef != nil {
            let seqSingle = seqSingleValue
            let seqDepth = seqSingle.numberOfLevels
            if seqDepth >= 1 {
                return seqDepth
            }
        }
        
        return 1
    }
    
    public func getFormattedSeq(full: Bool = false) -> String {
        return getFormattedSeq(seqIndex: seqIndex, full: full)
    }
    
    /// Return a formatted Seq, basec on Collection prefs
    public func getFormattedSeq(seqIndex: Int, full: Bool = false) -> String {
        
        guard collection.seqFieldDef != nil else { return "" }
        
        guard let seqValue = note.getFieldAsValue(def: collection.seqFieldDef!) as? SeqValue else { return "" }
        guard let singleSeq = seqValue.getSingleSeq(seqIndex: seqIndex) else { return "" }

        let (formatted, _) = collection.seqFormatter.format(seq: singleSeq, klassDef: note.klassDef, full: full)
        return formatted
    }
    
    public var seqAsTimeOfDay: SeqSingleValue {
        var val: StringValue!
        if collection.seqTimeOfDayFieldDef != nil {
            val = note.getFieldAsValue(def: collection.seqTimeOfDayFieldDef!)
        } else if collection.seqFieldDef != nil {
            val = note.getFieldAsValue(def: collection.seqFieldDef!)
        } else {
            val = SeqValue(seqParms: SeqParms())
        }
        if val is SeqValue {
            if let singleVal = (val as! SeqValue).getSingleSeq(seqIndex: seqIndex) {
                return singleVal
            }
        }
        return SeqSingleValue(seqParms: SeqParms())
    }
}
