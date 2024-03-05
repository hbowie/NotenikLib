//
//  Note.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// A single Note. 
public class Note: CustomStringConvertible, Comparable, Identifiable, NSCopying {
    
    public var collection: NoteCollection
    
    public var fields = [:] as [String: NoteField]
    public var attachments: [AttachmentName] = []
    
    public var noteID = NoteIdentification()
    
    public var id: String {
        return noteID.commonID
    }
    
    var _envCreateDate = ""
    var _envModDate    = ""
    
    // public var fileInfo: NoteFileInfo!
    
    public var mkdownCommandList = MkdownCommandList(collectionLevel: false)
    
    /// Initialize with a Collection
    public init (collection: NoteCollection) {
        self.collection = collection
        noteID.setNoteFileFormat(newFormat: collection.noteFileFormat)
        noteID.setPreferredExt(collection.preferredExt)
        applyDefaults()
    }
    
    func applyDefaults() {
        guard !collection.klassDefs.isEmpty else { return }
        for klassDef in collection.klassDefs {
            if klassDef.name == NotenikConstants.defaultsKlass {
                if let defaults = klassDef.defaultValues {
                    for (_, field) in defaults.fields {
                        if !field.value.value.isEmpty {
                            if field.def.shouldInitFromKlassTemplate {
                                _ = setField(label: field.def.fieldLabel.properForm, value: field.value.value)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Generate identifiers for the Note.
    /// - Returns: True if the note's unique id changed. 
    public func identify() {
        collection.noteIdentifier.identify(note: self, noteID: noteID)
    }
    
    /// Should this Note be excluded from a web book being generated?
    /// - Parameter epub: Is this an EPUB web book?
    /// - Returns: True if the Note should be excluded.
    public func excludeFromBook(epub: Bool) -> Bool {
        if klass.exclude { return true }
        if mkdownCommandList.contentPage { return false }
        if mkdownCommandList.search && epub { return true }
        return true
    }
    
    /// Should this Note be included in a web book being generated?
    /// - Parameter epub: Is this an EPUB web book?
    /// - Returns: True if the Note should be included.
    public func includeInBook(epub: Bool) -> Bool {
        if klass.exclude { return false }
        if mkdownCommandList.contentPage { return true }
        if mkdownCommandList.search && !epub { return true }
        return false
    }
    
    public var treatAsTitlePage: Bool {
        if klass.value == NotenikConstants.titleKlass { return true }
        if collection.klassFieldDef != nil { return false }
        if level.level > 1 { return false }
        if level.label.lowercased().contains("title") { return true }
        return false
    }
    
    public var dateAddedValue: String {
        if collection.dateAddedFieldDef == nil {
            return envCreateDate
        } else {
            return getFieldAsValue(def: collection.dateAddedFieldDef!).value
        }
    }
    
    public var dateAddedSortKey: String {
        if collection.dateAddedFieldDef == nil {
            return envCreateDate
        } else {
            return getFieldAsValue(def: collection.dateAddedFieldDef!).sortKey
        }
    }
    
    /// The note's creation date, as reported from the note's environment (file system, etc.)
    var envCreateDate: String {
        get {
            return _envCreateDate
        }
        set {
            _envCreateDate = newValue
            let dateAddedDef = collection.dict.getDef(NotenikConstants.dateAdded)
            if dateAddedDef != nil {
                let dateAddedField = fields[dateAddedDef!.fieldLabel.commonForm]
                if dateAddedField == nil {
                    _ = setDateAdded(newValue)
                }
            }
            let timestampDef = collection.dict.getDef(NotenikConstants.timestamp)
            if timestampDef != nil {
                if !self.contains(label: NotenikConstants.timestamp) {
                    let timestamp = TimestampValue(newValue)
                    let timestampField = NoteField(def: timestampDef!, value: timestamp)
                    fields[timestampDef!.fieldLabel.commonForm] = timestampField
                }
            }
        }
    }
    
    var envModDate: String {
        get {
            return _envModDate
        }
        set {
            _envModDate = newValue
            let dateModifiedDef = collection.dict.getDef(NotenikConstants.dateModified)
            if dateModifiedDef != nil {
                let dateModifiedField = fields[dateModifiedDef!.fieldLabel.commonForm]
                if dateModifiedField == nil {
                    _ = setDateModified(newValue)
                } else {
                    if let dateModifiedValue = dateModifiedField!.value as? DateTimeValue {
                        let dateModNewValue = DateTimeValue(newValue)
                        if dateModifiedValue.value.count == 0
                            || dateModNewValue > dateModifiedValue {
                            _ = setDateModified(newValue)
                        }
                    }
                }
            }
        }
    }
    
    /// See if the supplied sort key is greater than the sort key for this Note.
    /// - Parameter str: A sort key for comparison.
    /// - Returns: True if the supplied key is greater than this Note's.
    public func sortKeyGreaterThan(_ str: String) -> Bool {
        if collection.sortDescending {
            return str > sortKey
        } else {
            return sortKey > str
        }
    }
    
    /// See if the supplied sort key is less than the sort key for this Note.
    /// - Parameter str: A sort key for comparison.
    /// - Returns: True if the supplied key is less than this Note's.
    public func sortKeyLessThan(_ str: String) -> Bool {
        if collection.sortDescending {
            return str < sortKey
        } else {
            return sortKey < str
        }
    }
    
    
    /// See if the supplied sort key is equal to this Note's.
    /// - Parameter str: A sort key for comparison.
    /// - Returns: True if the keys match exactly.
    public func sortKeyEquals(_ str: String) -> Bool {
        return str == sortKey
    }
    
    public static func < (lhs: Note, rhs: Note) -> Bool {
        if lhs.collection.sortParm == .custom {
            return compareCustomFields(lhs: lhs, rhs: rhs) < 0
        } else if lhs.collection.sortDescending {
            return lhs.sortKey > rhs.sortKey
        } else {
            return lhs.sortKey < rhs.sortKey
        }
    }
    
    public static func == (lhs: Note, rhs: Note) -> Bool {
        if lhs.collection.sortParm == .custom {
            return compareCustomFields(lhs: lhs, rhs: rhs) == 0
        } else {
            return lhs.sortKey == rhs.sortKey
        }
    }
    
    /// Compare this note to another using a set of custom fields for comparison. 
    static func compareCustomFields(lhs: Note, rhs: Note) -> Int {
        var result = 0
        var index = 0
        while index < lhs.collection.customFields.count && result == 0 {
            let sortField = lhs.collection.customFields[index]
            let def = sortField.field
            let field1 = FieldGrabber.getField(note: lhs, label: def.fieldLabel.commonForm)
            var value1 = StringValue()
            if field1 != nil {
                value1 = field1!.value
            }
            let field2 = FieldGrabber.getField(note: rhs, label: def.fieldLabel.commonForm)
            var value2 = StringValue()
            if field2 != nil {
                value2 = field2!.value
            }
            if value1 < value2 {
                result = sortField.ascending ? -1 :  1
            } else if value1 > value2 {
                result = sortField.ascending ?  1 : -1
            } else {
                index += 1
            }
        }

        return result
    }
    
    public func getURLforAttachment(attachmentName: String) -> URL? {
        for attachment in attachments {
            if attachmentName == attachment.fullName || attachmentName == attachment.suffix {
                let attachmentsFolder = collection.lib.getResource(type: .attachments)
                let attachmentResource = ResourceFileSys(parent: attachmentsFolder,
                                                         fileName: attachment.fullName,
                                                         type: .attachment)
                return attachmentResource.url
            }
        }
        return nil
    }
    
    public var imageURL: URL? {
        guard let def = collection.imageNameFieldDef else { return nil }
        guard let imageField = getField(def: def) else { return nil }
        let imageName = imageField.value.value
        guard imageName.count > 0 else { return nil }
        
        var imageURL: URL?
        for attachment in attachments {
            if attachment.suffix.lowercased() == imageName.lowercased() {
                let attachmentsFolder = collection.lib.getResource(type: .attachments)
                let attachmentResource = ResourceFileSys(parent: attachmentsFolder,
                                                         fileName: attachment.fullName,
                                                         type: .attachment)
                imageURL = attachmentResource.url
            }
        }
        return imageURL
    }
    
    public var imageCommonName: String {

        guard let def = collection.imageNameFieldDef else { return "" }
        guard let imageField = getField(def: def) else { return "" }
        let imageName = imageField.value.value
        guard imageName.count > 0 else { return "" }
        
        var commonName = ""
        for attachment in attachments {
            if attachment.suffix.lowercased() == imageName.lowercased() {
                commonName = attachment.commonName
            }
        }
        return commonName
    }
    
    public func getImageAttachment() -> AttachmentName? {
        guard let def = collection.imageNameFieldDef else { return nil }
        guard let imageField = getField(def: def) else { return nil }
        let imageName = imageField.value.value
        guard !imageName.isEmpty else { return nil }
        let imageNameLowered = imageName.lowercased()
        
        for attachment in attachments {
            if attachment.suffix.lowercased() == imageNameLowered {
                return attachment
            }
        }
        return nil
    }
    
    /// Make a copy of this Note
    public func copy(with zone: NSZone? = nil) -> Any {
        let newNote = Note(collection: collection)
        copyFields(to: newNote)
        copyAttachments(to: newNote)
        newNote.noteID = noteID.copy()
        if hasCheckBoxUpdates {
            for (ckBoxName, checked) in checkBoxUpdates {
                newNote.checkBoxUpdates[ckBoxName] = checked
            }
        }
        return newNote
    }
    
    /// Copy field values from this Note to a second Note, making sure all fields have
    /// matching definitions and values.
    ///
    /// - Parameter note2: The Note to be updated with this Note's field values.
    public func copyFields(to note2: Note, copyBlanks: Bool = true) {

        let dict = collection.dict
        let defs = dict.list
        for definition in defs {
            let field = getField(def: definition)
            let field2 = note2.getField(def: definition)
            if field == nil && field2 == nil {
                // Nothing to do here -- just move on
            } else if field == nil && field2 != nil {
                if copyBlanks {
                    field2!.value.set("")
                }
            } else if field != nil && field2 == nil {
                _ = note2.addField(def: definition, strValue: field!.value.value)
            } else {
                field2!.value.set(field!.value.value)
            }
        }
        note2.identify()
    }
    
    /// Copy field values from this Note to a second Note, but only copying fields
    /// defined in the second note's collection dictionary. 
    ///
    /// - Parameter note2: The Note to be updated with this Note's field values.
    public func copyDefinedFields(to note2: Note, addDefs: Bool = false) {

        // Copy fields defined in to dictionary.
        var fromFieldsCopied: [String: FieldDefinition] = [:]
        let toDict = note2.collection.dict
        let toDefs = toDict.list
        for toDef in toDefs {
            var fromField = getField(def: toDef)
            if fromField == nil {
                switch toDef.fieldType.typeString {
                case NotenikConstants.booleanType: break
                case NotenikConstants.dateType: break
                case NotenikConstants.longTextType: break
                case NotenikConstants.lookupType: break
                case NotenikConstants.pickFromType: break
                case NotenikConstants.stringType: break
                default:
                    fromField = getFieldByType(def: toDef)
                }
            }
            let toField = note2.getField(def: toDef)
            if fromField == nil && toField == nil {
                // Nothing to do here -- just move on
            } else if fromField == nil && toField != nil {
                toField!.value.set("")
            } else if fromFieldsCopied[fromField!.def.fieldLabel.commonForm] != nil {
                // Already found a home for this field -- don't copy it again
            } else if fromField != nil && toField == nil {
                _ = note2.addField(def: toDef, strValue: fromField!.value.value)
                fromFieldsCopied[fromField!.def.fieldLabel.commonForm] = fromField!.def
            } else {
                toField!.value.set(fromField!.value.value)
                fromFieldsCopied[fromField!.def.fieldLabel.commonForm] = fromField!.def
            }
        }

        if !toDict.locked && note2.collection.otherFields {
            copyMissingFields(to: note2)
        } else if addDefs {
            copyMissingFields(to: note2)
        }
        
        note2.identify()
    }
    
    func copyMissingFields(to note2: Note) {

        for fromDef in collection.dict.list {
            guard let fromField = getField(def: fromDef) else { continue }
            let toField = note2.getField(def: fromDef)
            if toField == nil {
                _ = note2.addField(def: fromDef, strValue: fromField.value.value)
            }
        }
    }
    
    /// Copy attachment file names from this note to another one. 
    func copyAttachments(to note2: Note) {
        for attachment in attachments {
            let attachment2 = attachment
            note2.attachments.append(attachment2)
        }
    }
    
    /* ---------------------------------------------------------
     
     The following fields and functions identify and manipulate
     the unique identifier for this Note
     
     --------------------------------------------------------- */
    
    public func getNotenikLink(preferringTimestamp: Bool = false) -> String {
        
        var str = "notenik://open?"
        
        if collection.shortcut.count > 0 {
            str.append("shortcut=\(collection.shortcut)")
        } else {
            let folderURL = URL(fileURLWithPath: collection.fullPath)
            let encodedPath = String(folderURL.absoluteString.dropFirst(7))
            str.append("path=\(encodedPath)")
        }
        
        if preferringTimestamp && collection.hasTimestamp {
            str.append("&timestamp=\(timestampAsString)")
        } else {
            str.append("&id=\(noteID.commonID)")
        }
        return str
    }
    
    /// Provide a value to uniquely identify this note within its Collection, and provide
    /// conformance to the Identifiable protocol.
    /*
    public var id: String {
        return _noteID.identifier
    }
    
    var _noteID = NoteID()
    
    /// Get the unique ID used to identify this note within its collection
    public var noteID: NoteID {
        return _noteID
    }
    
    func setID() {
        _noteID.set(from: self)
    }
    
    func incrementID() -> String {
        return _noteID.increment()
    }
    
    func updateIDSource() {
        _noteID.updateSource(note: self)
    }
     
     */
    
    /// Set the Note's Code value
    func setCode(_ code: String) -> Bool {
        return setField(label: NotenikConstants.code, value: code)
    }
    
    /// Set the Note's Date Added field
    func setDateAdded(_ dateAdded: String) -> Bool {
        return setField(label: NotenikConstants.dateAdded, value: dateAdded)
    }
    
    /// Set the Note's Date Last Modified field.
    func setDateModified(_ dateModified: String) -> Bool {
        if collection.dict.getDef(NotenikConstants.dateModified) == nil {
            return false
        }
        return setField(label: NotenikConstants.dateModified, value: dateModified)
    }
    
    /// Note is being modified right now - bring field up-to-date.
    func setDateModNow() {
        guard let dateModifiedDef = collection.dict.getDef(NotenikConstants.dateModified) else {
            return
        }
        let dateModField = getField(def: dateModifiedDef)
        if let dateModValue = dateModField?.value as? DateTimeValue {
            dateModValue.setToNow()
        } else {
            let nowValue = DateTimeValue()
            let dateModField = NoteField(def: dateModifiedDef, value: nowValue)
            _ = addField(dateModField)
        }
    }
    
    public var dateModifiedValue: String {
        guard let dateModifiedDef = collection.dict.getDef(NotenikConstants.dateModified) else {
            return envModDate
        }
        let dateModField = getField(def: dateModifiedDef)
        if let dateModValue = dateModField?.value as? DateTimeValue {
            return dateModValue.value
        }
        return envModDate
    }
    
    public var dateModifiedSortKey: String {
        guard let dateModifiedDef = collection.dict.getDef(NotenikConstants.dateModified) else {
            return envModDate
        }
        let dateModField = getField(def: dateModifiedDef)
        if let dateModValue = dateModField?.value as? DateTimeValue {
            return dateModValue.sortKey
        }
        return envModDate
    }
    
    /// Return the date the note was originally added
    public var dateAdded: DateTimeValue {
        let val = getFieldAsValue(label: NotenikConstants.dateAdded)
        if val is DateTimeValue {
            return val as! DateTimeValue
        } else {
            return DateTimeValue(val.value)
        }
    }
    
    /// Return the date the note was last modified.
    public var dateModified: DateTimeValue {
        let val = getFieldAsValue(label: NotenikConstants.dateModified)
        if val is DateTimeValue {
            return val as! DateTimeValue
        } else {
            return DateTimeValue(val.value)
        }
    }
    
    /// This variable provides compliance with the CustomStringConvertible protocol.
    public var description: String {
        return sortKey
    }
    
    /// Return a String containing the current sort key for the Note
    public var sortKey: String {
        switch collection.sortParm {
        case .title:
            return title.sortKey
        case .seqPlusTitle:
            return seq.sortKey + title.sortKey + level.sortKey
        case .tasksByDate:
            return (status.doneX(config: collection.statusConfig)
                + date.getSortKey(sortBlankDatesLast: collection.sortBlankDatesLast)
                + seq.sortKey
                + title.sortKey)
        case .tasksBySeq:
            return (status.doneX(config: collection.statusConfig)
                + seq.sortKey
                + date.getSortKey(sortBlankDatesLast: collection.sortBlankDatesLast)
                + title.sortKey)
        case .tagsPlusTitle:
            return (tags.sortKey
                + title.sortKey
                + status.sortKey)
        case .author:
            return (creatorSortKey
                + date.getSortKey(sortBlankDatesLast: collection.sortBlankDatesLast)
                + title.sortKey)
        case .tagsPlusSeq:
            return (tags.sortKey + " "
                + seq.sortKey + " "
                + title.sortKey)
        case .dateAdded:
            return dateAddedSortKey
        case .dateModified:
            return dateModifiedSortKey
        case .datePlusSeq:
            return date.getSortKey(sortBlankDatesLast: collection.sortBlankDatesLast)
                + seq.sortKey
                + title.sortKey
        case .rankSeqTitle:
            return rank.getSortKey(config: collection.rankConfig)
                + seq.sortKey
                + title.sortKey
        case .klassTitle:
            return klass.sortKey
                + title.sortKey
        case .klassDateTitle:
            return klass.sortKey
                + date.getSortKey(sortBlankDatesLast: collection.sortBlankDatesLast)
                + title.sortKey
        case .lastNameFirst:
            return lastNameFirst
        case .custom:
            var key = ""
            for sortField in collection.customFields {
                let def = sortField.field
                let field = getField(def: def)
                if field != nil {
                    let value = field!.value
                    key.append(value.sortKey)
                }
            }
            return key
        }
    }
    
    /// Does this note have a date added?
    func hasDateAdded() -> Bool {
        return dateAdded.count > 0
    }
    
    /// Does this note have a date modified?
    func hasDateModified() -> Bool {
        return dateModified.count > 0
    }
    
    //
    // Task-related functions involving multiple fields. 
    //
    
    public var doneXorT: String {
        if isDone {
            return "X"
        } else if date.isToday {
            return "T"
        } else {
            return " "
        }
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    public func close() {
        if hasDate() && hasRecurs() {
            recur()
        } else if hasStatus()  {
            status.close(config: collection.statusConfig)
        }
    }
        
    /// Apply the recurs rule to the note
    public func recur() {
        if hasDate() && hasRecurs() {
            let dateVal = date
            let recursVal = recurs
            let newDate = recursVal.recur(dateVal)
            dateVal.set(String(describing: newDate))
        }
    }
    
    //
    // Functions and variables concerning the Note's title.
    //
    
    /// Get the title of the Note as a String, optionally preceded by the Note's Seq value.
    /// - Parameters:
    ///   - withSeq: Should the returned value be prefixed by the Note's Seq value? If the Note has no Seq value,
    ///   or if its class/klass indicates it should be treated as front matter or back matter, then a True value here
    ///   will have no effect.
    ///   - sep: The separator to place between the Seq and the Title. Defaults to a single space.
    /// - Returns: The title of the Note, optionally preceded by a Seq value.
    public func getTitle(withSeq: Bool = false, formattedSeq: Bool = false, sep: String = " ") -> String {
        if withSeq && hasSeq() && !klass.frontOrBack {
            if formattedSeq {
                return formattedSeqForDisplay + sep + title.value
            } else {
                return seq.value + sep + title.value
            }
        } else {
            return title.value
        }
    }
    
    /// Return the Note's Title Value
    public var title: TitleValue {
        let val = getFieldAsValue(def: collection.titleFieldDef)
        if val is TitleValue {
            return val as! TitleValue
        } else {
            return TitleValue(val.value)
        }
    }
    
    /// Does this note have a non-blank title field?
    public func hasTitle() -> Bool {
        return title.count > 0
    }
    
    /// Does this Note contain a title?
    func containsTitle() -> Bool {
        return contains(def: collection.titleFieldDef)
    }
    
    /// Get the Title field, if one exists
    func getTitleAsField() -> NoteField? {
        return getField(def: collection.titleFieldDef)
    }
    
    /// Set the Note's Title value
    public func setTitle(_ title: String) -> Bool {
        let ok = setField(label: collection.titleFieldDef.fieldLabel.commonForm, value: title)
        return ok
    }
    
    //
    // Functions and variables concerning the Note's Address field
    //
    
    public func hasAddress() -> Bool {
        guard let def = collection.addressFieldDef else { return false }
        let field = getField(def: def)
        if field == nil {
            return false
        } else if field!.value.isEmpty {
            return false
        }
        return true
    }
    
    public var address: AddressValue {
        guard let def = collection.addressFieldDef else { return AddressValue() }
        let field = getField(def: def)
        if field == nil {
            return AddressValue()
        } else if let value = field!.value as? AddressValue {
            return value
        } else {
            return AddressValue(field!.value.value)
        }
    }
    
    //
    // Functions and variables concering the Note's Directions field
    //
    
    public func hasDirections() -> Bool {
        guard let def = collection.directionsFieldDef else { return false }
        let field = getField(def: def)
        if field == nil {
            return false
        } else if field!.value.isEmpty {
            return false
        }
        return true
    }
    
    public var directions: DirectionsValue {
        guard let def = collection.directionsFieldDef else { return DirectionsValue() }
        let field = getField(def: def)
        if field == nil {
            return DirectionsValue()
        } else if let value = field!.value as? DirectionsValue {
            return value
        } else {
            return DirectionsValue(field!.value.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's AKA field.
    //
     
    /// Return the Note's AKA Value
    public var aka: AKAValue {
        guard collection.akaFieldDef != nil else {
            return AKAValue()
        }
        let val = getFieldAsValue(def: collection.akaFieldDef!)
        if val is AKAValue {
            return val as! AKAValue
        } else {
            return AKAValue(val.value)
        }
    }
    
    /// Does this note have a non-blank AKA field?
    public func hasAKA() -> Bool {
        guard collection.akaFieldDef != nil else { return false }
        return aka.count > 0
    }
    
    /// Get the AKA field, if one exists
    func getAKAasField() -> NoteField? {
        guard collection.akaFieldDef != nil else { return nil }
        return getField(def: collection.akaFieldDef!)
    }
    
    /// Set the Note's AKA value
    public func setAKA(_ aka: String) -> Bool {
        guard collection.akaFieldDef != nil else { return false }
        return setField(label: collection.akaFieldDef!.fieldLabel.commonForm,
                          value: aka)
    }
    
    //
    // Functions and variables concerning the Note's teaser field.
    //
    
    /// Return the note's teaser value.
    public var teaser: TeaserValue {
        guard collection.teaserFieldDef != nil else {
            return TeaserValue()
        }
        let val = getFieldAsValue(def: collection.teaserFieldDef!)
        if val is TeaserValue {
            return val as! TeaserValue
        } else {
            return TeaserValue(val.value)
        }
    }
    
    /// Does thos note have a non-blank teaser field?
    public func hasTeaser() -> Bool {
        guard collection.teaserFieldDef != nil else { return false }
        return teaser.count > 0
    }
    
    /// Get the teaser field, if one exists.
    public func getTeaserAsField() -> NoteField? {
        guard collection.teaserFieldDef != nil else { return nil }
        return getField(def: collection.teaserFieldDef!)
    }
    
    /// Attempt to set the Note's teaser value.
    public func setTeaser(_ teaser: String) -> Bool {
        guard collection.teaserFieldDef != nil else { return false }
        return setField(label: collection.teaserFieldDef!.fieldLabel.commonForm,
                        value: teaser)
    }
    
    //
    // Functions and variables concerning the Note's text format field.
    //
    
    /// Return the note's text format value.
    public var textFormat: TextFormatValue {
        guard collection.textFormatFieldDef != nil else {
            return TextFormatValue()
        }
        let val = getFieldAsValue(def: collection.textFormatFieldDef!)
        if val is TextFormatValue {
            return val as! TextFormatValue
        } else {
            return TextFormatValue(val.value)
        }
    }
    
    /// Does thos note have a non-blank text format field?
    public func hasTextFormat() -> Bool {
        guard collection.textFormatFieldDef != nil else { return false }
        return textFormat.count > 0
    }
    
    /// Get the text format field, if one exists.
    public func getTextFormatAsField() -> NoteField? {
        guard collection.textFormatFieldDef != nil else { return nil }
        return getField(def: collection.textFormatFieldDef!)
    }
    
    /// Attempt to set the Note's text format value.
    public func setTextFormat(_ txtFormat: String) -> Bool {
        guard collection.textFormatFieldDef != nil else { return false }
        return setField(label: collection.textFormatFieldDef!.fieldLabel.commonForm,
                        value: txtFormat)
    }
    
    //
    // Functions and variables concerning the Note's tags.
    //
    
    /// Does this note have a non-blank tags field?
    public func hasTags() -> Bool {
        return tags.count > 0
    }
    
    /// Set the Note's Tags value
    public func setTags(_ tags: String) -> Bool {
        return setField(label: collection.tagsFieldDef.fieldLabel.commonForm, value: tags)
    }
    
    public func getTagsAsField() -> NoteField? {
        return getField(def: collection.tagsFieldDef)
    }
    
    /// Return the Note's Tags Value
    public var tags: TagsValue {
        let val = getFieldAsValue(def: collection.tagsFieldDef)
        if val is TagsValue {
            return val as! TagsValue
        } else {
            return TagsValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's first or only Link field
    //
    
    /// Does this note have a link?
    public func hasLink() -> Bool {
        return link.count > 0
    }
    
    /// Set the Note's Link value
    public func setLink(_ link: String) -> Bool {
        return setField(label: collection.linkFieldDef.fieldLabel.commonForm, value: link)
    }
    
    /// Return the Note's Link Value
    public var link: LinkValue {
        let val = getFieldAsValue(def: collection.linkFieldDef)
        if val is LinkValue {
            return val as! LinkValue
        } else {
            return LinkValue(val.value)
        }
    }
    
    /// Return the Note's Link Value (if any) as a possible URL
    public var linkAsURL: URL? {
        let val = getFieldAsValue(def: collection.linkFieldDef)
        if val is LinkValue {
            let linkVal = val as! LinkValue
            return linkVal.url
        } else {
            return nil
        }
    }
    
    /// Return the first available link value from this note.
    public var firstLinkAsURL: URL? {
        let dict = collection.dict
        let defs = dict.list
        for definition in defs {
            let fieldType = definition.fieldType
        
            if fieldType is LinkType {
                let linkField = getField(def: definition)
                if linkField != nil {
                    if let linkVal = linkField!.value as? LinkValue {
                        if let linkURL = linkVal.url {
                            return linkURL
                        }
                    }
                }
            } else if fieldType is EmailType {
                let emailField = getField(def: definition)
                if emailField != nil {
                    if let emailVal = emailField!.value as? EmailValue {
                        if let emailURL = emailVal.url {
                            return emailURL
                        }
                    }
                }
            } else if fieldType is AddressType {
                let addressField = getField(def: definition)
                if addressField != nil {
                    if let address = addressField?.value as? AddressValue {
                        if let url = URL(string: address.link) {
                            return url
                        }
                    }
                }
            } else if fieldType is DirectionsType {
                let directionsField = getField(def: definition)
                if directionsField != nil {
                    if let directions = directionsField?.value as? DirectionsValue {
                        if let url = URL(string: directions.link) {
                            return url
                        }
                    }
                }
            }
        }
        return nil
    }
    
    //
    // Functions and variables concerning the Note's first or only Date field
    //
    
    /// Does this note have a non-blank date field?
    public func hasDate() -> Bool {
        return date.count > 0
    }
    
    /// Set the Note's Date value
    public func setDate(_ date: String) -> Bool {
        return setField(label: collection.dateFieldDef.fieldLabel.commonForm, value: date)
    }
    
    public func getDateAsField() -> NoteField? {
        return getField(def: collection.dateFieldDef)
    }
    
    /// Return the Note's Date Value
    public var date: DateValue {
        let val = getFieldAsValue(def: collection.dateFieldDef)
        if val is DateValue {
            return val as! DateValue
        } else {
            return DateValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's recurs field.
    //
    
    /// Does this note have a non-blank recurs field?
    public func hasRecurs() -> Bool {
        return recurs.count > 0
    }
    
    /// Does this note recur on a daily basis?
    public var daily: Bool {
        guard let recursVal = getFieldAsValue(def: collection.recursFieldDef) as? RecursValue else { return false }
        return recursVal.daily
    }
    
    /// Return the Note's Recurs Value
    public var recurs: RecursValue {
        let val = getFieldAsValue(def: collection.recursFieldDef)
        if val is RecursValue {
            return val as! RecursValue
        } else {
            return RecursValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's status field.
    //
    
    /// Does this note have a non-blank status field?
    public func hasStatus() -> Bool {
        return status.count > 0
    }
    
    /// Toggle the Note's status between least complete and most complete.
    public func toggleStatus() {
        if hasStatus() {
            status.toggle(config: collection.statusConfig)
        }
    }
    
    /// Bump this Note's status up to the next valid value for this Collection.
    public func incrementStatus() {
        if hasStatus() {
            status.increment(config: collection.statusConfig)
        }
    }
    
    /// Set the Note's Status value
    func setStatus(_ status: String) -> Bool {
        return setField(label: collection.statusFieldDef.fieldLabel.commonForm, value: status)
    }
    
    /// Is the user done with this item?
    public var isDone: Bool {
        let stat = status
        let done = stat.isDone(config: collection.statusConfig)
        return done
    }
    
    /// Return the Note's Status Value
    public var status: StatusValue {
        let val = getFieldAsValue(def: collection.statusFieldDef)
        if val is StatusValue {
            return val as! StatusValue
        } else {
            return StatusValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's depth.
    //
    
    
    /// Return a derived depth, using level, if available, otherwise seq depth, if available,
    /// otherwise 1.
    var depth: Int {
        
        // Use level, if we have it
        if let levelDef = collection.levelFieldDef {
            if let levelField = fields[levelDef.fieldLabel.commonForm] {
                if let levelValue = levelField.value as? LevelValue {
                    let config = collection.levelConfig
                    let level = levelValue.getInt()
                    if level >= config.low && level <= config.high {
                        return level
                    }
                }
            }
        }
        
        if let seqDef = collection.seqFieldDef {
            if let seqField = fields[seqDef.fieldLabel.commonForm] {
                if let seqValue = seqField.value as? SeqValue {
                    let seqDepth = seqValue.numberOfLevels
                    if seqDepth >= 1 {
                        return seqDepth
                    }
                }
            }
        }
        
        return 1
    }
    
    //
    // Functions and variables concerning the Note's level field.
    //
    public func hasLevel() -> Bool {
        guard collection.levelFieldDef != nil else { return false }
        guard let levelField = fields[collection.levelFieldDef!.fieldLabel.commonForm] else { return false }
        guard let levelValue = levelField.value as? LevelValue else { return false }
        let config = collection.levelConfig
        let level = levelValue.getInt()
        guard level >= config.low && level <= config.high else { return false }
        return true
    }
    
    public func incrementLevel() {
        guard collection.levelFieldDef != nil else { return }
        guard let levelField = fields[collection.levelFieldDef!.fieldLabel.commonForm] else { return }
        guard let levelValue = levelField.value as? LevelValue else { return }
        let config = collection.levelConfig
        var level = levelValue.getInt()
        guard level >= config.low && level < config.high else { return }
        level += 1
        levelValue.set(i: level, config: config)
    }
    
    public func setLevel(_ level: LevelValue) -> Bool {
        return setLevel(level.value)
    }
    
    public func setLevel(_ level: Int) -> Bool {
        let levelStr = "\(level)"
        return setLevel(levelStr)
    }
    
    /// Set the Note's Level Value.
    public func setLevel(_ level: String) -> Bool {
        guard collection.levelFieldDef != nil else { return false }
        return setField(label: collection.levelFieldDef!.fieldLabel.commonForm, value: level)
    }
    
    /// Return the Note's Level Value.
    public var level: LevelValue {
        guard collection.levelFieldDef != nil else {
            return LevelValue()
        }
        let val = getFieldAsValue(def: collection.levelFieldDef!)
        if val is LevelValue {
            return val as! LevelValue
        } else {
            return LevelValue(val.value)
        }
    }
    
 
    //
    // Return the appropriate seq field.
    //
   
    public var formattedSeqForDisplay: String {
        if hasDisplaySeq() {
            return formattedDisplaySeq
        } else {
            return formattedSeq
        }
    }
    
    //
    // Functions and variables concerning the Note's seq field.
    //
    
    // Does this note have a non-blank Sequence field?
    public func hasSeq() -> Bool {
        return seq.count > 0
    }
    
    /// Set the Note's Sequence value
    public func setSeq(_ seq: String) -> Bool {
        guard collection.seqFieldDef != nil else { return false }
        return setField(label: collection.seqFieldDef!.fieldLabel.commonForm, value: seq)
    }
    
    public func getSeqAsField() -> NoteField? {
        guard collection.seqFieldDef != nil else { return nil }
        return getField(def: collection.seqFieldDef!)
    }
    
    /// Return the Note's Sequence Value
    public var seq: SeqValue {
        guard collection.seqFieldDef != nil else {
            return SeqValue(seqParms: SeqParms())
        }
        let val = getFieldAsValue(def: collection.seqFieldDef!)
        if val is SeqValue {
            return val as! SeqValue
        } else {
            return collection.seqFieldDef!.fieldType.createValue(val.value) as! SeqValue
        }
    }
    
    /// Return a formatted Seq, basec on Collection prefs
    public var formattedSeq: String {
        
        guard collection.seqFieldDef != nil else { return "" }
        
        guard let seqValue = getFieldAsValue(def: collection.seqFieldDef!) as? SeqValue else { return "" }

        return collection.seqFormatter.format(seq: seqValue)
    }
    
    //
    // Functions and variables concerning the Note's Duration field.
    //
    public func hasDuration() -> Bool {
        guard let def = collection.durationFieldDef else { return false }
        guard let field = fields[def.fieldLabel.commonForm] else { return false }
        guard field.value.hasData else { return false }
        return true
    }
    
    public func setDuration(_ duration: String) -> Bool {
        guard collection.durationFieldDef != nil else { return false }
        return setField(label: collection.durationFieldDef!.fieldLabel.commonForm, value: duration)
    }
    
    public func getDurationAsField() -> NoteField? {
        guard let def = collection.durationFieldDef else { return nil }
        return getField(def: def)
    }
    
    public var duration: DurationValue {
        guard collection.durationFieldDef != nil else {
            return DurationValue()
        }
        let val = getFieldAsValue(def: collection.durationFieldDef!)
        if val is DurationValue {
            return val as! DurationValue
        } else {
            return collection.durationFieldDef!.fieldType.createValue(val.value) as! DurationValue
        }
    }
    
    //
    // Functions and variables concerning the Note's Display Seq field.
    //
    
    // Does this note have a non-blank Display Sequence field?
    public func hasDisplaySeq() -> Bool {
        guard let def = collection.displaySeqFieldDef else { return false }
        let val = getFieldAsValue(def: def)
        return (val.count > 0)
    }
    
    /// Set the Note's Display Sequence value
    public func setDisplaySeq(_ displaySeq: String) -> Bool {
        guard collection.displaySeqFieldDef != nil else { return false }
        return setField(label: collection.displaySeqFieldDef!.fieldLabel.commonForm,
                        value: displaySeq)
    }
    
    /// Return the Note's Display Sequence Value
    public var displaySeq: DisplaySeqValue {
        guard collection.displaySeqFieldDef != nil else {
            return DisplaySeqValue()
        }
        let val = getFieldAsValue(def: collection.displaySeqFieldDef!)
        if val is DisplaySeqValue {
            return val as! DisplaySeqValue
        } else {
            return DisplaySeqValue(val.value)
        }
    }
    
    /// Return a formatted Seq, basec on Collection prefs
    public var formattedDisplaySeq: String {
        
        guard let def = collection.displaySeqFieldDef else { return "" }
        guard let type = def.fieldType as? DisplaySeqType else { return "" }
        let val = getFieldAsString(label: def.fieldLabel.commonForm)
        let formatted = type.formatString.replacingOccurrences(of: "XXX", with: val).replacingOccurrences(of: "_", with: " ")
        return formatted
    }
    
    //
    // Functions and Variables concerning the Note's Rank field
    //
    
    // Does this note have a Rank value?
    public func hasRank() -> Bool {
        guard collection.rankFieldDef != nil else { return false }
        guard let rankValue = getFieldAsValue(def: collection.rankFieldDef!) as? RankValue else { return false }
        guard rankValue.number > 0 || !rankValue.label.isEmpty else { return false }
        return true
    }
    
    public func setRank(_ rank: String) -> Bool {
        guard collection.rankFieldDef != nil else { return false }
        return setField(label: collection.rankFieldDef!.fieldLabel.commonForm, value: rank)
    }
    
    public var rank: RankValue {
        guard collection.rankFieldDef != nil else { return RankValue() }
        let val = getFieldAsValue(def: collection.rankFieldDef!)
        if val is RankValue {
            return val as! RankValue
        } else {
            return RankValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's Timestamp field.
    //
    
    func hasTimestamp() -> Bool {
        guard collection.hasTimestamp else { return false }
        guard let timestampDef = getTimestampDef() else { return false }
        guard self.contains(def: timestampDef) else { return false }
        return true
    }
    
    func setTimestamp(_ timestamp: String) -> Bool {
        let ok = setField(label: NotenikConstants.timestamp, value: timestamp)
        return ok
    }
    
    /// Retum the timestamp value
    public var timestamp: TimestampValue {
        let val = getFieldAsValue(label: NotenikConstants.timestamp)
        if val is TimestampValue {
            return val as! TimestampValue
        } else {
            return TimestampValue(val.value)
        }
    }
    
    /// Return the timestamp, if the Note has one, or an empty string otherwise.
    public var timestampAsString: String {
        guard collection.hasTimestamp else { return "" }
        guard let timestampDef = getTimestampDef() else { return "" }
        guard self.contains(def: timestampDef) else { return "" }
        let field = getFieldAsValue(def: timestampDef)
        return field.value
    }
    
    public func getTimestampDef() -> FieldDefinition? {
        collection.dict.getDef(NotenikConstants.timestamp)
    }
    
    //
    // Functions and variables concerning the Note's Attribution field.
    //
    
    // Does this note have a non-blank Attribution field?
    public func hasAttribution() -> Bool {
        guard collection.attribFieldDef != nil else {
            return false
        }
        return attribution.count > 0
    }
    
    /// Set the Note's Sequence value
    public func setAttribution(_ attrib: String) -> Bool {
        guard collection.attribFieldDef != nil else { return false }
        return setField(label: collection.attribFieldDef!.fieldLabel.commonForm,
                        value: attrib)
    }
    
    /// Return the Note's Sequence Value
    public var attribution: LongTextValue {
        guard collection.attribFieldDef != nil else {
            return LongTextValue()
        }
        let val = getFieldAsValue(def: collection.attribFieldDef!)
        if val is LongTextValue {
            return val as! LongTextValue
        } else {
            return LongTextValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's class field.
    //
    
    /// See if this Note has a Class value.
    public func hasKlass() -> Bool {
        guard collection.klassFieldDef != nil else { return false }
        let val = getFieldAsValue(def: collection.klassFieldDef!)
        return val is KlassValue && !val.value.isEmpty
    }
    
    /// Set the Note's Class value.
    public func setKlass(_ value: String) -> Bool {
        guard collection.klassFieldDef != nil else { return false }
        let val = getFieldAsValue(def: collection.klassFieldDef!)
        if val is KlassValue {
            let klass = val as! KlassValue
            klass.set(value)
            return true
        } else {
            let klass = KlassValue(value)
            let field = NoteField()
            field.def = collection.klassFieldDef!
            field.value = klass
            return setField(field)
        }
    }
    
    /// Return the Note's Class Value
    public var klass: KlassValue {
        guard collection.klassFieldDef != nil else {
            return KlassValue(getFieldAsString(label: NotenikConstants.type))
        }
        let val = getFieldAsValue(def: collection.klassFieldDef!)
        if val is KlassValue {
            return val as! KlassValue
        } else {
            return KlassValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's Include Children field.
    //
    
    /// See if this Note has an Include Children value.
    public func hasIncludeChildren() -> Bool {
        guard collection.includeChildrenDef != nil else {
            return false
        }
        let val = getFieldAsValue(def: collection.includeChildrenDef!)
        return val is IncludeChildrenValue
    }
    
    /// Set the Note's Include Children value.
    public func setIncludeChildren(_ value: String) -> Bool {
        guard collection.includeChildrenDef != nil else { return false }
        let val = getFieldAsValue(def: collection.includeChildrenDef!)
        if val is IncludeChildrenValue {
            let includeChildren = val as! IncludeChildrenValue
            includeChildren.set(value)
            return true
        } else {
            let includeChildren = IncludeChildrenValue(value)
            let field = NoteField()
            field.def = collection.includeChildrenDef!
            field.value = includeChildren
            return setField(field)
        }
    }
    
    /// Return the Note's IncludeChildren Value
    public var includeChildren: IncludeChildrenValue {
        guard collection.includeChildrenDef != nil else {
            return IncludeChildrenValue()
        }
        let val = getFieldAsValue(def: collection.includeChildrenDef!)
        if val is IncludeChildrenValue {
            return val as! IncludeChildrenValue
        } else {
            return IncludeChildrenValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's Short ID field.
    //
    
    // Does this note have a non-blank Short ID field?
    public func hasShortID() -> Bool {
        guard collection.shortIdDef != nil else { return false }
        return shortID.count > 0
    }
    
    /// Set the Note's Short ID  value
    public func setShortID(_ shortID: String) -> Bool {
        guard collection.shortIdDef != nil else { return false }
        return setField(label: collection.shortIdDef!.fieldLabel.commonForm, value: shortID)
    }
    
    /// Return the Note's Sequence Value
    public var shortID: ShortIdValue {
        guard collection.shortIdDef != nil else {
            return ShortIdValue()
        }
        let val = getFieldAsValue(def: collection.shortIdDef!)
        if val is ShortIdValue {
            return val as! ShortIdValue
        } else {
            return ShortIdValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's index field.
    //
    
    /// Does this note have a non-blank Index field?
    func hasIndex() -> Bool {
        return index.count > 0
    }
    
    /// Append additional data to the Index Value
    func appendToIndex(_ index: String) {
        let field = getField(label: collection.indexFieldDef.fieldLabel.commonForm)
        if field == nil {
            _ = setIndex(index)
        } else {
            let val = field!.value
            if val is IndexValue {
                let indexVal = val as! IndexValue
                indexVal.append(index)
            }
        }
    }
    
    /// Set the Note's Index value
    func setIndex(_ index: String) -> Bool {
        return setField(label: collection.indexFieldDef.fieldLabel.commonForm, value: index)
    }
    
    /// Return the Note's Index Value
    public var index: IndexValue {
        let val = getFieldAsValue(def: collection.indexFieldDef)
        if val is IndexValue {
            return val as! IndexValue
        } else {
            return IndexValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's backlinks field.
    //
    
    /// Does the Note have any backlinks?
    func hasBacklinks() -> Bool {
        return collection.backlinksDef != nil && backlinks.count > 0
    }
    
    /// Add another line of links.
    func appendToBacklinks(_ morelinks: String) {
        guard let def = collection.backlinksDef else { return }
        let field = getField(label: def.fieldLabel.commonForm)
        if field == nil {
            _ = setBacklinks(morelinks)
        } else {
            let val = field!.value
            if val is BacklinkValue {
                let linksVal = val as! BacklinkValue
                linksVal.append(morelinks)
            }
        }
    }
    
    /// Set the Note's backlinks value.
    func setBacklinks(_ backlinks: String) -> Bool {
        guard let def = collection.backlinksDef else { return false }
        return setField(label: def.fieldLabel.commonForm,
                        value: backlinks)
    }
    
    func setBacklinks(_ backlinks: BacklinkValue) -> Bool {
        guard let def = collection.backlinksDef else { return false }
        let field = NoteField()
        field.def = def
        field.value = backlinks
        return setField(field)
    }
    
    /// Return the Note's backlinks value.
    public var backlinks: BacklinkValue {
        guard let def = collection.backlinksDef else {
            return BacklinkValue("")
        }
        let val = getFieldAsValue(def: def)
        if val is BacklinkValue {
            return val as! BacklinkValue
        } else {
            return BacklinkValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's wikilinks field.
    //
    
    /// Does the Note have any wikilinks?
    func hasWikilinks() -> Bool {
        return collection.wikilinksDef != nil && wikilinks.count > 0
    }
    
    /// Add another line of links.
    func appendToWikilinks(_ morelinks: String) {
        guard let def = collection.wikilinksDef else { return }
        let field = getField(label: def.fieldLabel.commonForm)
        if field == nil {
            _ = setWikilinks(morelinks)
        } else {
            let val = field!.value
            if val is WikilinkValue {
                let linksVal = val as! WikilinkValue
                linksVal.append(morelinks)
            }
        }
    }
    
    /// Set the Note's wikilinks value.
    func setWikilinks(_ wikilinks: String) -> Bool {
        guard let def = collection.wikilinksDef else { return false }
        return setField(label: def.fieldLabel.commonForm,
                        value: wikilinks)
    }
    
    func setWikilinks(_ wikilinks: WikilinkValue) -> Bool {
        guard let def = collection.wikilinksDef else { return false }
        let field = NoteField()
        field.def = def
        field.value = wikilinks
        return setField(field)
    }
    
    func setWikiLinks(wikiLinks: [WikiLink]) -> Bool {
        guard let def = collection.wikilinksDef else { return false }
        let wikiLinkValue = WikilinkValue()
        wikiLinkValue.set(wikiLinks: wikiLinks)
        let field = NoteField()
        field.def = def
        field.value = wikiLinkValue
        return setField(field)
    }
    
    /// Return the Note's wikilinks value.
    public var wikilinks: WikilinkValue {
        guard let def = collection.wikilinksDef else { return WikilinkValue("") }
        let val = getFieldAsValue(def: def)
        if val is WikilinkValue {
            return val as! WikilinkValue
        } else {
            return WikilinkValue(val.value)
        }
    }
    
    //
    // Return last name first.
    //
    
    public var lastNameFirst: String {
        var lnf = ""
        switch collection.lastNameFirstConfig {
        case .author:
            lnf = author.lastNameFirst
        case .person:
            lnf = person.lastNameFirst
        case .title:
            let pv = PersonValue(title.value)
            lnf = pv.lastNameFirst
        case .kindPlusPerson:
            let kind = getFieldAsString(label: "kind")
            if kind == "org" {
                if person.isEmpty {
                    lnf = title.value
                } else {
                    lnf = person.value
                }
            } else {
                if person.isEmpty {
                    let pv = PersonValue(title.value)
                    lnf = pv.lastNameFirst
                } else {
                    lnf = person.value
                }
            }
        case .kindPlusTitle:
            let kind = getFieldAsString(label: "kind")
            if kind == "org" {
                lnf = title.value
            } else {
                let pv = PersonValue(title.value)
                lnf = pv.lastNameFirst
            }
        }
        return lnf
    }
    
    //
    // Functions and variables concerning the Note's author, artist or creator.
    //
    
    /// Return the Creator: either Author or Artist
    public var creatorValue: String {
        let val = getFieldAsValue(def: collection.creatorFieldDef)
        return val.value
    }
    
    /// Return the appropriate sort key for an artist or author.
    public var creatorSortKey: String {
        return creator.sortKey
    }
    
    /// Return the Creator: either Author or Artist
    public var creator: StringValue {
        let val = getFieldAsValue(def: collection.creatorFieldDef)
        if val is ArtistValue {
            return val as! ArtistValue
        } else if val is AuthorValue {
            return val as! AuthorValue
        } else {
            return ArtistValue(val.value)
        }
    }
    
    /// Does this note have a non-blank Artist field?
    func hasArtist() -> Bool {
        return artist.count > 0
    }
    
    /// Return the Note's Artist Value
    public var artist: ArtistValue {
        let val = getFieldAsValue(label: NotenikConstants.artist)
        if val is ArtistValue {
            return val as! ArtistValue
        } else {
            return ArtistValue(val.value)
        }
    }
    
    /// Does this note have a non-blank Author field?
    func hasAuthor() -> Bool {
        return author.count > 0
    }
    
    /// Set the note's author value.
    public func setAuthor(_ author: String) -> Bool {
        if collection.authorDef != nil {
            return setField(label: collection.authorDef!.fieldLabel.properForm, value: author)
        } else {
            return setField(label: NotenikConstants.author, value: author)
        }
    }
    
    /// Return the Note's Person Value
    public var author: AuthorValue {
        var val: StringValue?
        if collection.authorDef != nil {
            val = getFieldAsValue(def: collection.authorDef!)
        } else {
            val = getFieldAsValue(label: NotenikConstants.author)
        }
        if val == nil {
            return AuthorValue()
        } else if val is AuthorValue {
            return val as! AuthorValue
        } else {
            return AuthorValue(val!.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's person field.
    //
    
    /// Return the appropriate sort key for a person
    public var personSortKey: String {
        return person.sortKey
    }
    
    /// Does this note have a non-blank Person field?
    func hasPerson() -> Bool {
        return person.count > 0
    }
    
    /// Set the note's person value.
    public func setPerson(_ person: String) -> Bool {
        return setField(label: NotenikConstants.person, value: person)
    }
    
    /// Return the Note's Person Value
    public var person: PersonValue {
        var val: StringValue?
        if collection.personDef != nil {
            val = getFieldAsValue(def: collection.personDef!)
        }
        if val == nil {
            val = getFieldAsValue(label: NotenikConstants.person)
        }
        if val == nil {
            return PersonValue()
        } else if val is PersonValue {
            return val as! PersonValue
        } else {
            return PersonValue(val!.value)
        }
    }
    
    //
    // Functions and variables concerning a Note's fields describing a creative work.
    //
    
    /// Does this note have a non-blank work title field?
    func hasWorkTitle() -> Bool {
        return workTitle.count > 0
    }
    
    /// Return the Note's Work Title Value
    public var workTitle: WorkTitleValue {
        let val = getFieldAsValue(def: collection.workTitleFieldDef)
        if val is WorkTitleValue {
            return val as! WorkTitleValue
        } else {
            return WorkTitleValue(val.value)
        }
    }
    
    public var workLink: LinkValue {
        let val = getFieldAsValue(def: collection.workLinkFieldDef)
        if val is LinkValue {
            return val as! LinkValue
        } else {
            return LinkValue(val.value)
        }
    }
    
    public var workType: WorkTypeValue {
        let val = getFieldAsValue(def: collection.workTypeFieldDef)
        if val is WorkTypeValue {
            return val as! WorkTypeValue
        } else {
            return WorkTypeValue(val.value)
        }
    }
    
    //
    // Functions and variables concerning the Note's body.
    //
    
    /// Does this note have a non-blank body?
    public func hasBody() -> Bool {
        return body.count > 0
    }
    
    /// Set the Note's Body value
    public func setBody(_ body: String) -> Bool {
        return setField(label: collection.bodyFieldDef.fieldLabel.commonForm, value: body)
    }
    
    /// Return the Body of the Note
    public var body: LongTextValue {
        let val = getFieldAsValue(label: collection.bodyFieldDef.fieldLabel.commonForm)
        if val is LongTextValue {
            return val as! LongTextValue
        } else {
            return LongTextValue(val.value)
        }
    }
    
    /// Get the body field, if one exists
    public func getBodyAsField() -> NoteField? {
        return getField(label: collection.bodyFieldDef.fieldLabel.commonForm)
    }
    
    //
    // Functions and variables for Body Check Box Updates.
    //
    
    public var checkBoxUpdates: [String: Bool] = [:]
    
    public var hasCheckBoxUpdates: Bool {
        return !checkBoxUpdates.isEmpty
    }
    
    public func clearCheckBoxUpdates() {
        checkBoxUpdates = [:]
    }
    
    public func checkBoxCountStr(count: Int) -> String {
        return String(format: "%03d", count)
    }
    
    public func checkBoxName(count: Int) -> String {
        return "checkbox-\(checkBoxCountStr(count: count))"
    }
    
    public func applyCheckBoxUpdates() -> Bool {
        guard !checkBoxUpdates.isEmpty else { return false }
        var work = body.value
        guard !work.isEmpty else { return false }
        var replacements = 0
        var ckBoxCount = 0
        var i = work.startIndex
        var ckBox = CkBoxInMarkdown()
        while i < work.endIndex {
            let c = work[i]
            var inc = 1
            switch c {
            case "*", "+", "-":
                ckBox = CkBoxInMarkdown()
                ckBox.dashPosition = i
            case "[":
                if ckBox.dashPosition != nil {
                    ckBox.leftBracketPosition = i
                    ckBox.length = 1
                }
            case " ":
                if ckBox.leftBracketPosition != nil {
                    ckBox.length += 1
                }
            case "x", "X":
                if ckBox.leftBracketPosition != nil {
                    ckBox.length += 1
                }
            case "]":
                if ckBox.leftBracketPosition != nil {
                    ckBox.rightBracketPosition = i
                    ckBox.length += 1
                    ckBoxCount += 1
                    let ckBoxName = checkBoxName(count: ckBoxCount)
                    var repStr = "[ ]"
                    if let checked = checkBoxUpdates[ckBoxName] {
                        if checked {
                            repStr = "[X]"
                        }
                        work.replaceSubrange(ckBox.leftBracketPosition!...ckBox.rightBracketPosition!, with: repStr)
                        inc = 3 - ckBox.length + 1
                        replacements += 1
                    }
                }
                ckBox = CkBoxInMarkdown()
            default:
                if ckBox.dashPosition != nil {
                    ckBox = CkBoxInMarkdown()
                }
            }
            i = work.index(i, offsetBy: inc)
        }
        
        checkBoxUpdates = [:]
        
        if replacements > 0 {
            _ = setBody(work)
            return true
        } else {
            return false
        }
    }
    
    func contains(def: FieldDefinition) -> Bool {
        let field = fields[def.fieldLabel.commonForm]
        return field != nil && field!.value.hasData
    }
    
    /// See if the note contains a field with the given label.
    ///
    /// - Parameter label: A string label expressed in either its proper or common form.
    /// - Returns: True if the note has such a field and the value is non-blank, false otherwise.
    func contains(label: String) -> Bool {
        let fieldLabel = FieldLabel(label)
        let field = fields[fieldLabel.commonForm]
        return field != nil && field!.value.hasData
    }
    
    /// Get the field for the passed label, and return the field value as a string
    func getFieldAsString(label: String) -> String {
        let field = getField(label: label)
        if field == nil {
            return ""
        } else {
            return field!.value.value
        }
    }
    
    func getFieldAsValue(def: FieldDefinition) -> StringValue {
        guard let field = getField(def: def) else { return StringValue("")}
        return field.value
    }
    
    /// Return the value for the Note field identified by the passed label.
    ///
    /// - Parameter label: The label identifying the desired field.
    /// - Returns: A StringValue or one of its descendants
    func getFieldAsValue(label: String) -> StringValue {
        let field = getField(label: label)
        if field == nil {
            return StringValue("")
        } else {
            return field!.value
        }
    }
    
    /// Get the Note Field for a particular label
    public func getField(label: String) -> NoteField? {
        let fieldLabel = FieldLabel(label)
        return fields[fieldLabel.commonForm]
    }
    
    public func getField(common: String) -> NoteField? {
        return fields[common]
    }
    
    /// Get the Note Field for a particular Field Definition
    ///
    /// - Parameter def: A Field Definition (typically from a Field Dictionary)
    /// - Returns: The corresponding field within this Note, if one exists for this definition
    public func getField(def: FieldDefinition) -> NoteField? {
        return fields[def.fieldLabel.commonForm]
    }
    
    /// Remove the specified field from the Note.
    /// - Parameter def: The Field Definition for the field to be removed. 
    public func removeField(def: FieldDefinition) {
        fields[def.fieldLabel.commonForm] = nil
    }
    
    /// Get the Note Field for a particular Field Label.
    /// - Parameter fieldLabel: The Field Label of interest.
    /// - Returns: The Note Field having that label, or nil if unable to match. 
    public func getField(fieldLabel: FieldLabel) -> NoteField? {
        return fields[fieldLabel.commonForm]
    }
    
    /// Return the first field of the specified type, ignoring the label.
    func getFieldByType(def: FieldDefinition) -> NoteField? {
        let desiredType = def.fieldType.typeString
        for field in fields {
            if field.value.def.fieldType.typeString == desiredType {
                return field.value
            }
        }
        return nil
    }
    
    /// Force the addition of a Tag field. A singular Tag field is used as part of the
    /// Tags Explosion logic. 
    func addTag(value: String) {

        var fieldLabel = FieldLabel(NotenikConstants.tag)
        var def = collection.getDef(label: &fieldLabel, allowDictAdds: true)
        if def == nil {
            let fieldType = StringType()
            let typeCat = AllTypes()
            def = FieldDefinition(typeCatalog: typeCat)
            def!.fieldLabel = fieldLabel
            def!.fieldType = fieldType
        }

        let val = StringValue(value)
        let field = NoteField(def: def!, value: val)
        fields[NotenikConstants.tagCommon] = field
    }
    
    
    /// Add a field to the note, given a definition and a String value.
    ///
    /// - Parameters:
    ///   - def: A Field Definition for this field.
    ///   - strValue: A String containing the intended value for this field.
    /// - Returns: True if added successfully, false otherwise.
    func addField(def: FieldDefinition, strValue: String) -> Bool {
        let field = NoteField(def: def, value: strValue,
                              statusConfig: collection.statusConfig,
                              levelConfig: collection.levelConfig)
        return addField(field)
    }
    
    /// Add a field to the note.
    ///
    /// - Parameter field: A complete Note Field, including definition and value.
    /// - Returns: True if added successfully, false otherwise.
    func addField(_ field : NoteField) -> Bool {
        if collection.dict.contains(field.def) {
            if fields[field.def.fieldLabel.commonForm] != nil {
                /// field is already part of the note -- can't add it
                return false
            } else {
                /// Add field that's already present in the dictionary
                fields[field.def.fieldLabel.commonForm] = field
                return true
            }
        } else if collection.dict.locked {
            /// If field not already in dictionary, and dictionary is locked, then we can't add it
            return false
        } else {
            /// Add the field to the dictionary and the note
            let def = collection.dict.addDef(field.def)!
            fields[def.fieldLabel.commonForm] = field
            return true
        }
    }
    
    /// Set a Note field given a label and a value
    public func setField(label: String, value: String) -> Bool {
        var def: FieldDefinition?
        def = collection.dict.getDef(label)
        if def == nil {
            def = FieldDefinition(typeCatalog: collection.typeCatalog, label: label)
        }
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

        return setField(field)
    }
    
    /// Set the indicated field to the passed Note Field
    ///
    /// - Parameter field: The Note field we want to set.
    /// - Returns: True if the field was set, false otherwise.
    public func setField(_ field: NoteField) -> Bool {
        
        if (field.def.fieldType.typeString == "status"
            && field.value.value.count > 0
            && field.value is StatusValue) {
            let statusVal = field.value as! StatusValue
            if statusVal.getInt() == 0 {
                statusVal.set(str: field.value.value, config: collection.statusConfig)
            }
        }
        
        if collection.dict.contains(field.def) {
            fields[field.def.fieldLabel.commonForm] = field
            return true
        } else if collection.dict.locked {
            /// If field not already in dictionary, and dictionary is locked, then we can't add it
            return false
        } else {
            /// Add the field to the dictionary and the note
            let def = collection.dict.addDef(field.def)!
            fields[def.fieldLabel.commonForm] = field
            return true
        }
    }
    
    public func display() {
        print(" ")
        print ("Note.display")
        for def in collection.dict.list {
            print ("Field Label - Proper: \(def.fieldLabel.properForm), common: \(def.fieldLabel.commonForm), type: \(def.fieldType)")
            let field = fields[def.fieldLabel.commonForm]
            if field == nil {
                print(" - No value found for this field for this Note")
            } else {
                let val = field!.value
                print("  - Type  = " + String(describing: type(of: val)))
                print("  - Value = " + val.value)
            }
        }
    }
}
