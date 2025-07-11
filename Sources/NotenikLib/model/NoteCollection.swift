//
//  NoteCollection.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown

import NotenikUtils

/// Information about a collection of Notes.
public class NoteCollection {
    
    public  var title       = ""
    public  var titleSetByUser = false
    public  var shortcut    = ""
    public  var folder      = ""
    public  var lib:          ResourceLibrary!
    public  var duplicates  = 0
            var noteType    : NoteType = .general
    public  var dict        : FieldDictionary
    public  var sortParm    : NoteSortParm
    public  var lastNameFirstConfig : LastNameFirstConfig = .title
    public  var sortDescending: Bool
    public  var sortBlankDatesLast = true
    public  var typeCatalog  = AllTypes()
    public  var statusConfig: StatusValueConfig
    public  var rankConfig:   RankValueConfig
    public  var levelConfig:  IntWithLabelConfig
    public  var preferredExt: String = "txt"
    public  var otherFields = false
    public  var readOnly    : Bool = false
            var customFields: [SortField] = []
    public  var hasTimestamp = false
    public  var isRealmCollection = false
    public  var noteFileFormat: NoteFileFormat = .toBeDetermined
    public  var hashTagsOption: HashtagsOption = .notenikField
    public  var mirror:       NoteTransformer?
    public  var mirrorAutoIndex = false
    public  var lastImportParent = ""
    public  var lastAttachmentParent: URL? = nil
    public  var forceStandardDisplay = false
    
    public  var dailyNotesType: DailyNotesType = .none
    public  var essential = false
    public  var general = false

    public  var bodyLabel = true
    public  var titleDisplayOption: LineDisplayOption = .pBold
    public  var displayMode: DisplayMode = .normal
    public  var outlineTabSetting: OutlineTabSetting = .none
    public  var overrideCustomDisplay = false
    public  var displayTemplate = ""
    public  var displayCSS = ""
    
    public  var cssFiles: [String] = []
    public  var selCSSfile = ""
    
    public var  shareTemplates: [String] = []
    public var  selShareTemplate = ""
    
    public  var addins: [URL] = []
    
    public  var mathJax = false
    public  var imgLocal = false
    public  var missingTargets = false
    public  var curlyApostrophes = true
    public  var extLinksOpenInNewWindows = false
    public  var scrollingSync = false
    public  var lastStartupDate = ""
            var todaysDate = ""
    
    public  var seqFormatter =  SeqFormatter()
    public  var linkFormatter = LinkFormatter()
    
    public  var noteIdentifier = NoteIdentifier()
    
    // Store some key and singular field definitions for easy access.
    public  var addressFieldDef: FieldDefinition?
    public  var directionsFieldDef: FieldDefinition?
    public  var idFieldDef:      FieldDefinition
    public  var titleFieldDef:   FieldDefinition
    public  var akaFieldDef:     FieldDefinition?
    public  var tagsFieldDef:    FieldDefinition
    public  var linkFieldDef:    FieldDefinition
    public  var dateFieldDef:    FieldDefinition
    public  var recursFieldDef:  FieldDefinition
    public  var statusFieldDef:  FieldDefinition
    public  var rankFieldDef:    FieldDefinition?
    public  var levelFieldDef:   FieldDefinition?
    public  var seqFieldDef:     FieldDefinition?
    public  var seqTimeOfDayFieldDef: FieldDefinition?
    public  var durationFieldDef: FieldDefinition?
    public  var displaySeqFieldDef: FieldDefinition?
    public  var folderFieldDef:  FieldDefinition?
    public  var klassFieldDef:   FieldDefinition?
    public  var includeChildrenDef: FieldDefinition?
    public  var attribFieldDef:  FieldDefinition?
    public  var indexFieldDef:   FieldDefinition?
    public  var backlinksDef:    FieldDefinition?
    public  var wikilinksDef:    FieldDefinition?
    public  var creatorFieldDef: FieldDefinition
    public  var workLinkFieldDef: FieldDefinition
    public  var workTitleFieldDef: FieldDefinition
    public  var workTypeFieldDef: FieldDefinition
    public  var teaserFieldDef: FieldDefinition?
    public  var textFormatFieldDef: FieldDefinition?
    public  var bodyFieldDef:   FieldDefinition
    public  var dateAddedFieldDef: FieldDefinition?
    public  var datePickedFieldDef: FieldDefinition?
    public  var imageNameFieldDef: FieldDefinition?
    public  var imageDarkFieldDef: FieldDefinition?
    public  var minutesToReadDef: FieldDefinition?
    public  var shortIdDef:     FieldDefinition?
    
