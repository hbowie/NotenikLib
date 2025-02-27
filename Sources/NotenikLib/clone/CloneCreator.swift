//
//  CloneCreator.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/20/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).

import Foundation

import NotenikUtils

/// Utility class to clone a project/collection.
public class CloneCreator {

    let fm = FileManager.default
    
    var returnMsg = ""
    var returnCount = 0
    
    /// Create a new instance.
    public init() {
        
    }
    
    /// Clone the source to the destination.
    /// - Parameters:
    ///   - source: The location of the input project/collection.
    ///   - destination: The location for the output.
    ///   - parms: Clone parameters
    /// - Returns: An error message, if any erros, and a count of files created.
    public func clone(source: URL, destination: URL, parms: CloneParms) -> (String, Int) {
        
        print("CloneCreator.clone(source: \(source), destination: \(destination), parms: \(parms))")
        
        returnMsg = ""
        returnCount = 0
        
        processFolder(source: source, destination: destination, path: "")
        
        return (returnMsg, returnCount)
    }
    
    /// Process the initial folder or a subfolder.
    /// - Parameters:
    ///   - source: The source folder/subfolder.
    ///   - destination: The topmost destination for the output.
    ///   - path: The current path from the top to the current subfolder. Blank for the initial folder.
    func processFolder(source: URL, destination: URL, path: String) {
        
        let folderName = source.lastPathComponent.lowercased()
        
        // Skip certain folders, based on their names.
        switch folderName {
        case "assets", "files", "fonts", "images", "includes-gen", "quick-export", "web", "xpltags":
            return
        default:
            if folderName.hasSuffix(".bbprojectd") {
                return
            } else if folderName.hasSuffix(".app") {
                return
            }
            break
        }
        
        // Obtain the contents of the folder.
        var contents: [URL] = []
        do {
            contents = try fm.contentsOfDirectory(at: source,
                                                  includingPropertiesForKeys: nil,
                                                  options: [.skipsHiddenFiles])
        } catch {
            logError("Could not read contents of directory at \(source)")
            return
        }
        
        // Create the output folder.
        var newDir: URL?
        
        if contents.count > 0 && !path.isEmpty {
            newDir = destination.appendingPathComponent(path)
            do {
                try fm.createDirectory(at: newDir!, withIntermediateDirectories: true)
            } catch {
                returnMsg = "Could not create output folder(s)"
                return
            }
        }
        
        var folderType: CloneFolderType = .other
        
        // Assign a folder type, based on the folder's contents.
        var noteFileExt = "txt"
        for item in contents {
            let fileName = item.lastPathComponent
            let nameOnly = item.deletingPathExtension().lastPathComponent
            switch fileName {
            case NotenikConstants.infoParentFileName:
                folderType = .project
            case NotenikConstants.infoProjectFileName:
                folderType = .project
            case NotenikConstants.infoFileName:
                folderType = .notenik
            default:
                if nameOnly == NotenikConstants.templateFileName {
                    noteFileExt = item.pathExtension
                }
            }
        }
        
        if folderType == .other && (folderName == "templates" || source.path.contains("factory")) {
            folderType = .factory
        }
        
        // Determine location for output files.
        var outDir: URL
        if newDir == nil {
            outDir = destination
        } else {
            outDir = newDir!
        }
        
        // If this is a Notenik Collection, open it as such.
        let io: NotenikIO = FileIO()
        var collection: NoteCollection? = nil
        
        if folderType == .notenik {
            let realm = io.getDefaultRealm()
            realm.path = ""
            collection = io.openCollection(realm: realm,
                                           collectionPath: source.path,
                                           readOnly: true,
                                           multiRequests: nil)
            if collection == nil {
                logError("Problems opening the collection at " + source.path)
                return
            }
            
            let writer = KeyValueWriter()
            writer.append(label: collection!.titleFieldDef.fieldLabel.properForm,
                              value: "Sample Note")
            writer.appendLong(label: collection!.bodyFieldDef.fieldLabel.properForm,
                                  value: "This is a sample note. Feel free to delete it after you have added a few of your own.")
            let outURL = outDir.appendingPathComponent("Sample Note.\(noteFileExt)")
            let writeOK = writer.write(toFile: outURL.path)
            if !writeOK {
                logError("Failed to write sample note")
            }
        }
        
        for item in contents {
            var isDirectory: ObjCBool = false
            if fm.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    let newPath = FileUtils.joinPaths(path1: path, path2: item.lastPathComponent)
                    processFolder(source: item, destination: destination, path: newPath)
                } else {
                    processFile(folderType: folderType,
                                noteFileExt: noteFileExt,
                                fileURL: item,
                                outDir: outDir,
                                collection: collection)
                }
            }
        }
        
        if path.isEmpty {
            let kvw = KeyValueWriter()
            kvw.open()
            kvw.appendTitle(destination.lastPathComponent)
            kvw.append(label: NotenikConstants.seq, value: "999")
            kvw.appendLong(label: NotenikConstants.teaser, value: "XXX")
            kvw.appendLong(label: NotenikConstants.body, value: " ")
            kvw.close()
            let starterInfoURL = outDir.appendingPathComponent(NotenikConstants.infoStarterFileName)
            let starterInfoOK = kvw.write(toFile: starterInfoURL.path)
            if !starterInfoOK {
                logError("Could not write Starter Info file to \(starterInfoURL)")
            }
        }
    } // End processFolder
    
    func processFile(folderType: CloneFolderType,
                     noteFileExt: String,
                     fileURL: URL,
                     outDir: URL,
                     collection: NoteCollection?) {
        
        let fileName = fileURL.lastPathComponent
        let ext = fileURL.pathExtension
        let nameOnly = fileURL.deletingPathExtension().lastPathComponent
        switch ext {
        case "bbprojectd", "csv", "eot", "graffle", "ics", "tab", "ttf", "webloc", "woff", "woff2":
            return
        case "html", "htm", "json", "xml":
            if folderType == .project || folderType == .other {
                return
            }
        default:
            break
        }
        
        let dstURL = outDir.appendingPathComponent(fileURL.lastPathComponent)
        
        if folderType == .project
            && (fileName == NotenikConstants.infoParentFileName
                || fileName == NotenikConstants.infoProjectFileName) {
            writeInfoProjectFile(outDir: outDir)
        } else if (folderType == .project || folderType == .other)
                    && (fileName == "LICENSE.md" || fileName == "README.md") {
            // Skip GitHub License files and README files
        } else if folderType == .notenik && fileName == NotenikConstants.infoFileName {
            writeInfoFile(outDir: outDir, collection: collection!)
        } else if folderType == .notenik
                    && nameOnly != NotenikConstants.templateFileName
                    && ext == noteFileExt {
            // Skip copying actual notes
        } else if fileName == NotenikConstants.aliasFileName {
            // skip any alias files
        } else if fileName == "- temp-HTML.html" {
            // skip any temp html files
        } else if fileName == NotenikConstants.infoStarterFileName {
            // skip it
        } else {
            do {
                try fm.copyItem(at: fileURL, to: dstURL)
                returnCount += 1
            } catch {
                logError("Failed to copy \(fileURL) to \(outDir.appendingPathComponent(fileURL.lastPathComponent)): \(error)")
            }
        }
    }
    
    func writeInfoProjectFile(outDir: URL) {
        let writer = KeyValueWriter()
        writer.append(label: NotenikConstants.title,
                      value: "To Be Determined")
        let outURL = outDir.appendingPathComponent(NotenikConstants.infoProjectFileName)
        let writeOK = writer.write(toFile: outURL.path)
        if !writeOK {
            logError("Failed to write Info Project File")
        }
    }
    
    func writeInfoFile(outDir: URL, collection: NoteCollection) {
        let maker = InfoLineMaker()
        maker.putInfo(collection: collection,
                      bunch: nil,
                      cloning: true,
                      cloneTitle: outDir.lastPathComponent)
        
        let outURL = outDir.appendingPathComponent(NotenikConstants.infoFileName)
        let writeOK = maker.write(toFile: outURL.path)
        if !writeOK {
            logError("Failed to write Info File")
        }
    }
    
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CloneCreator", level: .error, message: msg)
    }
    
    enum CloneFolderType {
        case factory
        case project
        case notenik
        case other
    }
}
