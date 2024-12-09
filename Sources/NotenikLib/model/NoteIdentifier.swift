//
//  NoteIdentifier.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/12/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// This is the class that populates the Note Identification. 
public class NoteIdentifier {
    
    public  var uniqueIdRule:  NoteIdentifierRule = .titleOnly
    public  var noteIdAuxField = ""
    public  var textIdRule:    NoteIdentifierRule = .titleOnly
    public  var textIdSep      = ""
    
    public init() {
        
    }
    
    public func identify(note: Note, noteID: NoteIdentification) {
        
        noteID.seqBeforeTitle = false
        
        var seqFieldFirst = false
        
        // Get the auxiliary field value, if one has been identified.
        var aux = ""
        if !noteIdAuxField.isEmpty {
            if let field = note.getField(label: noteIdAuxField) {
                aux = field.value.valueToWrite()
                if field.def.fieldType.typeString == NotenikConstants.seqCommon {
                    seqFieldFirst = true
                }
            }
        }
        
        // Generate the basis to be used for internal identification.
        switch uniqueIdRule {
        case .titleOnly:
            noteID.basis = note.title.value
        case .titleBeforeAux:
            if aux.isEmpty {
                noteID.basis = note.title.value
            } else {
                noteID.basis = note.title.value + " " + aux
            }
        case .titleAfterAux:
            if aux.isEmpty {
                noteID.basis = note.title.value
            } else {
                noteID.basis = aux + " " + note.title.value
            }
        case .auxOnly:
            noteID.basis = aux
        }
        
        // Generate the text to be used to identify the note to the user.
        switch textIdRule {
        case .titleOnly:
            noteID.text = note.title.value
        case .titleBeforeAux:
            if aux.isEmpty {
                noteID.text = note.title.value
            } else if textIdSep.isEmpty {
                noteID.text = note.title.value + " " + aux
            } else {
                noteID.text = note.title.value + textIdSep + aux
            }
        case .titleAfterAux:
            if aux.isEmpty {
                noteID.text = note.title.value
            } else {
                if textIdSep.isEmpty {
                    noteID.text = aux + " " + note.title.value
                } else {
                    noteID.text = aux + textIdSep + note.title.value
                }
                if seqFieldFirst {
                    noteID.seqBeforeTitle = true
                }
            }
        case .auxOnly:
            noteID.text = aux
        }
        
        if note.collection.textFormatFieldDef != nil && note.textFormat.isText {
            noteID.plainText = true
            noteID.preferredExt = NotenikConstants.textFormatTxt
        } else {
            noteID.preferredExt = note.collection.preferredExt
        }
        
        // Now derive all variations of the note identifiers.
        noteID.deriveIdentifiers()
    }
    
}
