//
//  NoteCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2019-2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Information about a collection of Notes.
public class NoteCollection {
    
    public  var title       = ""
            var realm       : Realm
            var noteType    : NoteType = .general
    public  var dict        : FieldDictionary
    public  var sortParm    : NoteSortParm
            var sortDescending: Bool
    public  var typeCatalog  = AllTypes()
    public  var statusConfig: StatusValueConfig
    public  var preferredExt: String = "txt"
    public  var otherFields = false
    public  var readOnly    : Bool = false
            var customFields: [SortField] = []
            var hasTimestamp = false
    public  var isRealmCollection = false
            var noteFileFormat: NoteFileFormat = .toBeDetermined
    public  var mirror:         NoteTransformer?
    public  var mirrorAutoIndex = false

    public  var bodyLabel = true
    public  var h1Titles = false
    public  var lastStartupDate = ""
            var todaysDate = ""
    
    // Store some key and singular field definitions for easy access.
    public  var idFieldDef:     FieldDefinition
    public  var titleFieldDef:  FieldDefinition
    public  var tagsFieldDef:   FieldDefinition
    public  var linkFieldDef:   FieldDefinition
    public  var dateFieldDef:   FieldDefinition
    public  var recursFieldDef: FieldDefinition
    public  var statusFieldDef: FieldDefinition
    public  var seqFieldDef:    FieldDefinition
    public  var indexFieldDef:  FieldDefinition
    public  var creatorFieldDef: FieldDefinition
    public  var workLinkFieldDef: FieldDefinition
    public  var workTitleFieldDef: FieldDefinition
    public  var workTypeFieldDef: FieldDefinition
    public  var bodyFieldDef:   FieldDefinition
    public  var dateAddedFieldDef: FieldDefinition?
    
            var pickLists:     [FieldDefinition] = []
    
