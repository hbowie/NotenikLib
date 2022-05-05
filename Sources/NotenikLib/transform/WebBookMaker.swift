//
//  WebBookMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/6/21.
//
//  Copyright © 2021 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A class to make web books. Note that the output can be formatted as an EPUB, or
/// as a  website. Even the EPUB format, though, can become part of a larger website.
public class WebBookMaker {
    
    let fm = FileManager.default
    
    let headerFileName = "header"
    let headerFileExt = "html"
    let lineBreak = "\n"

    let htmlFolderName = "html"
    let htmlFileExt = "html"
    let imagesFolderName = "images"
    let pubFolderName = "EPUB"
    let opfFileName = "content"
    let opfFileExt = "opf"
    let tagsFileName = "tags-outline-for-book"
    let tagsPageTitle = "Tags Outline"
    
    var headerFile:     URL
    var pubFolder:      URL

    var htmlFolder:     URL
    var imagesFolder:   URL
    var opfFile:        URL!
    var tagsFile:       URL!
    
    var header = ""

    var filesDeleted = 0
    var filesWritten = 0
    
    let htmlConverter = StringConverter()
    
    var collectionURL:  URL
    var collectionLink: NotenikLink
    var collection:     NoteCollection
    var io:             FileIO
    
    var bookFolder:     URL
    
    var epub = true
    
    /// Attempt to initialize an instance.
    public init?(input: URL, output: URL, epub: Bool) {
        
        collectionURL = input
        bookFolder = output
        self.epub = epub
        
        // Ready our output folders.
        guard FileUtils.ensureFolder(forURL: bookFolder) else { return nil }
        
        headerFile = URL(fileURLWithPath: headerFileName, relativeTo: bookFolder).appendingPathExtension(headerFileExt)
        if epub {
            pubFolder = bookFolder.appendingPathComponent(pubFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: pubFolder) else { return nil }
        } else {
            pubFolder = bookFolder
        }

        if epub {
            htmlFolder = pubFolder.appendingPathComponent(htmlFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: htmlFolder) else { return nil }
        } else {
            htmlFolder = bookFolder
        }
        imagesFolder = pubFolder.appendingPathComponent(imagesFolderName, isDirectory: true)
        guard FileUtils.ensureFolder(forURL: imagesFolder) else { return nil }
        
        // Open the input.
        collectionLink = NotenikLink(url: input)
        collectionLink.determineCollectionType()
        switch collectionLink.type {
        case .ordinaryCollection, .webCollection:
            break
        default:
            return nil
        }
        
        io = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        guard let possibleCollection = io.openCollection(realm: realm, collectionPath: collectionLink.path, readOnly: true) else {
            return nil
        }
        collection = possibleCollection
        
        do {
            header = try String(contentsOf: headerFile)
        } catch {
            header = ""
        }
        
        parms = DisplayParms()
        parms.setCSS(useFirst: collection.displayCSS, useSecond: DisplayPrefs.shared.bodyCSS)

        if epub {
            parms.format = .xhtmlDoc
        } else {
            parms.format = .htmlDoc
        }
        parms.sortParm = .seqPlusTitle
        parms.streamlined = true
        parms.wikiLinkPrefix = ""
        parms.wikiLinkFormat = .fileName
        parms.wikiLinkSuffix = "." + htmlFileExt
        parms.mathJax = collection.mathJax
        parms.localMj = false
        parms.curlyApostrophes = collection.curlyApostrophes
        if epub {
            parms.imagesPath = "../\(imagesFolderName)"
        } else {
            parms.imagesPath = "\(imagesFolderName)"
        }
        parms.header = header
        
        htmlConverter.addHTML()
        
        if epub {
            opfFile = URL(fileURLWithPath: opfFileName, relativeTo: pubFolder).appendingPathExtension(opfFileExt)
            tagsFile = URL(fileURLWithPath: tagsFileName, relativeTo: htmlFolder).appendingPathExtension(htmlFileExt)
        }
    }
    
