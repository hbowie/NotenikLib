//
//  InfoLineMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/9/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class InfoLineMaker {
    
    public var writer: KeyValueWriter
    
    /// Initialize with no input, assuming the writer will be a Big String Writer.
    public init() {
        writer = KeyValueWriter()
    }
    
    func putInfo(collection: NoteCollection, bunch: BunchOfNotes?, subFolder: Bool = false) {
        
        guard let lib = collection.lib else { return }

        writer.append(label: NotenikConstants.title, value: collection.title)
        writer.append(label: NotenikConstants.titleSetByUser, value: "\(collection.titleSetByUser)")
        writer.append(label: NotenikConstants.link, value: lib.getPath(type: .collection))
        writer.append(label: "Sort Parm", value: collection.sortParm.str)
        writer.append(label: "Sort Descending", value: "\(collection.sortDescending)")
        writer.append(label: NotenikConstants.sortBlankDatesLast, value: "\(collection.sortBlankDatesLast)")
        writer.append(label: "Other Fields Allowed", value: String(collection.otherFields))
        if bunch != nil && !subFolder {
            writer.append(label: NotenikConstants.lastIndexSelected, value: "\(bunch!.listIndex)")
        }
        writer.append(label: NotenikConstants.mirrorAutoIndex,   value: "\(collection.mirrorAutoIndex)")
        writer.append(label: NotenikConstants.bodyLabelDisplay,  value: "\(collection.bodyLabel)")
        writer.append(label: NotenikConstants.titleDisplayOpt,   value: "\(collection.titleDisplayOption.rawValue)")
        writer.append(label: NotenikConstants.displayMode,       value: collection.displayMode.rawValue)
        writer.append(label: NotenikConstants.mathJax, value: "\(collection.mathJax)")
        writer.append(label: NotenikConstants.imgLocal, value: "\(collection.imgLocal)")
        writer.append(label: NotenikConstants.missingTargets, value: "\(collection.missingTargets)")
        writer.append(label: NotenikConstants.curlyAposts, value: "\(collection.curlyApostrophes)")
        writer.append(label: NotenikConstants.extLinksNewWindows, value: "\(collection.extLinksOpenInNewWindows)")
        writer.append(label: NotenikConstants.scrollingSync, value: "\(collection.scrollingSync)")
        if collection.lastStartupDate.count > 0 {
            writer.append(label: NotenikConstants.lastStartupDate, value: collection.lastStartupDate)
        }
        if collection.shortcut.count > 0 && !subFolder {
            writer.append(label: NotenikConstants.shortcut, value: collection.shortcut)
        }
        if !collection.webBookPath.isEmpty {
            writer.append(label: NotenikConstants.webBookFolder, value: collection.webBookPath)
        }
        if !collection.webBookAsEPUB {
            writer.append(label: NotenikConstants.webBookEPUB, value: "false")
        }
        
        if collection.noteFileFormat != .toBeDetermined {
            writer.append(label: NotenikConstants.noteFileFormat, value: collection.noteFileFormat.rawValue)
        }
        
        writer.append(label: NotenikConstants.hashTags, value: "\(collection.hashTags)")
        
        if !collection.windowPosStr.isEmpty && !subFolder {
            writer.append(label: NotenikConstants.windowNumbers, value: collection.windowPosStr)
        }
        
        writer.append(label: NotenikConstants.columnWidths, value: "\(collection.columnWidths)")
        
        for usage in collection.mkdownCommandList.commands {
            if usage.saveForCollection && !usage.noteID.isEmpty {
                let label = "\(usage.command) Note ID"
                let value = usage.noteID
                writer.append(label: label, value: value)
            }
        }
        
        if collection.highestTitleNumber > 0 {
            writer.append(label: NotenikConstants.highestTitleNumber, value: "\(collection.highestTitleNumber)")
        }
        
        if collection.noteIdentifier.uniqueIdRule != .titleOnly {
            writer.append(label: NotenikConstants.noteIdRule, value: collection.noteIdentifier.uniqueIdRule.rawValue)
            writer.append(label: NotenikConstants.noteIdAux, value: collection.noteIdentifier.noteIdAuxField)
            writer.append(label: NotenikConstants.textIdRule, value: collection.noteIdentifier.textIdRule.rawValue)
            writer.append(label: NotenikConstants.textIdSep, value: "\"\(collection.noteIdentifier.textIdSep)\"")
        }
        
    }
    
    public var str: String {
        return writer.str
    }
}
