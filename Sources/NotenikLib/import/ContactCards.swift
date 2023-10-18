//
//  ContactCards.swift
//  NotenikLib
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 10/12/23.
//

import Foundation

import NotenikUtils

/// Utility object to manipulate vCards.
public class ContactCards {
    
    var noteIO:     NotenikIO!
    var collection: NoteCollection!
    var dict:       FieldDictionary!
    var lockedValue = true
    
    var reader: LineReader!
    
    var createdNotes: [Note] = []
    
    let errorCount = -1
    var vCardBegun = false
    var version = ""
    var fullName = ""
    var kind = "individual"
    var nickname = ""
    var org = ""
    var jobTitle = ""
    var birthday = ""
    var emails: [qualifiedValue] = []
    var phones: [qualifiedValue] = []
    var adrs:   [qualifiedValue] = []
    var url = ""
    var body = ""
    
    /// Initialize a new instance.
    public init() {

    }
    
    public func parse(vCards: URL, collection: NoteCollection) -> [Note] {
        self.collection = collection
        dict = collection.dict
        guard let rdr = BigStringReader(fileURL: vCards) else { return [] }
        reader = rdr
        parse()
        return createdNotes
    }
    
    public func parse(_ text: String, collection: NoteCollection) -> [Note] {
        reader = BigStringReader(text)
        self.collection = collection
        dict = collection.dict
        parse()
        return createdNotes
    }
    
    public func importCards(vCards: URL, noteIO: NotenikIO) -> Int {
        
        self.noteIO = noteIO
        guard let clctn = noteIO.collection else { return errorCount }
        collection = clctn
        dict = collection.dict
        
        if let rdr = BigStringReader(fileURL: vCards) {
            reader = rdr
            parse()
        } else {
            return errorCount
        }
        
        applyUpdates()
        noteIO.persistCollectionInfo()
        return createdNotes.count
    }
    
    func parse() {
        
        lockedValue = dict.locked
        dict.locked = false
        
        vCardBegun = false
        clearCardData()
        createdNotes = []
        reader.open()
        var line: String? = reader.readLine()
        while line != nil {
            if !line!.isEmpty {
                if line!.starts(with: " ") {
                    extraData(line: line!)
                } else {
                    normalLine(line: line!)
                }
            }
            line = reader.readLine()
        }
        reader.close()
        
        dict.locked = lockedValue
    }
            
    func normalLine(line: String) {
        let lineSplits = line.split(separator: ":")
        guard lineSplits.count >= 2 else { return }
        let label = String(lineSplits[0])
        var data = ""
        var i = 1
        while i < lineSplits.count {
            if i >= 2 {
                data.append(":")
            }
            data.append(String(lineSplits[i]))
            i += 1
        }
        labelWithData(label: label, data: data)
    }
    
    func clearCardData() {
        version = ""
        fullName = ""
        kind = "individual"
        nickname = ""
        org = ""
        jobTitle = ""
        birthday = ""
        url = ""
        emails = []
        phones = []
        adrs = []
        body = ""
    }
    
    func labelWithData(label: String, data: String) {
        let labelSplits = label.split(separator: ";")
        guard !labelSplits.isEmpty else { return }
        let itemLabel = String(labelSplits[0])
        var mainLabel = itemLabel
        let itemSplits = itemLabel.components(separatedBy: ".")
        if itemSplits.count == 2 && itemSplits[0].starts(with: "item") {
            mainLabel = itemSplits[1]
        }
        switch mainLabel {
        case "ADR":
            let anotherAddress = qualifiedValue()
            var i = 1
            while i < labelSplits.count {
                anotherAddress.qualifiers.append(String(labelSplits[i]))
                i += 1
            }
            anotherAddress.data = data
            adrs.append(anotherAddress)
        case "BEGIN":
            if data == "VCARD" {
                vCardBegun = true
                clearCardData()
            }
        case "BDAY":
            birthday = data
        case "EMAIL":
            let anotherEmail = qualifiedValue()
            var i = 1
            while i < labelSplits.count {
                anotherEmail.qualifiers.append(String(labelSplits[i]))
                i += 1
            }
            anotherEmail.data = data
            emails.append(anotherEmail)
        case "END":
            if data == "VCARD" {
                finishCard()
                vCardBegun = false
            }
        case "FN":
            fullName = data
        case "NICKNAME":
            nickname = data
        case "NOTE":
            body = data
        case "ORG":
            org = data
        case "TEL":
            let anotherPhone = qualifiedValue()
            var i = 1
            while i < labelSplits.count {
                anotherPhone.qualifiers.append(String(labelSplits[i]))
                i += 1
            }
            anotherPhone.data = data
            phones.append(anotherPhone)
        case "TITLE":
            jobTitle = data
        case "URL":
            url = data
        case "VERSION":
            version = data
        case "X-ABShowAs":
            if data == "COMPANY" {
                kind = "org"
            }
        default:
            break
        }
    }
    