    public  var personDef:      FieldDefinition?
    public  var authorDef:      FieldDefinition?
    
    public  var pageStyleDef:   FieldDefinition?
    
    public  var newLabelForTitle = ""
    public  var newLabelForBody  = ""
    
            var creatorFound = false
    
            var dateCount = 0
            var linkCount = 0
    
            var comboDefs:      [FieldDefinition] = []
            var pickLists:      [FieldDefinition] = []
    
            var lookupDefs:     [FieldDefinition] = []
            var lookBackDefs:   [FieldDefinition] = []
    
    public  var klassDefs:     [KlassDef] = []
    public  var lastNewKlass   = ""
    public  var webBookPath    = ""
    public  var webBookAsEPUB  = true
    public  var tocDepth       = 3
    
    public  var idToParse      = ""
    public  var textToParse    = ""
    public  var fileNameToParse = ""
    public  var shortID        = ""
    public  var tocNoteID      = ""
    public  var skipContentsForParent = false
    
    public  var mkdownCommandList = MkdownCommandList(collectionLevel: true)
    
    public  var windowPosStr   = ""
    public  var columnWidths   = ColumnWidths()
    
    public  var minBodyEditViewHeight: Float = 5.0
    
    public  var notePickerAction = ""
    
    public  var highestSeq: SeqValue?
    
    public  var sortBySeq: Bool {
        switch sortParm {
        case .seqPlusTitle:
            return true
        case .tasksBySeq:
            return true
        default:
            return false
        }
    }
    
    public var indexOfCollection: IndexCollection?
    public var indexPageID = ""
    public var lastIndexTermKey: String = ""
    public var lastIndexTermPageIx: Int = -1
    public var lastIndexTermPageCount: Int = 0
    public var lastIndexedPageID = ""
    
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
        rankConfig = RankValueConfig()
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
        
        personDef = nil
        authorDef = nil
        durationFieldDef = nil
        folderFieldDef = nil
        creatorFound = false
        pageStyleDef = nil

