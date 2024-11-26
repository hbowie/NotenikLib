//
//  NoteTransformer.swift
//  Notenik
//
//  Created by Herb Bowie on 2/6/20.
//  Copyright © 2020 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// A class that provides mirroring of notes in some alternate format (normally HTML).
public class NoteTransformer {
    
    let fileManager  = FileManager.default
    
    static let cssFolderName        = "css"
    static let cssFileName          = "styles.css"
    static let templatesFolderName  = "templates"
    static let scriptsFolderName    = "scripts"
    static let noteMirrorWords      = ["note", "mirror"]
    static let indexMirrorWords     = ["index", "mirror"]
    static let scriptExtension      = ".tcz"
    static let sampleMirrorTemplate = "note_mirror.html"
    static let indexMirrorTemplate  = "index_mirror.html"
    public static let sampleReportTemplateFileName = "sample report template"
    
    public var dispatchQueue: DispatchQueue
    
    var io: FileIO!
    
    var webRoot = ""
    
    var mirrorContents:     DirContents
    var templatesContents:  DirContents
    var scriptsContents:    DirContents?
    var noteMirrorFileName: FileName
    var noteMirrorURL: URL
    var noteIndexFileNames: [FileName] = []
    var scriptFileNames:    [FileName] = []
    
    let mirrorError = LogEvent(subsystem: "com.powersurgepub.notenik",
                               category: "NoteMirror", level: .error,
                               message: "Problems encountered during mirroring")
    var mirrorErrors: [LogEvent] = []
    
    /// Initializes a new instance of NoteTransformer if the appropriate folders and files can be found. 
    init?(io: NotenikIO) {
        
        /// Set up a default errors list that can be used if necessary.
        mirrorErrors.append(mirrorError)
        
        /// Make sure we have a FileIO instance to work with, because we'll be accessing files and folders. 
        if io is FileIO {
            self.io = io as? FileIO
        } else {
            print("Note Transformer init failed because the provided I/O object is not a FileIO instance.")
            return nil
        }
        
        guard self.io!.collectionOpen else {
            print("Note Transformer init failed because the I/O module is not open.")
            return nil
        }
        
        guard let lib = self.io.collection?.lib else {
            print("Note Transformer init failed because the I/O module does not contain a library.")
            return nil
        }
        
        guard lib.hasAvailable(type: .mirror) else {
            print("Note Transformer init failed because the Collection does not contain a mirror folder.")
            return nil
        }
        
        let mirrorPath = lib.getPath(type: .mirror)
        
        // See if we can get a list of the contents of the mirror folder.
        guard let contents1 = DirContents(path: mirrorPath) else {
            print("Note Transformer init failed because the mirror folder is empty.")
            return nil
        }
        mirrorContents = contents1
        
        // Now see if we can get a list of the contents of the mirror/templates folder.
        guard let contents2 = DirContents(path1: mirrorContents.dirPath,
                                          path2: NoteTransformer.templatesFolderName) else {
            print("Note Transformer init failed because there are no mirror templates.")
            return nil
        }
        templatesContents = contents2
        
        let (mirrorName, _) = templatesContents.firstContaining(words: NoteTransformer.noteMirrorWords)
        guard mirrorName != nil else {
            print("Note Transformer init failed because there was no note mirror template.")
            return nil
        }
        noteMirrorFileName = mirrorName!
        guard let mirrorURL = noteMirrorFileName.url else {
            print("Note Transformer init failed a URL could not be obtained for the note mirror template.")
            return nil
        }
        noteMirrorURL = mirrorURL
    
        var (indexName, index) = templatesContents.firstContaining(words: NoteTransformer.indexMirrorWords)
        while indexName != nil {
            noteIndexFileNames.append(indexName!)
            index += 1
            (indexName, index) = templatesContents.nextContaining(words: NoteTransformer.indexMirrorWords,
                                                                  start: index)
        }
        
        // See if we have any scripts. These are optional.
        scriptsContents = DirContents(path1: mirrorContents.dirPath,
                                          path2: NoteTransformer.scriptsFolderName)
        if scriptsContents != nil {
            var (scriptName, _) = scriptsContents!.firstWithExtension(NoteTransformer.scriptExtension)
            while scriptName != nil {
                scriptFileNames.append(scriptName!)
                index += 1
                (scriptName, index) = scriptsContents!.nextWithExtension(NoteTransformer.scriptExtension,
                                                                         start: index)
            }
        }
        
        let qlabel = "com.powersurgepub.notenik.q4: \(lib.getPath(type: .notes))"
        dispatchQueue = DispatchQueue(label: qlabel,
                                      qos: .userInitiated)
    }
    