    func extraData(line: String) {
        
    }
    
    func finishCard() {
        guard vCardBegun else { return }
        guard !fullName.isEmpty else { return }
        
        var noteToUpdate: Note?
        noteToUpdate = Note(collection: collection)
        
        // Now apply the info from the scan.
        if noteToUpdate != nil {
            updateNote(note: noteToUpdate!)
        }
        
        createdNotes.append(noteToUpdate!)
    }
    
    func updateNote(note: Note) {
        _ =  note.setTitle(fullName)
        updateNoteField(note: note, label: "Nickname", value: nickname)
        updateNoteField(note: note, label: "Organization", value: org)
        updateNoteField(note: note, label: "Kind", value: kind)
        updateNoteField(note: note, label: "Job Title", value: jobTitle)
        updateNoteField(note: note, label: "Birthday", value: birthday)
        updateNoteField(note: note, label: NotenikConstants.link, value: url)
        if !emails.isEmpty {
            if emails.count == 1 {
                updateNoteField(note: note, label: NotenikConstants.email, value: emails[0].data)
            }
        }
        if !phones.isEmpty {
            if phones.count == 1 {
                updateNoteField(note: note, label: NotenikConstants.phone, value: phones[0].data)
            }
        }
        if !adrs.isEmpty {
            if adrs.count == 1 {
                updateNoteField(note: note, label: NotenikConstants.address, value: adrs[0].data)
            }
        }
        if !body.isEmpty {
            var i = body.startIndex
            var lastChar: Character = " "
            var lastCharIndex = body.startIndex
            var backSlashes: [String.Index] = []
            for char in body {
                if lastChar == "\\" {
                    if char == ";" || char == "," {
                        backSlashes.append(lastCharIndex)
                    }
                }
                lastChar = char
                lastCharIndex = i
                i = body.index(after: i)
            }
            var j = backSlashes.count
            while j > 0 {
                j -= 1
                body.remove(at: backSlashes[j])
            }
            let bodyLines = body.components(separatedBy: "\\n")
            var bodyWithNewlines = ""
            for line in bodyLines {
                bodyWithNewlines.append(String(line))
                bodyWithNewlines.append("\n")
            }
            _ = note.setBody(bodyWithNewlines)
        }
    }
    
    func updateNoteField(note: Note, label: String, value: String) {
        guard !value.isEmpty else { return }
        var def: FieldDefinition? = collection.dict.getDef(label)
        if def == nil {
            def = genFieldDef(label: label)
            if def != nil {
                _ = dict.addDef(def!)
            }
        }
        guard def != nil else { return }
        var val = StringValue()
        if (def!.fieldType.typeString == NotenikConstants.pickFromType
                && def!.pickList != nil) {
            let pickListValue = def!.fieldType.createValue() as! PickListValue
            pickListValue.pickList = def!.pickList!
            pickListValue.set(value)
            val = pickListValue
        } else {
            val = def!.fieldType.createValue(value)
        }
        let field = NoteField(def: def!, value: val)
        _ = note.setField(field)
    }
    
    func genFieldDef(label: String) -> FieldDefinition {
        let def = FieldDefinition(typeCatalog: collection.typeCatalog, label: label)
        switch label {
        case "Birthday":
            def.fieldType = DateType()
        case "Kind":
            def.fieldType = PickListType()
            def.pickList = PickList(values: "family, individual, group, org",
                                    forceLowercase: true,
                                    allowBlanks: false)
        default:
            break
        }
        return def
    }
    
    func applyUpdates() {
        for vNote in createdNotes {
            let existingNote = noteIO.getNote(knownAs: vNote.title.value)
            if existingNote == nil {
                addNew(vNote)
            } else {
                updateExisting(existingNote: existingNote!, createdNote: vNote)
            }
        }
    }
    
    func addNew(_ newNote: Note) {
        (_, _) = noteIO.addNote(newNote: newNote)
    }
        
    func updateExisting(existingNote: Note, createdNote: Note) {
        var updatedNote: Note? = Note(collection: collection)
        updatedNote = existingNote.copy() as? Note
        guard updatedNote != nil else { return }
        createdNote.copyFields(to: updatedNote!, copyBlanks: false)
        _ = noteIO.modNote(oldNote: existingNote, newNote: updatedNote!)
    }
    
    class qualifiedValue {
        var qualifiers: [String] = []
        var data = ""
    }
    
}
