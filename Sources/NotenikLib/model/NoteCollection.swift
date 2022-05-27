//
//  NoteCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2019-2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Information about a collection of Notes.
public class NoteCollection {
    
    public  var title       = ""
    public  var shortcut    = ""
    public  var lib:          ResourceLibrary!
    public  var duplicates  = 0
            var noteType    : NoteType = .general
    public  var dict        : FieldDictionary
    public  var hasLookupFields = false
    public  var sortParm    : NoteSortParm
            var sortDescending: Bool
    public  var typeCatalog  = AllTypes()
    public  var statusConfig: StatusValueConfig
    public  var levelConfig:  IntWithLabelConfig
    public  var preferredExt: String = "txt"
    public  var otherFields = false
    public  var readOnly    : Bool = false
            var customFields: [SortField] = []
    public  var hasTimestamp = false
    public  var isRealmCollection = false
            var noteFileFormat: NoteFileFormat = .toBeDetermined
            var hashTags    : Bool = false
    public  var mirror:       NoteTransformer?
    public  var mirrorAutoIndex = false

    public  var bodyLabel = true
    public  var titleDisplayOption: LineDisplayOption = .pBold
    public  var streamlined = false
    public  var mathJax = false
    public  var imgLocal = false
    public  var missingTargets = false
    public  var curlyApostrophes = true
    public  var lastStartupDate = ""
            var todaysDate = ""
    
    public  var displayTemplate = ""
    public  var displayCSS = ""
    
    public  var seqFormatter = SeqFormatter()
    
    // Store some key and singular field definitions for easy access.
    public  var idFieldDef:     FieldDefinition
    public  var titleFieldDef:  FieldDefinition
    public  var akaFieldDef:    FieldDefinition?
    public  var tagsFieldDef:   FieldDefinition
    public  var linkFieldDef:   FieldDefinition
    public  var dateFieldDef:   FieldDefinition
    public  var recursFieldDef: FieldDefinition
    public  var statusFieldDef: FieldDefinition
    public  var levelFieldDef:  FieldDefinition?
    public  var seqFieldDef:    FieldDefinition?
    public  var klassFieldDef:  FieldDefinition?
    public  var includeChildrenDef: FieldDefinition?
    public  var attribFieldDef: FieldDefinition?
    public  var indexFieldDef:  FieldDefinition
    public  var backlinksDef:   FieldDefinition?
    public  var wikilinksDef:   FieldDefinition?
    public  var creatorFieldDef: FieldDefinition
    public  var workLinkFieldDef: FieldDefinition
    public  var workTitleFieldDef: FieldDefinition
    public  var workTypeFieldDef: FieldDefinition
    public  var teaserFieldDef: FieldDefinition?
    public  var bodyFieldDef:   FieldDefinition
    public  var dateAddedFieldDef: FieldDefinition?
    public  var imageNameFieldDef: FieldDefinition?
    public  var minutesToReadDef: FieldDefinition?
    public  var shortIdDef:     FieldDefinition?
    
            var authorDef:     FieldDefinition?
            var creatorFound = false
    
            var dateCount = 0
            var linkCount = 0
    
            var comboDefs:     [FieldDefinition] = []
            var pickLists:     [FieldDefinition] = []
    public  var klassDefs:     [KlassDef] = []
    public  var lastNewKlass   = ""
    public  var webBookPath    = ""
    public  var webBookAsEPUB  = true
    
    public  var titleToParse   = ""
    public  var tocNoteID      = ""
    public  var windowPosStr   = ""
    