        dateCount = 0
        linkCount = 0
    }
    
    /// Convenience initialization that identifies the Realm. 
    public convenience init (realm: Realm) {
        self.init()
        lib.realm = realm
    }
    
    public func userFacingLabel(below: URL? = nil) -> String {

        if titleSetByUser {
            return title
        } else if let url = lib.notesFolder.url {
            return AppPrefs.shared.idFolderFrom(url: url, below: below)
        } else {
            return "Error(s) identifying the Collection"
        }
    }
    
    public func setDefaultTitle() {
        title = defaultTitle
        titleSetByUser = false
    }
    
    /// Construct a user-facing label for the Collection.
    public var defaultTitle: String {
        if let url = lib.notesFolder.url {
            return AppPrefs.shared.idFolderFrom(url: url)
        } else {
            return ""
        }
    }
    
    /// Get and set a path for the collection.
    public  var path: String {
        get {
            return lib.getPath(type: .collection)
        }
        set {
            lib.pathWithinRealm = newValue
            folder = ""
            let url = lib.getURL(type: .collection)
            if url != nil {
                let nLink = NotenikLink(url: url!)
                folder = nLink.folder
            }
        }
    }
    
    public var fullPath: String {
        return lib.getPath(type: .collection)
    }
    
    public var fullPathURL: URL? {
        return lib.getURL(type: .collection)
    }
    
    /// Based on the folder path, and throwing out common rubbish, generate
    /// a semi-unique, hopefully meaningful identifier for the collection. 
    public var externalID: String {
        guard let collectionURL = lib.getURL(type: .collection) else { return "" }
        let pathComponents = collectionURL.pathComponents
        var id = ""
        for pathComponent in pathComponents {
            guard pathComponent != "/" else { continue }
            guard pathComponent != "Users" else { continue }
            guard pathComponent != "Documents" else { continue }
            guard pathComponent != "Library" else { continue }
            guard pathComponent != "Mobile Documents" else { continue }
            guard pathComponent != "com~apple~CloudDocs" else { continue }
            guard pathComponent != "Dropbox" else { continue }
            guard !pathComponent.contains("Cloud") else { continue }
            if !id.isEmpty {
                id.append("-")
            }
            id.append(StringUtils.toCommonFileName(pathComponent))
        }
        return id
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
    
    public func setCategoryConfig(_ options: String) {
        
        rankConfig.set(options)
        
        typeCatalog.rankValueConfig = rankConfig
        
        var categoryLabel = FieldLabel(NotenikConstants.rank)
        let fieldDef = getDef(label: &categoryLabel, allowDictAdds: false)
        if fieldDef != nil {
            if let categoryType = fieldDef!.fieldType as? RankType {
                categoryType.rankValueConfig = rankConfig
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
    
    public func setFileFormat(format: String) {
        switch format {
        case "nnk", "Notenik", "notenik":
            noteFileFormat = .notenik
        case "yaml", "YAML", "YAML Frontmatter":
            noteFileFormat = .yaml
        case "mmd", "multimarkdown", "MultiMarkdown":
            noteFileFormat = .multiMarkdown
        case "md", "markdown", "Markdown":
            noteFileFormat = .markdown
        case "txt", "plain text", "Plain Text":
            noteFileFormat = .plainText
        default:
            noteFileFormat = .notenik
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
                || label.isFolder
                || label.isIndex
                || label.isLevel
                || label.isPerson
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
            
        case NotenikConstants.addressCommon:
            if addressFieldDef == nil {
                addressFieldDef = def
            }
            
        case NotenikConstants.akaCommon:
            akaFieldDef = def
        
        case NotenikConstants.artistCommon:
            creatorFieldDef = def
            creatorFound = true
            
        case NotenikConstants.attribCommon:
            attribFieldDef = def
            
        case NotenikConstants.authorCommon:
            authorDef = def
            creatorFieldDef = def
            creatorFound = true
            
        case NotenikConstants.backlinksCommon:
            backlinksDef = def
            
        case NotenikConstants.bodyCommon:
            if bodyFieldDef.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                bodyFieldDef = def
            }
            
        case NotenikConstants.rankCommon:
            if rankFieldDef == nil {
                rankFieldDef = def
            }
        
        case NotenikConstants.dateCommon:
            dateCount += 1
            if dateCount == 1 {
                dateFieldDef = def
            }
            
        case NotenikConstants.directionsCommon:
            if directionsFieldDef == nil {
                directionsFieldDef = def
            }
            
        case NotenikConstants.durationCommon:
            if durationFieldDef == nil {
                durationFieldDef = def
            }
            
        case NotenikConstants.folderCommon:
            folderFieldDef = def
            
        case NotenikConstants.imageNameCommon:
            if imageNameFieldDef == nil {
                imageNameFieldDef = def
            } else if imageDarkFieldDef == nil && def.fieldLabel.commonForm.contains("dark") {
                imageDarkFieldDef = def
            }
            
        case NotenikConstants.includeChildrenCommon:
            includeChildrenDef = def
            
        case NotenikConstants.indexCommon:
            if indexFieldDef == nil {
                indexFieldDef = def
            }
            
        case NotenikConstants.klassCommon:
            if klassFieldDef == nil {
                klassFieldDef = def
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
            
        case NotenikConstants.personCommon:
            if personDef == nil {
                personDef = def
            }
            
        case NotenikConstants.recursCommon:
            if recursFieldDef.fieldLabel.commonForm == NotenikConstants.recursCommon {
                recursFieldDef = def
            }
            
        case NotenikConstants.seqCommon:
            if seqFieldDef == nil {
                seqFieldDef = def
            } else if seqTimeOfDayFieldDef == nil && def.fieldLabel.commonForm.contains("time") {
                seqTimeOfDayFieldDef = def
            }
            
        case NotenikConstants.displaySeqCommon:
            if displaySeqFieldDef == nil {
                displaySeqFieldDef = def
            }
            
        case NotenikConstants.teaserCommon:
            if teaserFieldDef == nil {
                teaserFieldDef = def
            }
            
        case NotenikConstants.textFormatCommon:
            if textFormatFieldDef == nil {
                textFormatFieldDef = def
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
            
        case NotenikConstants.datePickedCommon:
            datePickedFieldDef = def
            
        case NotenikConstants.pageStyleCommon:
            pageStyleDef = def
            
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
        
        if dict.dict["kind"] != nil {
            if personDef == nil {
                lastNameFirstConfig = .kindPlusTitle
            } else {
                lastNameFirstConfig = .kindPlusPerson
            }
        } else if personDef != nil {
            lastNameFirstConfig = .person
        } else if authorDef != nil && authorDef != titleFieldDef {
            lastNameFirstConfig = .author
        } else {
            lastNameFirstConfig = .title
        }
        
        determineSpecialFlags()
    }
    
    public func determineSpecialFlags() {
        let collectionURL = lib.getURL(type: .collection)
        general   = (collectionURL == AppPrefs.shared.generalURL)
        essential = (collectionURL == AppPrefs.shared.essentialURL)
    }
    
    /// Copy info such as field definitions from this Collection to another. This will
    /// be a shallow and incomplete copy. 
    func copyImportantInfo(to collection2: NoteCollection) {
        let dict2 = collection2.dict
        for (_, def) in dict.dict {
            _ = dict2.addDef(def)
        }
    }
    
    /// This is a short identifier meant for internal use.
    public var collectionID: String {
        if !shortcut.isEmpty {
            return shortcut
        } else {
            return folder
        }
    }
    
    public func registerSeq(_ noteSeq: SeqValue) {
        guard seqFieldDef != nil else { return }
        if highestSeq == nil || highestSeq! < noteSeq {
            highestSeq = noteSeq.dupe()
        }
    }
    
    var highestTitleNumber = 0
    
    public func nextTitleNumber() -> Int {
        highestTitleNumber += 1
        return highestTitleNumber
    }
    
    public func setLastImportParent(url: URL) {
        if #available(macOS 13.0, *) {
            lastImportParent = url.path()
        } 
    }
    
    public func getLastImportParent() -> URL? {
        if lastImportParent.isEmpty {
            return nil
        } else {
            return URL(fileURLWithPath: lastImportParent)
        }
    }
    
    public func makeLinkRelative(startingLink: String) -> String {
        
        if startingLink.hasPrefix("file://") || startingLink.hasPrefix("/") || startingLink.hasPrefix("mailto:") {
            if let collectionURL = lib.getURL(type: .collection) {
                let collectionFileName = FileName(collectionURL.absoluteString)
                let fileName = FileName(startingLink)
                if fileName.isBeneath(collectionFileName) {
                    return collectionFileName.makeRelative(fileName2: fileName)
                }
            }
        }
        return startingLink
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
        if displaySeqFieldDef != nil {
            print("  - Seq Alt Field: \(displaySeqFieldDef!.fieldLabel.properForm)")
        }
        if klassFieldDef != nil {
            print("  - Class Field: \(klassFieldDef!.fieldLabel.properForm)")
        }
        if includeChildrenDef != nil {
            print("  - Include Children Field: \(includeChildrenDef!.fieldLabel.properForm)")
        }
        if indexFieldDef != nil {
            print("  - Index Field: \(indexFieldDef!.fieldLabel.properForm)")
        }
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