    /// Mirror a Note to a Web page using the supplied note and template. 
    public func mirror(note: Note) -> [LogEvent] {
        let list = NotesList()
        list.append(note)
        return mirrorNotesList(list)
    }
    
    /// Mirror the entire list of Notes.
    public func mirrorAllNotes() -> [LogEvent] {
        return mirrorNotesList(io.notesList)
    }
    
    /// Mirror a list of one or more notes using the note mirror template file.
    func mirrorNotesList(_ list: NotesList) -> [LogEvent] {
        
        var errors: [LogEvent] = []
        
        let template = Template()
        
        template.setWebRoot(filePath: webRoot)
        
        var ok = template.openTemplate(templateURL: noteMirrorURL)
        guard ok else {
            let error = LogEvent(subsystem: "com.powersurgepub.notenik",
                                 category: "NoteMirror",
                                 level: .error,
                                 message: "Could Not Open Note Mirror Template file")
            errors.append(error)
            return errors
        }
        
        template.supplyData(notesList: list,
                            dataSource: io.collection!.lib.getPath(type: .notes))
        
        ok = template.generateOutput()
        guard ok else {
            let error = LogEvent(subsystem: "com.powersurgepub.notenik",
                                 category: "NoteMirror",
                                 level: .error,
                                 message: "Could Not Generate Template Output")
            errors.append(error)
            return errors
        }
        
        return errors
    }
    
    /// Let's run through all of the index templates we found. 
    public func rebuildIndices() -> [LogEvent] {
        var errors: [LogEvent] = []
        
        guard let noteIO = io else { return errors }
        guard let collection = noteIO.collection else { return errors }
        
        for indexFileName in noteIndexFileNames {
            let template = Template()
            
            template.setWebRoot(filePath: webRoot)
            
            guard let mirrorURL = indexFileName.url else { return mirrorErrors }

            var ok = template.openTemplate(templateURL: mirrorURL)
            guard ok else {
                let error = LogEvent(subsystem: "com.powersurgepub.notenik",
                                     category: "NoteMirror",
                                     level: .error,
                                     message: "Could Not Open Note Mirror Template file")
                errors.append(error)
                return errors
            }
            
            template.supplyData(notesList: io.notesList,
                                dataSource: collection.lib.getPath(type: .notes))
            
            ok = template.generateOutput()
            guard ok else {
                let error = LogEvent(subsystem: "com.powersurgepub.notenik",
                                     category: "NoteMirror",
                                     level: .error,
                                     message: "Could Not Generate Template Output")
                errors.append(error)
                return errors
            }
        }
        
        for scriptFileName in scriptFileNames {
            
            let scripter = ScriptEngine()
            
            let openCommand = ScriptCommand(workspace: scripter.workspace)
            openCommand.module = .script
            openCommand.action = .open
            openCommand.modifier = "input"
            openCommand.value = scriptFileName.fileNameStr
            scripter.playCommand(openCommand)
            
            let playCommand = ScriptCommand(workspace: scripter.workspace)
            playCommand.module = .script
            playCommand.action = .play
            scripter.playCommand(playCommand)
            
            scripter.close()
        }
        
        return errors
    }
    
