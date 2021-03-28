//
//  Note.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A single Note. 
public class Note: Comparable, Identifiable, NSCopying {
    
    public unowned var collection: NoteCollection
    
    var fields = [:] as [String: NoteField]
    public var attachments: [AttachmentName] = []
    
    var _envCreateDate = ""
    var _envModDate    = ""
    
    public var fileInfo: NoteFileInfo!
    
    /// Initialize with a Collection
    public init (collection: NoteCollection) {
        self.collection = collection
        fileInfo = NoteFileInfo(note: self)
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
                let dateAddedValue = dateAdded
                if dateAddedValue.value.count == 0 {
                    _ = setDateAdded(newValue)
                }
            }
            let timestampDef = collection.dict.getDef(NotenikConstants.timestamp)
            if timestampDef != nil {
                if !self.contains(label: NotenikConstants.timestamp) {
                    let timestamp = TimestampValue(newValue)
                    let timestampField = NoteField(def: timestampDef!, value: timestamp)
                    fields[timestampDef!.fieldLabel.commonForm] = timestampField
                    setID()
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
                let dateModifiedValue = dateModified
                let dateModNewValue = DateValue(newValue)
                if dateModifiedValue.value.count == 0
                        || dateModNewValue > dateModifiedValue {
                    _ = setDateModified(newValue)
                }
            }
        }
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
            let field1 = lhs.getField(def: def)
            var value1 = StringValue()
            if field1 != nil {
                value1 = field1!.value
            }
            let field2 = rhs.getField(def: def)
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
    
    /// Make a copy of this Note
    public func copy(with zone: NSZone? = nil) -> Any {
        let newNote = Note(collection: collection)
        copyFields(to: newNote)
        copyAttachments(to: newNote)
        if !fileInfo.isEmpty {
            newNote.fileInfo.base = fileInfo.base
            newNote.fileInfo.ext  = fileInfo.ext
            newNote.fileInfo.baseDotExt = fileInfo.baseDotExt
        }
        return newNote
    }
    
    /// Copy field values from this Note to a second Note, making sure all fields have
    /// matching definitions and values.
    ///
    /// - Parameter note2: The Note to be updated with this Note's field values.
    public func copyFields(to note2: Note) {

        let dict = collection.dict
        let defs = dict.list
        for definition in defs {
            let field = getField(def: definition)
            let field2 = note2.getField(def: definition)
            if field == nil && field2 == nil {
                // Nothing to do here -- just move on
            } else if field == nil && field2 != nil {
                field2!.value.set("")
            } else if field != nil && field2 == nil {
                _ = note2.addField(def: definition, strValue: field!.value.value)
            } else {
                field2!.value.set(field!.value.value)
            }
        }
        note2.setID()
    }
    
    /// Copy field values from this Note to a second Note, but only copying fields
    /// defined in the second note's collection dictionary. 
    ///
    /// - Parameter note2: The Note to be updated with this Note's field values.
    public func copyDefinedFields(to note2: Note) {

        let toDict = note2.collection.dict
        let toDefs = toDict.list
        for toDef in toDefs {
            var fromField = getField(def: toDef)
            if fromField == nil {
                fromField = getFieldByType(def: toDef)
            }
            let toField = note2.getField(def: toDef)
            if fromField == nil && toField == nil {
                // Nothing to do here -- just move on
            } else if fromField == nil && toField != nil {
                toField!.value.set("")
            } else if fromField != nil && toField == nil {
                _ = note2.addField(def: toDef, strValue: fromField!.value.value)
            } else {
                toField!.value.set(fromField!.value.value)
            }
        }
        note2.setID()
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
     the unique indentifier for this Note
     
     --------------------------------------------------------- */
    
    /// Provide a value to uniquely identify this note within its Collection, and provide
    /// conformance to the Identifiable protocol.
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
    
    func setTimestamp(_ timestamp: String) -> Bool {
        let ok = setField(label: NotenikConstants.timestamp, value: timestamp)
        setID()
        return ok
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
    
    /// Retum the timestamp value
    public var timestamp: TimestampValue {
        let val = getFieldAsValue(label: NotenikConstants.timestamp)
        if val is TimestampValue {
            return val as! TimestampValue
        } else {
            return TimestampValue(val.value)
        }
    }
    
    /// Return a String containing the current sort key for the Note
    var sortKey: String {
        switch collection.sortParm {
        case .title:
            return title.sortKey
        case .seqPlusTitle:
            return seq.sortKey + title.sortKey
        case .tasksByDate:
            return (status.doneX(config: collection.statusConfig)
                + date.sortKey
                + seq.sortKey
                + title.sortKey)
        case .tasksBySeq:
            return (status.doneX(config: collection.statusConfig)
                + seq.sortKey
                + date.sortKey
                + title.sortKey)
        case .tagsPlusTitle:
            return (tags.sortKey
                + title.sortKey
                + status.sortKey)
        case .author:
            return (creatorSortKey
                + date.sortKey
                + title.sortKey)
        case .tagsPlusSeq:
            return (tags.sortKey + " "
                + seq.sortKey + " "
                + title.sortKey)
        case .dateAdded:
            return dateAddedSortKey
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
    
    func hasTimestamp() -> Bool {
        return timestamp.count > 0
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
        setID()
        return ok
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
    
    func getTagsAsField() -> NoteField? {
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
            let linkType = fieldType as? LinkType
            if linkType != nil {
                let linkField = getField(def: definition)
                if linkField != nil {
                    if let linkVal = linkField!.value as? LinkValue {
                        if let linkURL = linkVal.url {
                            return linkURL
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
    // Functions and variables concerning the Note's seq field.
    //
    
    // Does this note have a non-blank Sequence field?
    public func hasSeq() -> Bool {
        return seq.count > 0
    }
    
    /// Set the Note's Sequence value
    public func setSeq(_ seq: String) -> Bool {
        return setField(label: collection.seqFieldDef.fieldLabel.commonForm, value: seq)
    }
    
    /// Return the Note's Sequence Value
    public var seq: SeqValue {
        let val = getFieldAsValue(def: collection.seqFieldDef)
        if val is SeqValue {
            return val as! SeqValue
        } else {
            return SeqValue(val.value)
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
        return setField(label: NotenikConstants.author, value: author)
    }
    
    /// Return the Note's Author Value
    public var author: AuthorValue {
        let val = getFieldAsValue(label: NotenikConstants.author)
        if val is AuthorValue {
            return val as! AuthorValue
        } else {
            return AuthorValue(val.value)
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
    func getField (label: String) -> NoteField? {
        let fieldLabel = FieldLabel(label)
        return fields[fieldLabel.commonForm]
    }
    
    /// Get the Note Field for a particular Field Definition
    ///
    /// - Parameter def: A Field Definition (typically from a Field Dictionary)
    /// - Returns: The corresponding field within this Note, if one exists for this definition
    public func getField(def: FieldDefinition) -> NoteField? {
        return fields[def.fieldLabel.commonForm]
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
    
    
    /// Add a field to the note, given a definition and a String value.
    ///
    /// - Parameters:
    ///   - def: A Field Definition for this field.
    ///   - strValue: A String containing the intended value for this field.
    /// - Returns: True if added successfully, false otherwise.
    func addField(def: FieldDefinition, strValue: String) -> Bool {
        let field = NoteField(def: def, value: strValue, statusConfig: collection.statusConfig)
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
    
    func display() {
        print(" ")
        print ("Note.display")
        for def in collection.dict.list {
            print ("Field Label Proper: \(def.fieldLabel.properForm) + common: \(def.fieldLabel.commonForm) + type: \(def.fieldType)")
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
