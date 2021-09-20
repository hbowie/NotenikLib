//
//  FieldGrabber.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/23/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A utility class that can be used to grab a field from a Note or one of its referenced Notes. 
public class FieldGrabber {
    
    /// Get the Note Field for a particular label
    public static func getField (note: Note, label: String) -> NoteField? {
        let fieldLabel = FieldLabel(label)
        let field = note.fields[fieldLabel.commonForm]
        if field != nil { return field }
        return tryLookupFields(note: note, label: fieldLabel)
    }
    
    public static func tryLookupFields(note: Note, label: FieldLabel) -> NoteField? {
        for (_, field) in note.fields {
            guard field.def.fieldType is LookupType else { continue }
            guard !field.def.lookupFrom.isEmpty else { continue }
            guard field.value.hasData else { continue }
            let id = StringUtils.toCommon(field.value.value)
            let lookupNote = MultiFileIO.shared.getNote(shortcut: field.def.lookupFrom, forID: id)
            guard lookupNote != nil else { continue }
            let field = getField(note: lookupNote!, label: label.commonForm)
            guard field != nil else { continue }
            // print("FieldGrabber.lookupField returned label = \(label.properForm), value = \(field!.value.value)")
            return field
        }
        return nil
    }
}