    /// Generate sample mirror folders and files. Note that this is sort of a
    /// factory method since, when successful, it returns a good instance
    /// of NoteTransformer..
    public static func genSampleMirrorFolder(io: NotenikIO) -> (NoteTransformer?, String) {
        
        let displayPrefs = DisplayPrefs.shared
        
        var ok = true
        
        // Let's make sure we have what we need to proceed.
        var fileIO: FileIO
        if io is FileIO {
            fileIO = io as! FileIO
        } else {
            return (nil, "I/O Module not a FileIO")
        }
        guard fileIO.collectionOpen else {
            return (nil, "No collection open")
        }
        let collection = io.collection!
        let collectionPath = collection.lib.getPath(type: .notes)
        let dict = collection.dict
        var upToWebFolder = ""
        var downToNotesFolder = ""
        if collection.lib.hasAvailable(type: .notesSubfolder) {
            upToWebFolder = "../"
            downToNotesFolder = "\(NotenikConstants.notesFolderName)/"
        }
        
        _ = collection.lib.ensureResource(type: .mirror)
        
        // First let's create a css styles file.
        var css = ""
        if displayPrefs.displayCSS != nil {
            css = displayPrefs.displayCSS!
        }
        ok = NoteTransformer.writeSampleFile(contents: css,
                                             collectionPath: collectionPath,
                                             folder1: NotenikConstants.mirrorFolderName,
                                             folder2: cssFolderName,
                                             fileName: cssFileName)
        guard ok else {
            return (nil, "Failed to write Sample CSS file")
        }
        
        // Now let's create a sample mirror template.
        var markedup = Markedup(format: .htmlDoc)
        // markedup.notenikIO = io
        markedup.templateNextRec()
        markedup.templateOutput(filename: "\(upToWebFolder)../../=$title&f$=.html")
        markedup.startDoc(withTitle: "=$title$=",
                          withCSS: "\(downToNotesFolder)\(NotenikConstants.mirrorFolderName)/\(cssFolderName)/\(cssFileName)",
                          linkToFile: true)
        markedup.heading(level: 1, text: "=$title$=")
        
        var i = 0
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                if (def!.fieldLabel.commonForm != NotenikConstants.titleCommon) {
                    NoteTransformer.genFieldDisplay(def: def!, io: fileIO, markedup: markedup)
                }
            }
            i += 1
        }
        
        markedup.horizontalRule()
        markedup.startParagraph()
        markedup.startEmphasis()
        markedup.link(text: "Back to Collection Index", path: "index.html")
        markedup.finishEmphasis()
        markedup.finishParagraph()
        
        
        markedup.finishDoc()
        markedup.templateLoop()
        
        ok = NoteTransformer.writeSampleFile(contents: markedup.code,
                                             collectionPath: collectionPath,
                                             folder1: NotenikConstants.mirrorFolderName,
                                             folder2: templatesFolderName,
                                             fileName: sampleMirrorTemplate)
        guard ok else {
            return (nil, "Failed to write sample mirror template")
        }
        
        // Now let's create a sample index template.
        markedup = Markedup(format: .htmlDoc)
        markedup.templateOutput(filename: "\(upToWebFolder)../../index.html")
        markedup.startDoc(withTitle: collection.title,
                          withCSS: "\(downToNotesFolder)\(NotenikConstants.mirrorFolderName)/\(cssFolderName)/\(cssFileName)",
        linkToFile: true)
        markedup.heading(level: 1, text: "Index for \(collection.title)")
        markedup.startUnorderedList(klass: nil)
        markedup.templateNextRec()
        
        markedup.startListItem()
        markedup.link(text: "=$title$=", path: "=$title&f$=.html")
        markedup.finishListItem()
        markedup.newLine()
        
        markedup.templateLoop()
        markedup.finishUnorderedList()
        markedup.finishDoc()

        ok = NoteTransformer.writeSampleFile(contents: markedup.code,
                                             collectionPath: collectionPath,
                                             folder1: NotenikConstants.mirrorFolderName,
                                             folder2: templatesFolderName,
                                             fileName: indexMirrorTemplate)
        guard ok else {
            return (nil, "Could not write sample index template")
        }
        
        let transformer = NoteTransformer(io: fileIO)
        if transformer == nil {
            return (nil, "Could not create NoteTransformer")
        }
        return (transformer, "")
    }
    
    /// Get the markedup used to display this field
    ///
    /// - Parameter def: The field definition to be displayed.
    /// - Parameter io:  The I/O module we're using for this collection.
    /// - Parameter markedup: The Markedup instance to which we're writing the code.
    static func genFieldDisplay(def: FieldDefinition, io: NotenikIO, markedup: Markedup) {

        let mkdownContext = NotesMkdownContext(io: io)
        markedup.writeLine("")
        markedup.templateIfField(fieldname: "=$\(def.fieldLabel.commonForm)$=")
        if def.fieldLabel.commonForm == NotenikConstants.titleCommon {
            markedup.startParagraph()
            markedup.startStrong()
            markedup.append("=$\(def.fieldLabel.commonForm)$=")
            markedup.finishStrong()
            markedup.finishParagraph()
        } else if def.fieldLabel.commonForm == NotenikConstants.tagsCommon {
            markedup.startParagraph()
            markedup.startEmphasis()
            markedup.append("=$\(def.fieldLabel.commonForm)$=")
            markedup.finishEmphasis()
            markedup.finishParagraph()
        } else if def.fieldLabel.commonForm == NotenikConstants.bodyCommon {
            markedup.startParagraph()
            markedup.append(def.fieldLabel.properForm)
            markedup.append(": ")
            markedup.finishParagraph()
            var format = "o"
            // if io.collection!.doubleBracketParsing {
                format = "w1o"
            // }
            markedup.append("=$\(def.fieldLabel.commonForm)&\(format)$=")
            markedup.newLine()
        } else if def.fieldType is LinkType {
            markedup.startParagraph()
            markedup.append(def.fieldLabel.properForm)
            markedup.append(": ")
            markedup.link(text: "=$\(def.fieldLabel.commonForm)$=",
                path: "=$\(def.fieldLabel.commonForm)$=")
            markedup.finishParagraph()
        } else if def.fieldLabel.commonForm == NotenikConstants.codeCommon {
            markedup.startParagraph()
            markedup.append(def.fieldLabel.properForm)
            markedup.append(": ")
            markedup.finishParagraph()
            markedup.codeBlock("=$\(def.fieldLabel.commonForm)$=")
        } else if def.fieldType.typeString == NotenikConstants.longTextType {
            markedup.startParagraph()
            markedup.append(def.fieldLabel.properForm)
            markedup.append(": ")
            markedup.finishParagraph()
            let mkdownOptions = MkdownOptions()
            Markdown.markdownToMarkedup(markdown: "=$\(def.fieldLabel.commonForm)&o$=",
                options: mkdownOptions, mkdownContext: mkdownContext, writer: markedup)
        } else {
            markedup.startParagraph()
            markedup.append(def.fieldLabel.properForm)
            markedup.append(": ")
            markedup.append("=$\(def.fieldLabel.commonForm)$=")
            markedup.finishParagraph()
        }
        markedup.templateEndIf()
    }
    
    /// Generate a sample report template.
    public static func genReportTemplateSample(io: NotenikIO, markdown: Bool = false) -> [LogEvent] {
        var errors: [LogEvent] = []
        
        guard let collection = io.collection else {
            let error = LogEvent(subsystem: "com.powersurgepub.notenik",
                                 category: "NoteTransformer",
                                 level: .error,
                                 message: "Collection not available")
            errors.append(error)
            return errors
        }
        let dict = collection.dict
        let fields = dict.list
        
        guard let sampleURL = NoteTransformer.getReportTemplateSampleURL(io: io, markdown: markdown) else {
            let error = LogEvent(subsystem: "com.powersurgepub.notenik",
                                 category: "NoteTransformer",
                                 level: .error,
                                 message: "Reports folder path not available")
            errors.append(error)
            return errors
        }
        
        var shortMods = ""
        var longMods = ""
        var markup: Markedup!
        if markdown {
          markup = Markedup(format: .markdown)
        } else {
          shortMods = "&h"
          longMods = "&o"
          markup = Markedup(format: .htmlDoc)
        }
        let fileExt = NoteTransformer.getFileExt(markdown: markdown)
        markup.writeLine("<?output \"report.\(fileExt)\"?>")
        markup.startDoc(withTitle: collection.title, withCSS: nil)
        markup.heading(level: 1, text: collection.title)
        markup.writeLine("<?nextrec?>")
        for field in fields {
          let proper = field.fieldLabel.properForm
          let common = field.fieldLabel.commonForm
          let type = field.fieldType.typeString
            if common == NotenikConstants.titleCommon {
              markup.heading(level: 2, text: "=$title\(shortMods)$=")
            } else if common == NotenikConstants.bodyCommon || type == NotenikConstants.longTextType {
              markup.startParagraph()
              markup.startStrong()
              markup.write(proper)
              markup.write(":")
              markup.finishStrong()
              markup.finishParagraph()
              if fileExt == "md" {
                  markup.paragraph(text: "=$\(common)\(longMods)$=")
              } else {
                  markup.writeLine("=$\(common)\(longMods)$=")
              }
          } else {
              markup.startParagraph()
              markup.startStrong()
              markup.write("\(proper):")
              markup.finishStrong()
              markup.write(" =$\(common)\(shortMods)$=")
              markup.finishParagraph()
          }
        }
        markup.writeLine("<?loop?>")
        markup.finishDoc()

        // Now let's save the new report.
        do {
          try markup.code.write(to: sampleURL, atomically: false, encoding: .utf8)
        }
        catch {
            let error = LogEvent(subsystem: "com.powersurgepub.notenik",
                                 category: "NoteTransformer",
                                 level: .error,
                                 message: "Error saving sample report to \(sampleURL.path)")
            errors.append(error)
            return errors
        }
        return errors
    }
    
    
    /// Write one of the sample files to disk, creating any needed folders along the way.
    /// - Parameters:
    ///   - contents: The string containing the text to be written to disk.
    ///   - collectionPath: The path at which the collection resides.
    ///   - folder1: A folder beneath the collection path.
    ///   - folder2: Optionally, a folder beneath the first folder.
    ///   - fileName: The file name to which we wish to write the text.
    /// - Returns: True if the write was successful; false if an error was encountered.
    static func writeSampleFile(contents: String,
                          collectionPath: String,
                          folder1: String,
                          folder2: String?,
                          fileName: String) -> Bool {
        
        let fileManager = FileManager.default
        
        var folderPath = FileUtils.ensureFolder(path1: collectionPath,
                                                path2: folder1)
        guard folderPath != nil else { return false }
        
        if folder2 != nil {
            folderPath = FileUtils.ensureFolder(path1: folderPath!,
                                                path2: folder2!)
            guard folderPath != nil else { return false }
        }
        
        let filePath = FileUtils.joinPaths(path1: folderPath!, path2: fileName)
        guard !fileManager.fileExists(atPath: filePath) else { return false }
        
        let fileURL = URL(fileURLWithPath: filePath)
        do {
            try contents.write(to: fileURL,
                               atomically: true,
                               encoding: String.Encoding.utf8)
        } catch {
            return false
        }
        return true
    }
    
    /// Generate a URL pointing to the Report Template Sample and ensure the Reports folder exists.
    public static func getReportTemplateSampleURL(io: NotenikIO, markdown: Bool = false) -> URL? {
        guard io.collection != nil else { return nil }
        let reportsResource = io.collection!.lib.getResource(type: .reports)
        guard reportsResource.ensureExistence() else { return nil }
        guard let reportsFolderURL = reportsResource.url else { return nil }
        let fileExt = NoteTransformer.getFileExt(markdown: markdown)
        return reportsFolderURL.appendingPathComponent(sampleReportTemplateFileName + "." + fileExt)
    }
    
    /// Return the file extension (without the period).
    static func getFileExt(markdown: Bool) -> String {
        if markdown {
            return "md"
        } else {
            return "html"
        }
    }
    
}
