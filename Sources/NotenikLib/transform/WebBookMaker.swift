//
//  WebBookMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/6/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

import ZIPFoundation

/// A class to make web books. Note that the output can be formatted as an EPUB, or
/// as a  website. Even the EPUB format, though, can become part of a larger website.
public class WebBookMaker {
    
    let fm = FileManager.default
    
    // The type of output to be produced.
    var webBookType: WebBookType = .epubsite
    var epub = false
    var htmlFileExt = "html"
    
    // The input to be used.
    var collectionURL:  URL
    var collectionLink: NotenikLink = NotenikLink()
    var collection:     NoteCollection = NoteCollection()
    var io:             FileIO = FileIO()
    
    var imagesIn: URL?
    
    let headerFileName = "header"
    let headerFileExt = "html"
    var headerFile:     URL
    var header = ""
    
    let lineBreak = "\n"
    
    // The folder into which we will place whatever output
    // is to be produced.
    var bookFolder:     URL
    
    // This is the high-level folder that will contain everything
    // that makes up the electronic publication.
    let pubFolderName = "EPUB"
    var pubFolder:      URL
    var pubFolderPath = ""
    
    // The mimetype file.
    let mimetypeFileName = "mimetype"
    var mimetypeFile:   URL!
    
    // The META-INF folder contains the container.xml file.
    let metaInfFolderName = "META-INF"
    var metaFolder:       URL!
    var metaNote:         Note?
    
    let containerFileName = "container"
    let containerFileExt  = "xml"
    var containerFile:    URL!
    
    // Next come content folders.
    let contentFolderName = "OEBPS"
    var contentFolder:    URL!
    
    // CSS file and folder.
    let cssFolderName = "css"
    let cssFileName = "styles"
    let cssFileExt = "css"
    var cssFolder:      URL?
    var cssFile:        URL?
    var cssRelPath = ""

    // HTML folder.
    let htmlFolderName = "html"
    var htmlFolder:     URL

    // Images folder.
    let imagesFolderName = "images"
    var imagesFolder:   URL!
    var imagesRelPath = ""
    var images: [ImageFile] = []
    
    // JavaScript folder.
    let jsFolderName = "js"
    let jsFileExt    = "js"
    var jsFolder:       URL!
    var jsRelPath    = ""
    
    let opfFileName = "content"
    let opfFileExt = "opf"
    var opfFile:        URL!

    let epubFileName      = "web-book"
    let epubFileExt       = "epub"
    var epubFile:       URL!
    
    let tocFileName = "toc"
    var tocFile:        URL!

    var filesDeleted = 0
    var filesWritten = 0
    
    let htmlConverter = StringConverter()
    
    // -----------------------------------------------------------
    //
    // MARK: Attempt to initialize an instance.
    //
    // -----------------------------------------------------------
    
