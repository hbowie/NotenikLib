//
//  CollectionRelocation.swift
//  NotenikLib
//
//  Created by Herb Bowie on 11/26/20.
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// An object that moves or copies a Collection from one path to another.
public class CollectionRelocation {
    
    var fromPath = ""
    var fromIO = FileIO()
    var fromCollection: NoteCollection?
    var fromDict = FieldDictionary()
    var fromFullPath = ""
    var fromNotesPath = ""
    var fromExt = ""
    
    var toPath = ""
    var toIO = FileIO()
    var toCollection: NoteCollection?
    var toDict = FieldDictionary()
    var toNotesPath = ""
    
    var move = false
    
    var errors = 0
    var notesWritten = 0
    
    public init() {
        
    }
    
    /// Copy or Move a Collection from one path to another.
    /// - Parameters:
    ///   - from: The path we're copying/moving from.
    ///   - to: The path we're copying/moving to.
    ///   - move: True to perform a move, which will delete the old Collection.
    public func copyOrMoveCollection(from: String, to: String, move: Bool = false) -> Bool {
        
        // Save parms
        fromPath = from
        toPath = to
        self.move = move
        
        // Init counters
        errors = 0
        notesWritten = 0
        
        // Open the input Collection
        fromIO = FileIO()
        let realm = fromIO.getDefaultRealm()
        realm.path = ""
        fromCollection = fromIO.openCollection(realm: realm, collectionPath: from)
        guard fromCollection != nil else {
            logError("Problems opening the from collection at " + fromPath)
            return false
        }
        fromDict = fromCollection!.dict
        fromFullPath = fromCollection!.fullPath
        fromNotesPath = fromCollection!.notesPath
        fromExt = fromCollection!.preferredExt
        
        // Open the output Collection
        guard FileUtils.ensureFolder(forDir: toPath) else {
            logError("Problems creating the to folder at " + toPath)
            return false
        }
        toIO = FileIO()
        guard toIO.initCollection(realm: realm, collectionPath: toPath) else {
            logError("Could not open requested output folder at \(toPath) as a new Notenik collection")
            return false
        }
        toCollection = toIO.collection!
        toDict = toCollection!.dict
        toNotesPath = toCollection!.notesPath
        
        toCollection!.noteType = fromCollection!.noteType
        toCollection!.idFieldDef = fromCollection!.idFieldDef.copy()
        toCollection!.sortParm = fromCollection!.sortParm
        toCollection!.sortDescending = fromCollection!.sortDescending
        toCollection!.statusConfig = fromCollection!.statusConfig
        toCollection!.preferredExt = fromCollection!.preferredExt
        toCollection!.otherFields = fromCollection!.otherFields
        toCollection!.notesSubFolder = fromCollection!.notesSubFolder
        let caseMods = ["u", "u", "l"]
        for def in fromDict.list {
            let proper = def.fieldLabel.properForm
            let toProper = StringUtils.wordDemarcation(proper, caseMods: caseMods, delimiter: " ")
            let toLabel = FieldLabel(toProper)
            let toDef = FieldDefinition()
            toDef.fieldLabel = toLabel
            toDef.typeCatalog = def.typeCatalog
            toDef.fieldType = def.fieldType
            _ = toDict.addDef(toDef)
        }
        guard toIO.newCollection(collection: toCollection!) else {
            logError("Could not open requested output folder at \(toPath) as a new Notenik collection")
            return false
        }
        logInfo("New Collection successfully initialized at \(toPath)")
        
        // Copy/move the notes between Collections.
        var (nextNote, position) = fromIO.firstNote()
        while nextNote != nil {
            let fromNote = nextNote!
            let toNote = Note(collection: toCollection!)
            for def in fromDict.list {
                let toDef = toDict.getDef(def.fieldLabel.commonForm)
                if toDef != nil {
                    let field = fromNote.getField(def: toDef!)
                    if field != nil && field!.value.count > 0 {
                        let toField = NoteField()
                        toField.def = toDef!
                        toField.value = field!.value
                        _ = toNote.addField(toField)
                    }
                }
            }
            toNote.setID()
            toNote.fileInfo.ext = toCollection!.preferredExt
            toNote.fileInfo.format = .notenik
            toNote.fileInfo.genFileName()
            let (added, toPosition) = toIO.addNote(newNote: toNote)
            if added == nil || toPosition.index < 0 {
                errors += 1
                logError("Note titled \(toNote.title.value) could not be saved to the to collection")
            } else {
                notesWritten += 1
                copyAttachments(fromNote: fromNote, toNote: toNote)
                if move {
                    let removed = FileUtils.removeItem(at: fromNote.fileInfo.url)
                    if !removed {
                        errors += 1
                    }
                }
            }
            
            (nextNote, position) = fromIO.nextNote(position)
        }
        
        // Let's carry along any timestamp aliases.
        toIO.importAliasList(from: fromIO)
        
        // Now let's close the I/O modules for the from and to collections. 
        fromIO.closeCollection()
        toIO.closeCollection()
        
        // If we moved the notes successfully, then let's remove
        // the standard Collection files and folders left in the
        // old location.
        if move && errors == 0 {
            removeFromItem(itemName: NotenikConstants.infoFileName)
            removeFromItem(itemName: NotenikConstants.readmeFileName)
            removeFromItem(itemName: NotenikConstants.templateFileName + "." + fromExt)
            if fromItemExists(itemName: NotenikConstants.aliasFileName) {
                removeFromItem(itemName: NotenikConstants.aliasFileName)
            }
            if fromItemExists(itemName: NotenikConstants.oldSourceParms) {
                removeFromItem(itemName: NotenikConstants.oldSourceParms)
            }
            copySubfolder(folderName: NotenikConstants.reportsFolderName, move: move)
            copySubfolder(folderName: NotenikConstants.mirrorFolderName, move: move)
            if fromItemExists(itemName: NotenikConstants.filesFolderName) {
                if fromItemIsEmpty(itemName: NotenikConstants.filesFolderName) {
                    removeFromItem(itemName: NotenikConstants.filesFolderName)
                }
            }
            if fromItemIsEmpty(itemName: "") {
                removeFromItem(itemName: "")
            }
        }
        
        return errors == 0
    }
    
