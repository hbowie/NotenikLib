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
    var name = ""
    var kind = "individual"
    var nickname = ""
    var org = ""
    var jobTitle = ""
    var birthday = ""
    var emails: [QualifiedValue] = []
    var phones: [QualifiedValue] = []
    var adrs:   [QualifiedValue] = []
    var url = ""
    var body = ""
    
    /// Initialize a new instance.
    public init() {

    }
    
    /// Parse the vCard file at the given URL, returning a stack of Notes.
    public func parse(vCards: URL, collection: NoteCollection) -> [Note] {
        self.collection = collection
        dict = collection.dict
        guard let rdr = BigStringReader(fileURL: vCards) else { return [] }
        reader = rdr
        parse()
        return createdNotes
    }
    
    /// Parse the passed text, and return a stack of Notes.
    public func parse(_ text: String, collection: NoteCollection) -> [Note] {
        reader = BigStringReader(text)
        self.collection = collection
        dict = collection.dict
        parse()
        return createdNotes
    }
    
    /// Import the vCard file at the tiven URL, adding or updating the contacts found, and return the number of
    /// vCards found.
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
    
    /// Parse the vCard text, creating Notes and stacking them up.
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
            
    /// Process what appears to be a normal vCard line.
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
    
    /// Clear out the fields to be extracted.
    func clearCardData() {
        version = ""
        fullName = ""
        name = ""
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
    
    /// Process a normal line, containing both a label and some data.
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
            let anotherAddress = QualifiedValue()
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
            for email in emails {
                if data.lowercased() == email.data.lowercased() {
                    return
                }
            }
            let anotherEmail = QualifiedValue()
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
            if fullName.contains(" family") || fullName.contains(" and ") || fullName.contains(" & ") {
                kind = "family"
            }
        case "N":
            name = data
        case "NICKNAME":
            nickname = data
        case "NOTE":
            body = data
        case "ORG":
            org = data
        case "TEL":
            let anotherPhone = QualifiedValue()
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
    
    /// Process (or ignore) extra data.
    func extraData(line: String) {
        
    }
    
    /// Once we hit the end of a card, process the fields we've saved.
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
    
    /// Update the given note using the saved fields from one vCard.
    func updateNote(note: Note) {
        _ =  note.setTitle(unescape(fullName))
        if name != ";;;;" {
            updateNoteField(note: note, label: "Name", value: name)
        }
        updateNoteField(note: note, label: "Nickname", value: nickname)
        updateNoteField(note: note, label: "Organization", value: unescape(org))
        updateNoteField(note: note, label: "Kind", value: kind)
        updateNoteField(note: note, label: "Job Title", value: unescape(jobTitle))
        updateNoteField(note: note, label: "Birthday", value: birthday)
        updateNoteField(note: note, label: NotenikConstants.link, value: url)
        
        var emailCount = 0
        for email in emails {
            emailCount += 1
            var label = "Email"
            if emailCount > 1 {
                label = "Email-\(emailCount)"
            }
            updateNoteField(note: note, label: label, value: email.data)
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
            _ = note.setBody(unescape(body))
        }
    }
    
    func unescape(_ input: String) -> String {
        var str = input
        var i = str.startIndex
        var lastChar: Character = " "
        var lastCharIndex = str.startIndex
        var backSlashes: [String.Index] = []
        for char in str {
            if lastChar == "\\" {
                if char == ";" || char == "," {
                    backSlashes.append(lastCharIndex)
                }
            }
            lastChar = char
            lastCharIndex = i
            i = str.index(after: i)
        }
        var j = backSlashes.count
        while j > 0 {
            j -= 1
            str.remove(at: backSlashes[j])
        }
        let lines = str.components(separatedBy: "\\n")
        var output = ""
        for line in lines {
            if !output.isEmpty {
                output.append("\n")
            }
            output.append(String(line))
        }
        return output
    }
    
    /// Update a single note field, using the passed label and data.
    func updateNoteField(note: Note, label: String, value: String) {
        
        guard !value.isEmpty else { return }
        
        var def: FieldDefinition? = collection.dict.getDef(label)
        var family: String? = nil
        if def == nil {
            (def, family) = genFieldDef(label: label)
            if def != nil {
                _ = dict.addDef(def!, family: family)
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
        } else if def!.fieldType.typeString == NotenikConstants.personCommon {
            let pv = PersonValue()
            pv.setFromVcardName(name: value)
            val = pv
        } else {
            val = def!.fieldType.createValue(value)
        }
        let field = NoteField(def: def!, value: val)
        _ = note.setField(field)
    }
    
    /// If the field dictionary doesn't yet contain a definition for this field label, then let's generate one.
    func genFieldDef(label: String) -> (FieldDefinition, String?) {
        let def = FieldDefinition(typeCatalog: collection.typeCatalog, label: label)
        var family: String? = nil
        switch label {
        case "Birthday":
            def.fieldType = DateType()
        case "Kind":
            def.fieldType = PickListType()
            def.pickList = PickList(values: "family, individual, group, org",
                                    forceLowercase: true,
                                    allowBlanks: false)
        case "Name":
            def.fieldType = PersonType()
        default:
            if def.fieldLabel.commonForm.starts(with: "email") && def.fieldLabel.commonForm.count > 5 {
                def.fieldType = EmailType()
                family = "email"
            }
        }
        return (def, family)
    }
    
    /// Go through the created Notes, and update the Collection with them.
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
    
    /// Add a new note to the collection.
    func addNew(_ newNote: Note) {
        (_, _) = noteIO.addNote(newNote: newNote)
    }
        
    /// Update an existing Note from the Collection.
    func updateExisting(existingNote: Note, createdNote: Note) {
        var updatedNote: Note? = Note(collection: collection)
        updatedNote = existingNote.copy() as? Note
        guard updatedNote != nil else { return }
        createdNote.copyFields(to: updatedNote!, copyBlanks: false)
        _ = noteIO.modNote(oldNote: existingNote, newNote: updatedNote!)
    }
    
    /// Contains some data with associated qualifiers.
    class QualifiedValue {
        var qualifiers: [String] = []
        var data = ""
    }
    
}