    /// Default initialization of a new Collection.
    public init () {
        lib = ResourceLibrary()
        dict = FieldDictionary()
        
        idFieldDef =     FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.title)
        titleFieldDef =  FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.title)
        tagsFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.tags)
        linkFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.link)
        dateFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.date)
        recursFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.recurs)
        statusFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.status)
        indexFieldDef =  FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.index)
        workTitleFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workTitle)
        workTypeFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workType)
        workLinkFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workLink)
        creatorFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.artist)
        bodyFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.body)
        
        sortParm = .title
        sortDescending = false
        statusConfig = StatusValueConfig()
        levelConfig  = IntWithLabelConfig()
        
        let today = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        todaysDate = format.string(from: today)
    }
    
    func resetFieldInfo() {
        idFieldDef =     FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.title)
        titleFieldDef =  FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.title)
        tagsFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.tags)
        linkFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.link)
        dateFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.date)
        recursFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.recurs)
        statusFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.status)
        indexFieldDef =  FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.index)
        workTitleFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workTitle)
        workTypeFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workType)
        workLinkFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.workLink)
        creatorFieldDef = FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.artist)
        bodyFieldDef =   FieldDefinition(typeCatalog: typeCatalog, label: NotenikConstants.body)
        
        authorDef = nil
        creatorFound = false

        dateCount = 0
        linkCount = 0
    }
    
    /// Convenience initialization that identifies the Realm. 
    public convenience init (realm: Realm) {
        self.init()
        lib.realm = realm
    }
    
    /// Get and set a path for the collection.
    public  var path: String {
        get {
            return lib.getPath(type: .collection)
        }
        set {
            lib.pathWithinRealm = newValue
        }
    }
    
    public var fullPath: String {
        return lib.getPath(type: .collection)
    }
    
    public var fullPathURL: URL? {
        return lib.getURL(type: .collection)
    }
    
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
    
    public func setLevelConfig(_ configString: String) {
        
        levelConfig.set(configString)
        
        typeCatalog.levelValueConfig = levelConfig
        
        var levelLabel = FieldLabel(NotenikConstants.level)
        let fieldDef = getDef(label: &levelLabel, allowDictAdds: false)
        if fieldDef != nil {
            if let levelType = fieldDef!.fieldType as? LevelType {
                levelType.config = levelConfig
            }
        }
    }
    
    
    /// Populate the field dictionary of a new Collection, using the definitions from this Collection.
    /// - Parameter to: The new Collection whose dictionary is to be populated. 
    public func populateFieldDefs(to: NoteCollection) {
        var i = 0
        while i < dict.count {
            if let def = dict.getDef(i) {
                if let result = to.dict.addDef(def) {
                    to.registerDef(result)
                }
            }
            i += 1
        }
        to.finalize()
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
            registerDef(def)
            dict.lock()
        } else if label.commonForm == NotenikConstants.dateModifiedCommon
                    && dict.locked &&  allowDictAdds {
            label.validLabel = true
            dict.unlock()
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            registerDef(def)
            dict.lock()
        } else if dict.locked || !allowDictAdds {
            // Can't add any additional labels
        } else if label.isTitle || label.isTags || label.isLink || label.isBody || label.isDateAdded || label.isDateModified {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            registerDef(def)
        } else if noteType == .simple {
            // No other labels allowed for simple notes
        } else if label.isAuthor
                || label.isCode
                || label.isDate
                || label.isIndex
                || label.isLevel
                || label.isRating
                || label.isRecurs
                || label.isSeq
                || label.isStatus
                || label.isTeaser
                || label.isType
                || label.isWorkTitle
                || label.isShortId {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            registerDef(def)
        } else if noteType == .expanded {
            // No other labels allowed for expanded notes
        } else {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            registerDef(def)
        }
        return def
    }
    
    /// Keep track of the first or only field definitions of various types with special functionality.
    public func registerDef(_ newDef: FieldDefinition?) {
        
        guard let def = newDef else { return }
        
        if def.fieldLabel.commonForm == NotenikConstants.authorCommon
            || def.fieldLabel.commonForm == NotenikConstants.artistCommon {
            authorDef = def
        } else if def.fieldLabel.commonForm == NotenikConstants.klassCommon
                    || def.fieldLabel.commonForm == "klass" {
            if klassFieldDef == nil {
                klassFieldDef = def
            }
        }
        
        switch def.fieldType.typeString {
            
        case NotenikConstants.akaCommon:
            akaFieldDef = def
        
        case NotenikConstants.artistCommon:
            creatorFieldDef = def
            creatorFound = true
            
        case NotenikConstants.attribCommon:
            attribFieldDef = def
            
        case NotenikConstants.authorCommon:
            creatorFieldDef = def
            creatorFound = true
            
        case NotenikConstants.backlinksCommon:
            backlinksDef = def
            
        case NotenikConstants.bodyCommon:
            if bodyFieldDef.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                bodyFieldDef = def
            }
        
        case NotenikConstants.dateCommon:
            dateCount += 1
            if dateCount == 1 {
                dateFieldDef = def
            }
            
        case NotenikConstants.imageNameCommon:
            if imageNameFieldDef == nil {
                imageNameFieldDef = def
            }
            
        case NotenikConstants.includeChildrenCommon:
            includeChildrenDef = def
            
        case NotenikConstants.indexCommon:
            if indexFieldDef.fieldLabel.commonForm == NotenikConstants.indexCommon {
                indexFieldDef = def
            }
            
        case NotenikConstants.linkCommon:
            linkCount += 1
            if linkCount == 1 {
                linkFieldDef = def
            }
            
        case NotenikConstants.minutesToReadCommon:
            if minutesToReadDef == nil {
                minutesToReadDef = def
            }
            
        case NotenikConstants.recursCommon:
            if recursFieldDef.fieldLabel.commonForm == NotenikConstants.recursCommon {
                recursFieldDef = def
            }
            
        case NotenikConstants.seqCommon:
            if seqFieldDef == nil {
                seqFieldDef = def
            }
            
        case NotenikConstants.teaserCommon:
            if teaserFieldDef == nil {
                teaserFieldDef = def
            }
            
        case NotenikConstants.levelCommon:
            if levelFieldDef == nil {
                levelFieldDef = def
            }
            
        case NotenikConstants.shortIdCommon:
            if shortIdDef == nil {
                shortIdDef = def
            }
            
        case NotenikConstants.statusCommon:
            if statusFieldDef.fieldLabel.commonForm == NotenikConstants.statusCommon {
                statusFieldDef = def
            }
            
        case NotenikConstants.tagsCommon:
            if tagsFieldDef.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                tagsFieldDef = def
            }
            
        case NotenikConstants.timestampCommon:
            hasTimestamp = true
            if dateAddedFieldDef == nil {
                dateAddedFieldDef = def
            }
            
        case NotenikConstants.titleCommon:
            if idFieldDef.fieldLabel.commonForm == NotenikConstants.titleCommon {
                idFieldDef = def
            }
            if titleFieldDef.fieldLabel.commonForm == NotenikConstants.titleCommon {
                titleFieldDef = def
            }
            
        case NotenikConstants.wikilinksCommon:
            wikilinksDef = def
            
        case NotenikConstants.workLinkCommon:
            workLinkFieldDef = def
            
        case NotenikConstants.workTitleCommon:
            workTitleFieldDef = def
            
        case NotenikConstants.workTypeCommon:
            workTypeFieldDef = def
            
        case NotenikConstants.dateAddedCommon:
            dateAddedFieldDef = def
            
        default:
            break
            
        }
    }
    
    /// Finalize things after all dictionary definitions have been loaded. 
    func finalize() {
        comboDefs = []
        pickLists = []
        for def in dict.list {
            if def.comboList != nil {
                comboDefs.append(def)
            }
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
        print("  - File Format: \(noteFileFormat)")
        if akaFieldDef != nil {
            print("  - AKA Field: \(akaFieldDef!.fieldLabel.properForm)")
        }
        print("  - Path: \(path)")
        print("  - Preferred ext: \(preferredExt)")
        print("  - ID Field: \(idFieldDef.fieldLabel.properForm)")
        print("  - Title Field: \(titleFieldDef.fieldLabel.properForm)")
        print("  - Tags Field: \(tagsFieldDef.fieldLabel.properForm)")
        print("  - Link Field: \(linkFieldDef.fieldLabel.properForm)")
        print("  - Date Field: \(dateFieldDef.fieldLabel.properForm)")
        print("  - Recurs Field: \(recursFieldDef.fieldLabel.properForm)")
        print("  - Status Field: \(statusFieldDef.fieldLabel.properForm)")
        if levelFieldDef != nil {
            print("  - Level Field: \(levelFieldDef!.fieldLabel.properForm)")
        }
        if seqFieldDef != nil {
            print("  - Seq Field: \(seqFieldDef!.fieldLabel.properForm)")
        }
        if klassFieldDef != nil {
            print("  - Class Field: \(klassFieldDef!.fieldLabel.properForm)")
        }
        if includeChildrenDef != nil {
            print("  - Include Children Field: \(includeChildrenDef!.fieldLabel.properForm)")
        }
        print("  - Index Field: \(indexFieldDef.fieldLabel.properForm)")
        if backlinksDef != nil {
            print("  - Backlinks Field: \(backlinksDef!.fieldLabel.properForm)")
        }
        if wikilinksDef != nil {
            print("  - Wikilinks Field: \(wikilinksDef!.fieldLabel.properForm)")
        }
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
