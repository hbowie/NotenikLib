//
//  NoteCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2019-2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Information about a collection of Notes.
public class NoteCollection {
    
    public var path  = ""
    public var title = ""
    var realm        : Realm
    var noteType     : NoteType = .general
    public var dict  : FieldDictionary
    var idRule       : NoteIDRule
    public var sortParm : NoteSortParm
    var sortDescending: Bool
    public var typeCatalog  = AllTypes()
    public var statusConfig : StatusValueConfig
    public var preferredExt : String = "txt"
    public var otherFields  = false
    public var readOnly     : Bool = false
    var customFields : [SortField] = []
    var hasTimestamp = false
    var isRealmCollection = false
    var noteFileFormat: NoteFileFormat = .toBeDetermined
    public var mirror:         NoteTransformer?
    public var mirrorAutoIndex = false
    public var bodyLabel = true
    public var h1Titles = false
    public var lastStartupDate = ""
    var todaysDate = ""
    
    /// Default initialization of a new Collection.
    public init () {
        realm = Realm()
        dict = FieldDictionary()
        idRule = NoteIDRule.fromTitle
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
    
    public var collectionFullPathURL: URL? {
        var collectionURL: URL
        if realm.path == "" || realm.path == " " {
            collectionURL = URL(fileURLWithPath: path)
        } else {
            let realmURL = URL(fileURLWithPath: realm.path)
            collectionURL = realmURL.appendingPathComponent(path)
        }
        return collectionURL
    }
    
    /// The complete path to this collection, represented as a String
    public var collectionFullPath: String {
        if realm.path == "" || realm.path == " " {
            return path
        } else {
            return FileUtils.joinPaths(path1: realm.path, path2: path)
        }
    }
    
    /// Make a complete path to a file residing within this collection
    func makeFilePath(fileName: String) -> String {
        return FileUtils.joinPaths(path1: collectionFullPath, path2: fileName)
    }
    
    /// Is this today's first startup?
    public var startupToday: Bool {
        return lastStartupDate != todaysDate
    }
    
    /// Record the info that we've had a successful startup for today.
    public func startedUp() {
        lastStartupDate = todaysDate
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
        } else if label.commonForm == LabelConstants.dateAddedCommon
            && dict.locked &&  allowDictAdds {
            label.validLabel = true
            dict.unlock()
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            dict.lock()
        } else if dict.locked || !allowDictAdds {
            // Can't add any additional labels
        } else if label.isTitle || label.isTags || label.isLink || label.isBody || label.isDateAdded {
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
}