    /// Create an index file pointing to the first page of the book.
    /// - Parameter indexURL: The URL of the file to be written.
    /// - Returns: An error message, if problems.
    /*
    public func webBookIndexRedirect(_ indexURL: URL) -> String? {
        
        let (note1, _) = io.firstNote()
        guard let firstNote = note1 else {
            return "Could not find any notes in the Collection"
        }
        let bookTitle = firstNote.title.value
        let indexParent = indexURL.deletingPathExtension().deletingLastPathComponent()
        let indexParentPath = indexParent.path
        let webBookPath = collection.webBookPath
        guard webBookPath.starts(with: indexParentPath) else {
            return "The Web Book is not within the same folder"
        }
        var redirectPath = ""
        if webBookPath == indexParentPath {
            redirectPath = "./"
        } else {
            redirectPath = "./" + String(webBookPath.suffix(webBookPath.count - indexParentPath.count - 1))
        }
        let firstNoteFilename = StringUtils.toCommonFileName(bookTitle)
        if epub {
            redirectPath.append("/EPUB/html/")
        }
        redirectPath.append("\(firstNoteFilename).html")
        var code = ""
        code.append("<!DOCTYPE html>\n")
        code.append("<html lang=\"en\">\n")
        code.append("<head>\n")
        code.append("    <meta charset=\"utf-8\" />\n")
        code.append("    <title>\(bookTitle)</title>\n")
        code.append("    <meta http-equiv=\"refresh\" content=\"0; URL=\(redirectPath)\" />\n")
        code.append("</head>\n")
        code.append("<body>\n")
        code.append("<p>Please click <a href=\"\(redirectPath)\">here</a> to view this Notenik Web Book.</p>")
        code.append("</body>\n")
        code.append("</html>\n")
        do {
            try code.write(to: indexURL, atomically: true, encoding: .utf8)
        } catch {
            return "Could not write Web Book Index Redirect file to \(indexURL.path)"
        }
        return nil
    } */
    
    // -----------------------------------------------------------
    //
    // MARK: Generate a Web Book.
    //
    // -----------------------------------------------------------
    