    /// Default initialization of a new Collection.
    public init () {
        realm = Realm()
        dict = FieldDictionary()
        
        idFieldDef =     FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.title)
        titleFieldDef =  FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.title)
        tagsFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.tags)
        linkFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.link)
        dateFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.date)
        recursFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.recurs)
        statusFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.status)
        seqFieldDef =    FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.seq)
        indexFieldDef =  FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.index)
        workTitleFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workTitle)
        workTypeFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workType)
        workLinkFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workLink)
        creatorFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.artist)
        bodyFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.body)
        
        sortParm = .title
        sortDescending = false
        statusConfig = StatusValueConfig()
        
        let today = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        todaysDate = format.string(from: today)
    }
    
    /// Convenience initialization that identifies the Realm. 
    public convenience init (realm: Realm) {
        self.init()
        self.realm = realm
    }
    
    /// Get and set a path for the collection.
    public  var path: String {
        get {
            return _path
        }
        set {
            _path = newValue
            setPaths()
        }
    }
    var _path        = ""
    
    /// Indicate whether the notes reside in a subfolder named notes.
    public var notesSubFolder: Bool {
        get {
            return _notesSubfolder
        }
        set {
            _notesSubfolder = newValue
            setPaths()
        }
    }
    var _notesSubfolder  = false
    
    /// Set paths
    func setPaths() {
        fullPathURL = FileIO.urlFrom(realm: realm, path: _path)
        guard fullPathURL != nil else { return }
        fullPath = fullPathURL!.path
        parentURL = fullPathURL!.deletingLastPathComponent()
        if _notesSubfolder {
            notesPath = FileUtils.joinPaths(path1: fullPath,
                                            path2: NotenikConstants.notesFolderName)
            notesPathURL = URL(fileURLWithPath: notesPath)
        } else {
            notesPath = fullPath
            notesPathURL = fullPathURL
        }
    }
    
    public private(set) var fullPath    = ""
    public private(set) var fullPathURL:  URL?
    public private(set) var notesPath   = ""
    public private(set) var notesPathURL: URL?
    public private(set) var parentURL:    URL?
    
    /// Is this today's first startup?
    public var startupToday: Bool {
        return lastStartupDate != todaysDate
    }
    
    /// Record the info that we've had a successful startup for today.
    public func startedUp() {
        lastStartupDate = todaysDate
    }
    
    /// Set this Collection's title from its URL. 
    public func setTitleFromURL(_ url: URL) {
        let folderIndex = url.pathComponents.count - 1
        let parentIndex = folderIndex - 1
        let folder = url.pathComponents[folderIndex]
        let parent = url.pathComponents[parentIndex]
        if parent == "Documents" {
            title = folder
        } else if folder == "notes" {
            title = parent
        } else {
            title = parent + " " + folder
        }
    }
    
    /// Set new values for the Status Value configuration. 
    public func setStatusConfig(_ options: String) {
        
        statusConfig.set(options)
        
        typeCatalog.statusValueConfig = statusConfig
        
        var statusLabel = FieldLabel(NotenikConstants.status)
        let fieldDef = getDef(label: &statusLabel, allowDictAdds: false)
        if fieldDef != nil {
            if let statusType = fieldDef!.fieldType as? StatusType {
                statusType.statusValueConfig = statusConfig
            }
        }
    }
    
    /// Attempt to obtain or create a Field Definition for the given Label.
    ///
    /// Note that the Collection's Field Dictionary may be updated as part of this call.
    ///
    /// - Parameter label: A field label. The validLabel field will be updated as part of this call.
    /// - Returns: A Field Definition for this Label, if the label is valid, otherwise nil.
    func getDef(label: inout FieldLabel, allowDictAdds: Bool = true) -> FieldDefinition? {
        label.validLabel = false
        var def: FieldDefinition? = nil
        if label.commonForm.count > 48 {
            // Too long
        } else if (label.commonForm == "http"
            || label.commonForm == "https"
            || label.commonForm == "ftp"
            || label.commonForm == "mailto") {
            // Let's not confuse a URL with a field label
        } else if dict.contains(label) {
            label.validLabel = true
            def = dict.getDef(label)
        } else if label.commonForm == NotenikConstants.dateAddedCommon
            && dict.locked &&  allowDictAdds {
            label.validLabel = true
            dict.unlock()
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            dict.lock()
        } else if label.commonForm == NotenikConstants.dateModifiedCommon
                    && dict.locked &&  allowDictAdds {
            label.validLabel = true
            dict.unlock()
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            dict.lock()
        } else if dict.locked || !allowDictAdds {
            // Can't add any additional labels
        } else if label.isTitle || label.isTags || label.isLink || label.isBody || label.isDateAdded || label.isDateModified {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
        } else if noteType == .simple {
            // No other labels allowed for simple notes
        } else if label.isAuthor
                || label.isCode
                || label.isDate
                || label.isIndex
                || label.isRating
                || label.isRecurs
                || label.isSeq
                || label.isStatus
                || label.isTeaser
                || label.isType
                || label.isWorkTitle {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
        } else if noteType == .expanded {
            // No other labels allowed for expanded notes
        } else {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
        }
        return def
    }
    
    /// Finalize things after all dictionary definitions have been loaded. 
    func finalize() {
        pickLists = []
        for def in dict.list {
            if def.pickList != nil {
                pickLists.append(def)
            }
        }
    }
    
    /// Useful for debugging. 
    public func display() {
        print(" ")
        print("Collection info")
        print("  - Title: \(title)")
        print("  - Preferred ext: \(preferredExt)")
        print("  - ID Field: \(idFieldDef.fieldLabel.properForm)")
        print("  - Title Field: \(titleFieldDef.fieldLabel.properForm)")
        print("  - Tags Field: \(tagsFieldDef.fieldLabel.properForm)")
        print("  - Link Field: \(linkFieldDef.fieldLabel.properForm)")
        print("  - Date Field: \(dateFieldDef.fieldLabel.properForm)")
        print("  - Recurs Field: \(recursFieldDef.fieldLabel.properForm)")
        print("  - Status Field: \(statusFieldDef.fieldLabel.properForm)")
        print("  - Seq Field: \(seqFieldDef.fieldLabel.properForm)")
        print("  - Index Field: \(indexFieldDef.fieldLabel.properForm)")
        print("  - Work Title Field: \(workTitleFieldDef)")
        print("  - Work Type Field: \(workTypeFieldDef)")
        print("  - Work Link Field: \(workLinkFieldDef)")
        print("  - Creator Field: \(creatorFieldDef.fieldLabel.properForm)")
        print("  - Body Field: \(bodyFieldDef.fieldLabel.properForm)")
        print("  - Has time stamp? \(hasTimestamp)")
        print("  - Field Definitions: ")
        for def in dict.list {
            var choices = 0
            var pickerStr = ""
            if def.pickList != nil {
                choices = def.pickList!.count
                pickerStr = ", pick list count: \(choices)"
            }
            print("    - Label: \(def.fieldLabel.properForm), common: \(def.fieldLabel.commonForm), type: \(def.fieldType.typeString)\(pickerStr)")
        }
    }
}
