//
//  NoteDisplaySample.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/15/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown

/// A class that generates a sample display template file for a Collection.
public class NoteDisplaySample {
    
    let fileManager  = FileManager.default
    
    static let cssFolderName        = "css"
    static let cssFileName          = "styles.css"
    static let mirrorFolderName     = "mirror"
    static let templatesFolderName  = "templates"
    static let scriptsFolderName    = "scripts"
    static let noteMirrorWords      = ["note", "mirror"]
    static let indexMirrorWords     = ["index", "mirror"]
    static let scriptExtension      = ".tcz"
    static let sampleMirrorTemplate = "note_mirror.html"
    static let indexMirrorTemplate  = "index_mirror.html"
    public static let sampleReportTemplateFileName = "sample report template"
    
    var io: FileIO!
    
    var webRoot = ""
    
    var noteIndexFileNames: [FileName] = []
    var scriptFileNames:    [FileName] = []
    
    let mirrorError = LogEvent(subsystem: "com.powersurgepub.notenik",
                               category: "NoteMirror", level: .error,
                               message: "Problems encountered during mirroring")
    var mirrorErrors: [LogEvent] = []
    
    
    var code = Markedup(format: .htmlDoc)
    var titleLabel = NotenikConstants.titleCommon
    var tagsLabel = NotenikConstants.tagsCommon
    var datesAndTimes = false
    var collection: NoteCollection!
    var shortMods = "&h"
    var longMods = "&o"
    
    /// Initializes a new instance of NoteDisplaySample.
    public init() {

    }
    
    /// Generate Sample Display Files.
    /// - Parameter io: The Notenik I/O module for the desired Collection.
    /// - Returns: True if successful, false if errors.
    public func genSampleFiles(io: NotenikIO) -> Bool {
        
        var ok = true
        
        // -----------------------------------------------------------
        //
        // MARK: Gather needed resources.
        //
        // -----------------------------------------------------------

        let displayPrefs = DisplayPrefs.shared
        var fileIO: FileIO
        if io is FileIO {
            fileIO = io as! FileIO
        } else {
            return false
        }
        guard fileIO.collectionOpen else { return false }
        collection = io.collection!
        let resourceLib = io.collection!.lib
        let notes = resourceLib!.getResource(type: .notes)
        let dict = collection.dict
        titleLabel = collection.titleFieldDef.fieldLabel.commonForm
        tagsLabel = collection.tagsFieldDef.fieldLabel.commonForm
        
        // -----------------------------------------------------------
        //
        // MARK: Create the css styles file.
        //
        // -----------------------------------------------------------
        
        var css = ""
        if displayPrefs.bodyCSS != nil {
            css = displayPrefs.bodyCSS!
        }
        let cssFile = ResourceFileSys(parent: notes,
                                      fileName: ResourceFileSys.displayCSSFileName,
                                      type: .displayCSS)
        ok = cssFile.write(str: css)
        guard ok else { return false }
        
        // -----------------------------------------------------------
        //
        // MARK: Create the template file.
        //
        // -----------------------------------------------------------
        
        // Start the template.
        code = Markedup(format: .htmlDoc)
        code.templateNextRec()
        
        code.startDoc(withTitle: "=$\(titleLabel)$=",
                          withCSS: css,
                          linkToFile: false,
                          withJS: nil)
        
        // Include all the fields, formatted as they are on the Display tab.
        code.templateAllFields()
        
        // Format fields one by one, but comment these lines out.
        code.templateIfField(fieldname: "=$IndividualFields$=")
        code.startMultiLineComment("For Detailed Formatting Control, Uncomment these lines:")
        
        // Format Tags first
        code.templateIfField(fieldname: "=$\(tagsLabel)$=")
        code.startParagraph()
        code.startEmphasis()
        code.append("=$\(tagsLabel)$=")
        code.finishEmphasis()
        code.finishParagraph()
        code.templateEndIf()
        
        // Format Title next
        if collection.h1Titles {
            code.heading(level: 1, text: "=$\(titleLabel)\(shortMods)$=")
        } else {
            code.startParagraph()
            code.startStrong()
            code.append("=$\(titleLabel)\(shortMods)$=")
            code.finishStrong()
            code.finishParagraph()
        }
        
        // Now format everything else.
        datesAndTimes = false
        var i = 0
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                let label = def!.fieldLabel.commonForm
                if label == titleLabel
                    || label == tagsLabel {
                    // Already done
                } else if label == NotenikConstants.dateAddedCommon
                        || label == NotenikConstants.dateModifiedCommon
                        || label == NotenikConstants.timestampCommon {
                    datesAndTimes = true
                } else {
                    genTemplateForField(def: def!)
                }
            }
            i += 1
        }
        
        code.finishMultiLineComment("")
        code.templateEndIf()
        
        // Finish up the template code.
        code.finishDoc()
        code.templateLoop()
        
        // Save it to disk.
        let templateFile = ResourceFileSys(parent: notes,
                                           fileName: ResourceFileSys.displayHTMLFileName,
                                           type: .display)
        ok = templateFile.write(str: code.code)
        
        return ok
        
    }
    
    func genTemplateForField(def: FieldDefinition) {
        
        let common = def.fieldLabel.commonForm
        
        code.writeLine("")
        code.templateIfField(fieldname: "=$\(common)$=")
        
        if def.fieldType is LinkType {
            code.startParagraph()
            code.append(def.fieldLabel.properForm)
            code.append(": ")
            code.link(text: "=$\(common)$=",
                path: "=$\(common)$=")
            code.finishParagraph()
        } else if common == NotenikConstants.codeCommon {
            code.startParagraph()
            code.append(def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.codeBlock("=$\(common)$=")
        } else if def.fieldType.typeString == NotenikConstants.longTextType {
            code.startParagraph()
            code.append(def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.writeLine("=$\(common)\(longMods)$=")
        } else if common == collection.bodyFieldDef.fieldLabel.commonForm {
            if collection.bodyLabel {
                code.startParagraph()
                code.append(def.fieldLabel.properForm)
                code.append(": ")
                code.finishParagraph()
            }
            code.writeLine("=$\(common)w1o$=")
        } else {
            code.startParagraph()
            code.append(def.fieldLabel.properForm)
            code.append(": ")
            code.append("=$\(common)$=")
            code.finishParagraph()
        }
        
        code.templateEndIf()
    }
    
}