    /// Use the Collection found at the input URL to generate a Web book within the output URL.
    public func generate() -> Int {
        
        if epub {
            generateMimetype()
            manifestStarted = false
            generateManifest(noteTitle: nil, finish: false)
            spineStarted = false
            generateSpine(noteTitle: nil, finish: false)
        }
        
        generateCSS()
        
        deleteOldFiles()
        
        // Now generate fresh content.
        filesWritten = 0
        io.sortParm = .seqPlusTitle
        bookTitle = ""
        var (note, position) = io.firstNote()
        firstPage = true
        while note != nil && position.valid {
            generate(note: note!)
            (note, position) = io.nextNote(position)
            firstPage = false
        }
        
        // Now finish up.
        if epub {
            generateManifest(noteTitle: nil, finish: true)
            generateSpine(noteTitle: nil, finish: true)
            writeOPF()
        }
        
        logInfo(msg: "\(filesWritten) files written to \(bookFolder)")
        return filesWritten
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Delete old files before regenerating them.
    //
    // -----------------------------------------------------------
    
    func deleteOldFiles() {
        // Delete any html files already present in the output folder.
        filesDeleted = 0
        do {
            let contents = try fm.contentsOfDirectory(at: htmlFolder,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles)
            for entry in contents {
                if entry.pathExtension == htmlFileExt {
                    // if epub || entry.lastPathComponent != "index.html" {
                        try fm.removeItem(at: entry)
                        filesDeleted += 1
                    // }
                }
            }
        } catch {
            communicateError("Could not read directory at \(htmlFolder)")
        }
        logInfo(msg: "\(filesDeleted) files deleted from \(htmlFolder)")
        
        // Delete any image files already present in the output folder.
        filesDeleted = 0
        do {
            let contents = try fm.contentsOfDirectory(at: imagesFolder,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles)
            for entry in contents {
                try fm.removeItem(at: entry)
                filesDeleted += 1
            }
        } catch {
            communicateError("Could not read directory at \(imagesFolder)")
        }
        logInfo(msg: "\(filesDeleted) files deleted from \(imagesFolder)")
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate mimetype file for an EPUB.
    //
    // -----------------------------------------------------------
    
    let mimetypeFileName = "mimetype"
    var mimetypeFile:   URL!
    
    func generateMimetype() {


        mimetypeFile = URL(fileURLWithPath: mimetypeFileName, relativeTo: pubFolder)

        let mimetype = "application/epub+zip"
        do {
            try mimetype.write(to: mimetypeFile, atomically: true, encoding: .utf8)
        } catch {
            communicateError("Could not mimetype to \(mimetypeFile!)")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate a default CSS style sheet.
    //
    // -----------------------------------------------------------
    
    let cssFolderName = "css"
    let cssFileName = "styles"
    let cssFileExt = "css"
    
    var cssFolder:      URL?
    var cssFile:        URL?
    
    var defaultCSS = ""
    
    /// If the CSS file already exists, then leave it in place.
    func generateCSS() {
        
        cssFolder = pubFolder.appendingPathComponent(cssFolderName, isDirectory: true)
        guard FileUtils.ensureFolder(forURL: cssFolder!) else { return }
        cssFile = URL(fileURLWithPath: cssFileName, relativeTo: cssFolder).appendingPathExtension(cssFileExt)
        
        defaultCSS = parms.cssString
        defaultCSS.append("\nimg { max-width: 100%; border: 4px solid gray; }")
        defaultCSS.append("\nbody { max-width: 33em; margin: 0 auto; float: none; }")
        
        if epub {
            parms.cssString = "../\(cssFolderName)/\(cssFileName).\(cssFileExt)"
        } else {
            parms.cssString = "\(cssFolderName)/\(cssFileName).\(cssFileExt)"
        }
        parms.cssLinkToFile = true
        
        var css = ""
        do {
            css = try String(contentsOf: cssFile!)
        } catch {
            css = ""
        }
        guard css.isEmpty else { return }
        css = defaultCSS
        do {
            try css.write(to: cssFile!, atomically: true, encoding: .utf8)
            filesWritten += 1
        } catch {
            communicateError("Could not write CSS file to \(cssFile!)")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate appropriate output for each Note.
    //
    // -----------------------------------------------------------
    
    var bookTitle = ""
    var firstPage = true
    
    var parms = DisplayParms()
    var display = NoteDisplay()
    
    /// Generate appropriate output for the next Note.
    func generate(note: Note) {
        
        let title = note.title.value
        let level = note.level
        var levelText = level.value
        var levelInt = level.getInt()
        if levelText.count == 1 && levelInt >= 1 && levelInt <= 6 {
            // ok
        } else {
            levelText = "2"
            levelInt = 2
        }
        
        let fileName = StringUtils.toCommonFileName(title)
        
        if bookTitle.isEmpty {
            bookTitle = title
            levelText = "1"
            levelInt = 1
        }

        let fileURL = URL(fileURLWithPath: fileName, relativeTo: htmlFolder).appendingPathExtension(htmlFileExt)
        
        let (code, _) = display.display(note, io: io, parms: parms)
        
        let written = FileUtils.saveToDisk(strToWrite: code,
                                           outputURL: fileURL,
                                           createDirectories: true,
                                           checkForChanges: false)
        
        if firstPage && !epub {
            let indexURL = URL(fileURLWithPath: "index", relativeTo: htmlFolder).appendingPathExtension(htmlFileExt)
            _ = FileUtils.saveToDisk(strToWrite: code,
                                     outputURL: indexURL,
                                     createDirectories: false,
                                     checkForChanges: false)
        }
        
        if written {
            filesWritten += 1
            copyImageAsNeeded(note: note)
            if epub {
                generateManifest(noteTitle: title, finish: false)
                generateSpine(noteTitle: title, finish: false)
            }
        } 
    }
    
    func copyImageAsNeeded(note: Note) {
        guard let fromURL = note.imageURL else { return }
        let toName = note.imageCommonName
        let toURL = imagesFolder.appendingPathComponent(toName)
        do {
            try fm.copyItem(at: fromURL, to: toURL)
        } catch {
            communicateError("Image Copy Failed -- from: \(fromURL) -- to: \(toURL)")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate an OPF manifest.
    //
    // -----------------------------------------------------------
    
    var opfManifest = ""
    var manifestStarted = false
    
    func generateManifest(noteTitle: String?, finish: Bool = false) {
        
        if !manifestStarted {
            opfManifest = ""
            writeLineToManifest(indentLevel: 1, text: "<manifest>")
            manifestStarted = true
        }
        
        if let title = noteTitle {
            if !title.isEmpty {
                var text = "<item href=\""
                text.append(htmlFolderName)
                text.append("/")
                text.append(StringUtils.toCommonFileName(title))
                text.append(".")
                text.append(htmlFileExt)
                text.append("\" id=\"")
                text.append(StringUtils.toCommon(title))
                text.append("\" media-type=\"text/html\"/>")
                writeLineToManifest(indentLevel: 2, text: text)
                // "<item href="\/epub30-titlepage.xhtml" id="ttl" media-type="application/xhtml+xml"/>"
            }
        }
        
        if finish {
            writeLineToManifest(indentLevel: 1, text: "</manifest>")
        }
    }
    
    func writeLineToManifest(indentLevel: Int, text: String) {
        let indent = String(repeating: " ", count: indentLevel * 2)
        opfManifest.append(indent + text + lineBreak)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate an OPF spine.
    //
    // -----------------------------------------------------------
    
    var opfSpine = ""
    var spineStarted = false
    
    func generateSpine(noteTitle: String?, finish: Bool = false) {
        
        if !spineStarted {
            opfSpine = ""
            writeLineToSpine(indentLevel: 1, text: "<spine toc=\"ncx\">")
            spineStarted = true
        }
        
        if let title = noteTitle {
            if !title.isEmpty {
                var text = "<itemref idref=\""
                text.append(StringUtils.toCommon(title))
                text.append("\" />")
                writeLineToSpine(indentLevel: 2, text: text)
            }
        }
        
        if finish {
            writeLineToSpine(indentLevel: 1, text: "</spine>")
        }
    }
    
    func writeLineToSpine(indentLevel: Int, text: String) {
        let indent = String(repeating: " ", count: indentLevel * 2)
        opfSpine.append(indent + text + lineBreak)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Write out the OPF file for an epub.
    //
    // -----------------------------------------------------------
    
    func writeOPF() {
        var opf = ""
        opf.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
        opf.append("<package xmlns=\"http://www.idpf.org/2007/opf\" version=\"3.0\" unique-identifier=\"uid\">\n")
        opf.append("  <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n")
        opf.append("    <dc:identifier id=\"uid\">\(StringUtils.toCommonFileName(bookTitle))</dc:identifier>\n")
        opf.append("    <dc:title>\(bookTitle)</dc:title>\n")
        // opf.append("    <dc:creator>???</dc:creator>\n")
        opf.append("    <dc:language>en</dc:language>\n")
        // <meta property="dcterms:modified">2012-02-27T16:38:35Z</meta>
        opf.append("  </metadata>\n")
        
        opf.append(opfManifest)
        
        opf.append(opfSpine)
        
        opf.append("</package>\n")
        
        do {
            try opf.write(to: opfFile, atomically: true, encoding: .utf8)
            filesWritten += 1
        } catch {
            communicateError("Problems writing OPF file to \(opfFile!)")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Utility methods.
    //
    // -----------------------------------------------------------
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "WebBookMaker",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "WebBookMaker",
                          level: .error,
                          message: msg)
    }
    
}