    /// Attempt to initialize an instance, setting up all of the output structure.
    public init?(input: URL, output: URL, webBookType: WebBookType) {
        
        // Save the input parameters.
        collectionURL = input
        bookFolder = output
        self.webBookType = webBookType
        epub = (webBookType == .epub || webBookType == .epubsite)
        
        // Ready our output folders.
        guard FileUtils.ensureFolder(forURL: bookFolder) else { return nil }
        
        // Point to a possible header file, supplied by the user in
        // the output folder.
        headerFile = URL(fileURLWithPath: headerFileName, relativeTo: bookFolder).appendingPathExtension(headerFileExt)
        do {
            header = try String(contentsOf: headerFile)
        } catch {
            header = ""
        }
        
        // Set up our output files and folders.
        switch webBookType {
            
        case .website:
            
            htmlFileExt = "html"
            pubFolder = bookFolder
            contentFolder = bookFolder
            htmlFolder = bookFolder
            
            cssFolder = pubFolder.appendingPathComponent(cssFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: cssFolder!) else { return }
            cssFile = URL(fileURLWithPath: cssFileName, relativeTo: cssFolder).appendingPathExtension(cssFileExt)
            cssRelPath = "\(cssFolderName)/\(cssFileName).\(cssFileExt)"
            
            imagesFolder = pubFolder.appendingPathComponent(imagesFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: imagesFolder) else { return nil }
            imagesRelPath = "\(imagesFolderName)"
            
            jsFolder = pubFolder.appendingPathComponent(jsFolderName, isDirectory: true)
            
        case .epubsite:
            
            htmlFileExt = "html"
            
            pubFolder = bookFolder.appendingPathComponent(pubFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: pubFolder) else { return nil }
            
            metaFolder = pubFolder.appendingPathComponent(metaInfFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: metaFolder) else { return nil }
            
            containerFile = URL(fileURLWithPath: containerFileName, relativeTo: metaFolder).appendingPathExtension(containerFileExt)
            
            contentFolder = pubFolder
            
            htmlFolder = pubFolder.appendingPathComponent(htmlFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: htmlFolder) else { return nil }
            
            cssFolder = pubFolder.appendingPathComponent(cssFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: cssFolder!) else { return }
            cssRelPath = "../\(cssFolderName)/\(cssFileName).\(cssFileExt)"
            cssFile = URL(fileURLWithPath: cssFileName, relativeTo: cssFolder).appendingPathExtension(cssFileExt)
            
            imagesFolder = pubFolder.appendingPathComponent(imagesFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: imagesFolder) else { return nil }
            imagesRelPath = "../\(imagesFolderName)"
            
            jsFolder = pubFolder.appendingPathComponent(jsFolderName, isDirectory: true)

            opfFile = URL(fileURLWithPath: opfFileName, relativeTo: pubFolder).appendingPathExtension(opfFileExt)
            
            tocFile = URL(fileURLWithPath: tocFileName, relativeTo: contentFolder).appendingPathExtension(htmlFileExt)
            
        case .epub:
            
            htmlFileExt = "xhtml"
            
            pubFolder = bookFolder.appendingPathComponent(pubFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: pubFolder) else { return nil }
            
            metaFolder = pubFolder.appendingPathComponent(metaInfFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: metaFolder) else { return nil }
            
            containerFile = URL(fileURLWithPath: containerFileName, relativeTo: metaFolder).appendingPathExtension(containerFileExt)
            
            contentFolder = pubFolder.appendingPathComponent(contentFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: contentFolder) else { return nil }
            
            htmlFolder = contentFolder
            
            cssFolder = contentFolder.appendingPathComponent(cssFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: cssFolder!) else { return }
            cssFile = URL(fileURLWithPath: cssFileName, relativeTo: cssFolder).appendingPathExtension(cssFileExt)
            cssRelPath = "\(cssFolderName)/\(cssFileName).\(cssFileExt)"
            
            imagesFolder = contentFolder.appendingPathComponent(imagesFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: imagesFolder) else { return nil }
            imagesRelPath = "\(imagesFolderName)"
            
            jsFolder = contentFolder.appendingPathComponent(jsFolderName, isDirectory: true)
            guard FileUtils.ensureFolder(forURL: jsFolder) else { return nil }
            jsRelPath = "\(jsFolderName)"
            
            opfFile = URL(fileURLWithPath: opfFileName, relativeTo: contentFolder).appendingPathExtension(opfFileExt)
            
            epubFile = URL(fileURLWithPath: epubFileName, relativeTo: bookFolder).appendingPathExtension(epubFileExt)
            
            tocFile = URL(fileURLWithPath: tocFileName, relativeTo: contentFolder).appendingPathExtension(htmlFileExt)
            
        }

        pubFolderPath = pathFromURL(pubFolder)
        
        imagesIn = input.appendingPathComponent(imagesFolderName, isDirectory: true)
        
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
        guard let possibleCollection = io.openCollection(realm: realm,
                                                         collectionPath: collectionLink.path,
                                                         readOnly: true) else {
            return nil
        }
        collection = possibleCollection
        
        // Now set up the Display parameters.
        parms = DisplayParms()
        if webBookType == .epub {
            parms.epub3 = true
        }
        parms.setCSS(useFirst: collection.displayCSS, useSecond: DisplayPrefs.shared.displayCSS)
        if epub {
            parms.format = .xhtmlDoc
        } else {
            parms.format = .htmlDoc
        }
        parms.sortParm = .seqPlusTitle
        parms.displayMode = .streamlinedReading
        parms.wikiLinks.set(format: .fileName, prefix: "", suffix: "." + htmlFileExt)
        parms.mathJax = collection.mathJax
        parms.localMj = false
        parms.curlyApostrophes = collection.curlyApostrophes
        parms.extLinksOpenInNewWindows = collection.extLinksOpenInNewWindows
        parms.imagesPath = imagesRelPath
        parms.header = header
        // parms.cssString = cssRelPath
        
        htmlConverter.addHTML()
        
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate a Web Book.
    //
    // -----------------------------------------------------------
    
    /// Use the Collection found at the input URL to generate a Web book within the output URL.
    public func generate() -> Int {
        
        images = []
        
        loadImagesFolder()
        
        if epub {
            generateMimetype()
            generateContainer()
            
            manifestStarted = false
            _ = generateManifest(folder: "", filenameWithExt: "", finish: false)
            
            spineStarted = false
            generateSpine(idref: "", finish: false)
        }
        
        generateCSS()
        
        deleteOldFiles()
        
        parms.cssString = cssRelPath
        
        // Now generate fresh content.
        display.loadResourcePagesForCollection(io: io, parms: parms)
        filesWritten = 0
        switch io.sortParm {
        case .seqPlusTitle:
            break
        case .datePlusSeq:
            break
        default:
            io.sortParm = .seqPlusTitle
        }
        
        bookTitle = ""
        var (note, position) = io.firstNote()
        firstPage = true
        while note != nil && position.valid {
            generate(note: note!)
            (note, position) = io.nextNote(position)
            firstPage = false
        }
        
        if epub {
            addToTableOfContents(level: 0, href: "", note: nil, finish: true)
        }
        
        copyImages()
        
        // Now finish up.
        if epub {
            _ = generateManifest(folder: "", filenameWithExt: "", finish: true)
            generateSpine(idref: "", finish: true)
            writeOPF()
        }
        
        logInfo(msg: "\(filesWritten) files written to \(bookFolder)")
        
        if webBookType == .epub {
            zipToEpub()
        }
        
        return filesWritten
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate mimetype file for an EPUB.
    //
    // -----------------------------------------------------------
    
    func generateMimetype() {
        mimetypeFile = URL(fileURLWithPath: mimetypeFileName, relativeTo: pubFolder)

        let mimetype = "application/epub+zip"
        let mimetypePath = pathFromURL(mimetypeFile)
        do {
            try mimetype.write(to: mimetypeFile, atomically: true, encoding: .utf8)
            logInfo(msg: "Mimetype file written to \(mimetypePath)")
        } catch {
            communicateError("Could not write mimetype to \(mimetypePath)")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate a container file pointing to the opf file.
    //
    // -----------------------------------------------------------
    
    func generateContainer() {
        var container = ""
        container.append("<?xml version= \"1.0\" encoding=\"UTF-8\"?>\n")
        container.append("<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">\n")
        container.append("  <rootfiles>\n")
        
        switch webBookType {
        case .website:
            break
        case .epubsite:
            container.append("    <rootfile full-path=\"\(opfFileName).\(opfFileExt)\" media-type=\"application/oebps-package+xml\"/>\n")
        case .epub:
            container.append("    <rootfile full-path=\"\(contentFolderName)/\(opfFileName).\(opfFileExt)\" media-type=\"application/oebps-package+xml\"/>\n")
        }
        
        container.append("  </rootfiles>\n")
        container.append("</container>\n")
        
        let containerFilePath = pathFromURL(containerFile)
        do {
            try container.write(to: containerFile, atomically: true, encoding: .utf8)
            logInfo(msg: "Container file written to \(containerFilePath)")
        } catch {
            communicateError("Could not write container file to \(containerFilePath)")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Delete old files before regenerating them.
    //
    // -----------------------------------------------------------
    
    func deleteOldFiles() {
        // Delete any html files already present in the output folder.
        filesDeleted = 0
        let hdrFN = headerFileName + "." + headerFileExt
        do {
            let contents = try fm.contentsOfDirectory(at: htmlFolder,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles)
            for entry in contents {
                if entry.pathExtension == htmlFileExt || entry.pathExtension == opfFileExt {
                    if webBookType == .website && entry.lastPathComponent == hdrFN {
                        // Leave the header file
                    } else {
                        // if epub || entry.lastPathComponent != "index.html" {
                        try fm.removeItem(at: entry)
                        filesDeleted += 1
                        // }
                    }
                }
            }
        } catch {
            communicateError("Could not delete contents of directory at \(htmlFolder)")
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
            communicateError("Could not delete contents of directory at \(imagesFolder!)")
        }
        logInfo(msg: "\(filesDeleted) image files deleted from \(imagesFolder!)")
        
        // Delete any javascript files already present in the output folder.
        if epubFile != nil {
            filesDeleted = 0
            do {
                let contents = try fm.contentsOfDirectory(at: jsFolder,
                                                          includingPropertiesForKeys: nil,
                                                          options: .skipsHiddenFiles)
                for entry in contents {
                    try fm.removeItem(at: entry)
                    filesDeleted += 1
                }
            } catch {
                communicateError("Could not delete contents of directory at \(jsFolder!)")
            }
            logInfo(msg: "\(filesDeleted) javascript files deleted from \(jsFolder!)")
        }
        
        // Delete the epub file, if we are going to create a new one.
        if epubFile != nil {
            do {
                try fm.removeItem(at: epubFile!)
            } catch {
                // No need to panic...
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Store the contents of the input images folder.
    //
    // -----------------------------------------------------------
    
    func loadImagesFolder() {
        guard imagesIn != nil else { return }
        do {
            let contents = try fm.contentsOfDirectory(at: imagesIn!,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles)
            for entry in contents {
                let toName = entry.lastPathComponent
                let img = ImageFile(originalLocation: entry, toName: toName)
                images.append(img)
            }
        } catch {
            // Just continue if problems.
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate a default CSS style sheet.
    //
    // -----------------------------------------------------------
    
    var defaultCSS = ""
    
    /// If the CSS file already exists, then leave it in place.
    func generateCSS() {
        
        defaultCSS = parms.cssString
        defaultCSS.append("\nimg { max-width: 100%; border: 4px solid gray; }")
        defaultCSS.append("\nbody { max-width: 33em; margin: 0 auto; float: none; }")
        
        parms.cssLinkToFile = true
        
        var css = ""
        do {
            css = try String(contentsOf: cssFile!)
        } catch {
            css = ""
        }
        
        _ = generateManifest(folder: cssFolderName, filename: cssFileName, fileExt: cssFileExt)
        
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
    
    var tocLevel1 = 0
    var tocLevel2 = 0
    
    /// Generate appropriate output for the next Note.
    func generate(note: Note) {
        
        if note.mkdownCommandList.metadata {
            metaNote = note
        }
        guard note.includeInBook(epub: epub) else { return }
        
        let title = note.title.value
        let level = note.level
        var levelText = level.value
        var levelInt = level.getInt()
        if levelText.count >= 1 && levelInt >= 1 && levelInt <= 6 {
            // ok
        } else {
            levelText = "2"
            levelInt = 2
        }
        let fileName = note.noteID.commonFileName
        
        if bookTitle.isEmpty {
            bookTitle = title
            levelText = "1"
            levelInt = 1
        } else {
            if tocLevel1 <= 0 {
                tocLevel1 = levelInt
            }
            if tocLevel2 <= 0 && levelInt > tocLevel1 {
                tocLevel2 = levelInt
            }
        }

        let fileURL = URL(fileURLWithPath: fileName, relativeTo: htmlFolder).appendingPathExtension(htmlFileExt)
        let mdResults = TransformMdResults()
        let code = display.display(note, io: io, parms: parms, mdResults: mdResults)
        
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
            if let imgURL = note.getImageURL() {
                if let imgCommon = note.getImageCommonName() {
                    let img = ImageFile(originalLocation: imgURL, toName: imgCommon)
                    images.append(img)
                }
            }
            if epub {
                var properties = ""
                if note.mkdownCommandList.scripted {
                    properties = "scripted"
                }
                let id = generateManifest(folder: "",
                                          filename: fileName,
                                          fileExt: htmlFileExt,
                                          finish: false,
                                          properties: properties)
                generateSpine(idref: id, finish: false)
                if levelInt == tocLevel1 {
                    addToTableOfContents(level: 1, href: fileName + "." + htmlFileExt, note: note)
                } else if levelInt == tocLevel2 {
                    addToTableOfContents(level: 2, href: fileName + "." + htmlFileExt, note: note)
                }
                if display.mkdownContext == nil {
                    communicateError("Attempt to generate for Note titled \(note.title.value) witn nil MkdownContext")
                } else if !display.mkdownContext!.javaScript.isEmpty {
                    let jsURL = URL(fileURLWithPath: fileName, relativeTo: jsFolder).appendingPathExtension(jsFileExt)
                    let jsWritten = FileUtils.saveToDisk(strToWrite: display.mkdownContext!.javaScript,
                                                         outputURL: jsURL,
                                                         createDirectories: true,
                                                         checkForChanges: false)
                    if jsWritten {
                        _ = generateManifest(folder: jsFolderName,
                                                    filename: fileName,
                                                    fileExt: jsFileExt,
                                                    finish: false,
                                                    properties: "")
                    } else {
                        print("Problems writing javascript to disk!")
                    }
                }
            }
        } 
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Copy images.
    //
    // -----------------------------------------------------------
    
    func copyImages() {
        for image in images {
            let fromURL = image.originalLocation!
            let toName = image.toName
            let toURL = imagesFolder.appendingPathComponent(toName)
            do {
                try fm.copyItem(at: fromURL, to: toURL)
            } catch {
                communicateError("Image Copy Failed -- from: \(fromURL) -- to: \(toURL)")
            }
            _ = generateManifest(folder: imagesFolderName, filenameWithExt: toName)
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Add an entry to the Table of Contents file.
    //
    // -----------------------------------------------------------
    
    var toc = Markedup()
    var tocStarted = false
    var lastLevel = 0
    
    func addToTableOfContents(level: Int, href: String, note: Note?, finish: Bool = false) {
        if !tocStarted {
            toc = Markedup(format: .xhtmlDoc)
            toc.startDoc(withTitle: "Table of Contents", withCSS: nil, epub3: true)
            toc.writeLine("<nav epub:type=\"toc\">")
            lastLevel = 0
            tocStarted = true
        }
        
        var workLevel = lastLevel
        while workLevel >= level {
            
            if workLevel >= level && workLevel > 0 {
                toc.finishListItem()
            }
            
            if workLevel > level {
                toc.finishOrderedList()
            }
            
            workLevel -= 1
        }
        
        workLevel = lastLevel
        while workLevel < level {
            toc.startOrderedList(klass: nil)
            workLevel += 1
        }
        
        if level > 0 && !href.isEmpty && note != nil {
            toc.startListItem()
            parms.streamlinedTitleWithLink(markedup: toc, note: note!, klass: Markedup.htmlClassNavLink)
        }
        
        lastLevel = level
        
        if finish && tocStarted {
            toc.finishNav()
            toc.finishDoc()
            let tocOK = toc.writeDoc(to: tocFile)
            if tocOK {
                _ = generateManifest(folder: "",
                                     filename: tocFileName,
                                     fileExt: htmlFileExt,
                                     properties: "nav")
            }
        }
        
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate an OPF manifest.
    //
    // -----------------------------------------------------------
    
    var opfManifest = ""
    var manifestStarted = false
    
    func generateManifest(folder: String,
                          filenameWithExt: String,
                          finish: Bool = false,
                          properties: String = "") -> String {
        
        var id = ""
        var filename = ""
        var fileExt = ""
        
        var components = filenameWithExt.components(separatedBy: ".")
        if components.count >= 2 {
            fileExt = components[components.count - 1]
            components.removeLast()
            filename = components.joined(separator: ".")
        }
        id = generateManifest(folder: folder,
                         filename: filename,
                         fileExt: fileExt,
                         finish: finish,
                         properties: properties)
        return id
    }
    
    func generateManifest(folder: String,
                          filename: String,
                          fileExt: String,
                          finish: Bool = false,
                          properties: String = "") -> String {
        
        var id = ""
        
        if !manifestStarted {
            opfManifest = ""
            writeLineToManifest(indentLevel: 1, text: "<manifest>")
            manifestStarted = true
        }
        
        if !filename.isEmpty {
            
            var href = folder
            if href.count > 0 {
                href.append("/")
            }
            href.append(filename)
            href.append(".")
            href.append(fileExt)
            
            let fileExtLower = fileExt.lowercased()
            id = StringUtils.toCommonFileName(folder)
            if id.count > 0 {
                id.append("-")
            }
            let filenameChar1 = filename[filename.startIndex]
            if filenameChar1.isWholeNumber {
                id.append("_")
            }
            id.append(StringUtils.toCommonFileName(filename))
            id.append("-")
            id.append(fileExtLower)
            
            var mediaType = ""
            switch fileExtLower {
            case "css":
                mediaType = "text/css"
            case "gif":
                mediaType = "image/gif"
            case "jpg", "jpeg":
                mediaType = "image/jpeg"
            case "js":
                mediaType = "application/javascript"
            case "png":
                mediaType = "image/png"
            case "svg":
                mediaType = "image/svg+xml"
            case "ttf":
                mediaType = "application/x-font-ttf"
            case "xhtml":
                mediaType = "application/xhtml+xml"
            default:
                break
            }
            
            if !mediaType.isEmpty {
                var props = ""
                if !properties.isEmpty {
                    props = " properties=\"\(properties)\""
                }
                let manLine = "<item id=\"\(id)\" href=\"\(href)\" media-type=\"\(mediaType)\"\(props)/>"
                writeLineToManifest(indentLevel: 2, text: manLine)
            }
        }
        
        if finish {
            writeLineToManifest(indentLevel: 1, text: "</manifest>")
        }
        
        return id
    }
    
    /* func generateManifest(noteTitle: String?, finish: Bool = false) {
        
        if !manifestStarted {
            opfManifest = ""
            writeLineToManifest(indentLevel: 1, text: "<manifest>")
            manifestStarted = true
        }
        
        if let title = noteTitle {
            if !title.isEmpty {
                var text = "<item"
                text.append(" id=\"\(StringUtils.toCommon(title))\"")
                text.append(" href=\"\(htmlFolderName)/\(StringUtils.toCommonFileName(title)).\(htmlFileExt)\"")
                text.append(" media-type=\"application/xhtml+xml\"/>")
                writeLineToManifest(indentLevel: 2, text: text)
                // "<item href="\/epub30-titlepage.xhtml" id="ttl" media-type="application/xhtml+xml"/>"
            }
        }
        
        if finish {
            writeLineToManifest(indentLevel: 1, text: "</manifest>")
        }
    } */
    
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
    
    func generateSpine(idref: String, finish: Bool = false) {
        
        if !spineStarted {
            opfSpine = ""
            // writeLineToSpine(indentLevel: 1, text: "<spine toc=\"ncx\">")
            writeLineToSpine(indentLevel: 1, text: "<spine>")
            spineStarted = true
        }
        
        if !idref.isEmpty {
            var text = "<itemref idref=\""
            text.append(idref)
            text.append("\" />")
            writeLineToSpine(indentLevel: 2, text: text)
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
        opf.append("<package xmlns=\"http://www.idpf.org/2007/opf\" version=\"3.0\" unique-identifier=\"pub-identifier\">\n")
        opf.append("  <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n")
        let metaCode = collection.mkdownCommandList.getCodeFor(MkdownConstants.metadataCmd)
        if metaCode.isEmpty || metaNote == nil {
            opf.append("    <dc:identifier id=\"pub-identifier\">\(StringUtils.toCommonFileName(bookTitle))</dc:identifier>\n")
            opf.append("    <dc:title>\(bookTitle)</dc:title>\n")
            opf.append("    <dc:language>en</dc:language>\n")
        } else {
            let templateUtil = TemplateUtil()
            templateUtil.setCommandCharsGen2()
            let linesIn = metaCode.components(separatedBy: "\n")
            var linesOut = ""
            for line in linesIn {
                let lineOut = templateUtil.replaceVariables(str: line, note: metaNote!)
                linesOut.append(lineOut.line)
                linesOut.append("\n")
            }
            opf.append(linesOut)
            // opf.append("\n")
        }
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
    // MARK: Zip everything up into the final epub file.
    //
    // -----------------------------------------------------------
    
    var zipster: Archive!
    var compressionMethod: CompressionMethod = .none
    
    func zipToEpub() {
        
        if !bookTitle.isEmpty {
            let newEPUBFileName = StringUtils.toCommonFileName(bookTitle)
            epubFile = URL(fileURLWithPath: newEPUBFileName, relativeTo: bookFolder).appendingPathExtension(epubFileExt)
            do {
                try fm.removeItem(at: epubFile)
            } catch {
                // Keep calm and carry on. 
            }
        }
        
        guard let archive = Archive(url: epubFile, accessMode: .create) else {
            communicateError("New EPUB archive could not be created at \(epubFile!)")
            return
        }
        zipster = archive
        addEpubEntry(relativePath: mimetypeFileName)
        addEpubFolder(relativePath: metaInfFolderName)
        addEpubFolder(relativePath: contentFolderName)
    }
    
    func addEpubFolder(relativePath: String) {
        
        addEpubEntry(relativePath: relativePath)
        
        guard let folderURL = URL(string: relativePath, relativeTo: pubFolder) else {
            communicateError("Could not create a URL for folder at \(relativePath)")
            return
        }
        do {
            let contents = try fm.contentsOfDirectory(at: folderURL,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles)
            for entry in contents {
                let newRelPath = FileUtils.joinPaths(path1: relativePath, path2: entry.lastPathComponent)
                if entry.hasDirectoryPath {
                    addEpubFolder(relativePath: newRelPath)
                } else {
                    addEpubEntry(relativePath: newRelPath)
                }
            }
        } catch {
            communicateError("Could not read directory at \(folderURL)")
        }
    }
    
    func addEpubEntry(relativePath: String) {
        do {
            try zipster.addEntry(with: relativePath,
                                 relativeTo: pubFolder,
                                 compressionMethod: compressionMethod)
        } catch {
            communicateError("Unable to add \(relativePath) to epub archive")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Utility methods.
    //
    // -----------------------------------------------------------
    
    func pathFromURL(_ url: URL) -> String {
        if #available(macOS 13.0, *) {
            return url.path(percentEncoded: false)
        } else {
            return url.path
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
    
    class ImageFile {
        
        var originalLocation: URL!
        var toName = ""
        
        init(originalLocation: URL, toName: String) {
            self.originalLocation = originalLocation
            self.toName = toName
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
    
}