    /// Copy any attachments from the first Note to the second.
    func copyAttachments(fromNote: Note, toNote: Note) {
        for attachment in fromNote.attachments {
            let attachmentURL = fromIO.getURLforAttachment(attachmentName: attachment)
            if attachmentURL != nil {
                let attached = toIO.addAttachment(from: attachmentURL!, to: toNote, with: attachment.suffix)
                if attached {
                    if move {
                        let removed = FileUtils.removeItem(at: attachmentURL)
                        if !removed {
                            errors += 1
                        }
                    }
                } else {
                    errors += 1
                }
            }
        }
    }
    
    /// Does the file or folder in the From collection exist?
    func fromItemExists(itemName: String) -> Bool {
        return FileManager.default.fileExists(atPath: fromItemPath(itemName))
    }
    
    /// Is the specified folder empty?
    func fromItemIsEmpty(itemName: String) -> Bool {
        return FileUtils.isEmpty(fromItemPath(itemName))
    }
    
    /// Delete the named file or folder from the from location.
    func removeFromItem(itemName: String) {
        if !FileUtils.removeItem(at: fromItemPath(itemName)) {
            errors += 1
        }
    }
    
    /// Get the path of an item in the From Collection's folder.
    func fromItemPath(_ itemName: String) -> String {
        if itemName.count == 0 {
            return fromFullPath
        } else {
            return makeFromFilePath(fileName: itemName)
        }
    }
    
    /// Try to copy a subfolder from the old collection to the new one.
    func copySubfolder(folderName: String, move: Bool = false) {
        
        let fromFolderPath = makeFromFilePath(fileName: folderName)
        guard FileUtils.isDir(fromFolderPath) else { return }
        let fromFolderURL = URL(fileURLWithPath: fromFolderPath)
        
        let toFolderPath = makeToFilePath(fileName: folderName)
        let toFolderURL = URL(fileURLWithPath: toFolderPath)
        
        do {
            try FileManager.default.copyItem(at: fromFolderURL, to: toFolderURL)
            if move {
                try FileManager.default.removeItem(at: fromFolderURL)
            }
        } catch {
            logError("Problems moving subfolder named \(folderName)")
            errors += 1
        }
    }
    
    func makeFromFilePath(fileName: String) -> String {
        return FileUtils.joinPaths(path1: fromNotesPath, path2: fileName)
    }
    
    func makeToFilePath(fileName: String) -> String {
        return FileUtils.joinPaths(path1: toNotesPath, path2: fileName)
    }
    
    /// Log an error message.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "CollectionRelocation",
                          level: .error,
                          message: msg)
    }
    
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "CollectionRelocation",
                          level: .info,
                          message: msg)
    }
    
}
