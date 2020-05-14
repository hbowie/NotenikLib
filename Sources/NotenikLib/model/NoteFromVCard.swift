//
//  NoteFromVCard.swift
//
//  Created by Herb Bowie on 5/14/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class NoteFromVCard {
    
    public static func makeNote(from vcard: VCard, collection: NoteCollection) -> Note {
        let note = Note(collection: collection)
        _ = note.setTitle(vcard.fullName)
        let email = vcard.primaryEmail
        if email.count > 0 {
            _ = note.setLink("mailto:\(email)")
        }
        let org = vcard.org
        if org.count > 0 {
            _ = note.setField(label: "Org", value: org)
        }
        return note
    }
    
}
