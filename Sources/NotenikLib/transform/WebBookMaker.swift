//
//  WebBookMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/6/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A class to make web books.
public class WebBookMaker {
    
    let fm = FileManager.default
    
    let headerFileName = "header"
    let headerFileExt = "html"
    let lineBreak = "\n"
    let cssFolderName = "css"
    let cssFileName = "styles"
    let cssFileExt = "css"
    let htmlFolderName = "html"
    let htmlFileExt = "html"
    let imagesFolderName = "images"
    let pubFolderName = "EPUB"
    let opfFileName = "content"
    let opfFileExt = "opf"
    let tagsFileName = "tags-outline-for-book"
    let tagsPageTitle = "Tags Outline"
    
    var parms = DisplayParms()
    var display = NoteDisplay()
    
    var collectionURL: URL
    var collectionLink: NotenikLink
    var collection: NoteCollection
    var io: FileIO
    
    var epub = true
    
    var bookFolder:     URL
    var headerFile:     URL
    var pubFolder:      URL
    var cssFolder:      URL
    var cssFile:        URL
    var htmlFolder:     URL
    var imagesFolder:   URL
    var opfFile:        URL!
    var tagsFile:       URL!
    
    var header = ""
    var defaultCSS = ""
    var bookTitle = ""
    var opfManifest = ""
    var opfSpine = ""
    var filesDeleted = 0
    var filesWritten = 0
    
    let htmlConverter = StringConverter()
    
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
        cssFolder = pubFolder.appendingPathComponent(cssFolderName, isDirectory: true)
        guard FileUtils.ensureFolder(forURL: cssFolder) else { return nil }
        cssFile = URL(fileURLWithPath: cssFileName, relativeTo: cssFolder).appendingPathExtension(cssFileExt)
        if epub {
            htmlFolder = pubFolder.appendingPathComponent(htmlFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: htmlFolder) else { return nil }
        } else {
            htmlFolder = bookFolder
        }
        imagesFolder = pubFolder.appendingPathComponent(imagesFolderName, isDirectory: true)
        guard FileUtils.ensureFolder(forURL: imagesFolder) else { return nil }
        if epub {
            opfFile = URL(fileURLWithPath: opfFileName, relativeTo: pubFolder).appendingPathExtension(opfFileExt)
            tagsFile = URL(fileURLWithPath: tagsFileName, relativeTo: htmlFolder).appendingPathExtension(htmlFileExt)
        }
        
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
        defaultCSS = parms.cssString
        defaultCSS.append("\nimg { max-width: 100%; border: 4px solid gray; }")
        defaultCSS.append("\nbody { max-width: 33em; margin: 0 auto; float: none; }")
        if epub {
            parms.cssString = "../\(cssFolderName)/\(cssFileName).\(cssFileExt)"
        } else {
            parms.cssString = "\(cssFolderName)/\(cssFileName).\(cssFileExt)"
        }
        parms.cssLinkToFile = true
        parms.format = .htmlDoc
        parms.sortParm = .seqPlusTitle
        parms.streamlined = true
        parms.wikiLinkPrefix = ""
        parms.wikiLinkFormat = .fileName
        parms.wikiLinkSuffix = "." + htmlFileExt
        parms.mathJax = collection.mathJax
        parms.localMj = false
        if epub {
            parms.imagesPath = "../\(imagesFolderName)"
        } else {
            parms.imagesPath = "\(imagesFolderName)"
        }
        parms.header = header
        
        htmlConverter.addHTML()
    }
    
    /// Create an index file pointing to the first page of the book.
    /// - Parameter indexURL: The URL of the file to be written.
    /// - Returns: An error message, if problems.
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
    }
    
    /// Use the Collection found at the input URL to generate a Web book within the output URL.
    public func generate() -> Int {
        
        opfManifest = ""
        writeLineToManifest(indentLevel: 1, text: "<manifest>")
        
        opfSpine = ""
        generateCSS()
        
        // Delete any html files already present in the output folder.
        filesDeleted = 0
        do {
            let contents = try fm.contentsOfDirectory(at: htmlFolder,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles)
            for entry in contents {
                if entry.pathExtension == htmlFileExt {
                    if epub || entry.lastPathComponent != "index.html" {
                        try fm.removeItem(at: entry)
                        filesDeleted += 1
                    }
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
        
        // Now generate fresh content.
        filesWritten = 0
        io.sortParm = .seqPlusTitle
        
        var (note, position) = io.firstNote()
        while note != nil && position.valid {
            generate(note: note!)
            (note, position) = io.nextNote(position)
        }
        
        writeLineToManifest(indentLevel: 1, text: "</manifest>")
        
        if epub {
            writeOPF()
        }
        
        logInfo(msg: "\(filesWritten) files written to \(bookFolder)")
        return filesWritten
    }
    
    /// If the CSS file already exists, then leave it in place.
    func generateCSS() {
        var css = ""
        do {
            css = try String(contentsOf: cssFile)
        } catch {
            css = ""
        }
        guard css.isEmpty else { return }
        css = defaultCSS
        do {
            try css.write(to: cssFile, atomically: true, encoding: .utf8)
            filesWritten += 1
        } catch {
            communicateError("Could not write CSS file to \(cssFile)")
        }
    }
    
    /// Generate for the next Note. 
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
                                           checkForChanges: true)
        
        if written {
            filesWritten += 1
            writeNoteToManifest(title: title)
            copyImageAsNeeded(note: note)
        } 
    }
    
    func copyImageAsNeeded(note: Note) {
        guard let fromURL = note.imageURL else { return }
        let toName = note.imageCommonName
        let toURL = imagesFolder.appendingPathComponent(toName)
        do {
            try FileManager.default.copyItem(at: fromURL, to: toURL)
        } catch {
            print("Image Copy failed!")
            print("  - from: \(fromURL)")
            print("  - to:   \(toURL)")
        }
    }
    
    func writeNoteToManifest(title: String) {
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
    
    func writeLineToManifest(indentLevel: Int, text: String) {
        let indent = String(repeating: " ", count: indentLevel * 2)
        opfManifest.append(indent + text + lineBreak)
    }
    
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
        
        opf.append("</package>\n")
        
        do {
            try opf.write(to: opfFile, atomically: true, encoding: .utf8)
            filesWritten += 1
        } catch {
            communicateError("Problems writing OPF file to \(opfFile)")
        }
    }
    
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
