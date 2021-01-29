//
//  LineParser.swift
//  Notenik
//
//  Created by Herb Bowie on 12/10/18.
//  Copyright © 2018 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Read lines in the Notenik format, and create a Note from their content.
public class NoteLineParser {
    
    var collection:     NoteCollection
    var dict:           FieldDictionary
    var reader:         BigStringReader
    
    var allowDictAdds = true
    
    var note:           Note
    
    var textLine: String?
    var noteLine: NoteLineIn!
    
    var trailingSpaceCount = 0
    
    var label        = FieldLabel()
    var def          = FieldDefinition()
    var value        = ""
    var valueLines   = 0
    var pendingBlankLines = 0
    
    var bodyStarted  = false
    var indexStarted = false
    
    var lineNumber   = 0
    var fieldNumber  = 0
    var blankLines   = 0
    var fileSize     = 0
    
    /// Initialize with a functioning Line Reader
    public init (collection: NoteCollection, reader: BigStringReader) {
        
        self.collection = collection
        self.dict = collection.dict
        
        // let typeCat = collection.typeCatalog
        // let tagsDef = dict.getDef(NotenikConstants.tags)
        // if tagsDef == nil {
        //     _ = dict.addDef(typeCatalog: typeCat, label: NotenikConstants.tags)
        // }
        
        self.reader = reader
        
        note = Note(collection: collection)
        
    }
    
    /// Get the Note from the input lines
    public func getNote(defaultTitle: String, allowDictAdds: Bool = true) -> Note {
        
        self.allowDictAdds = allowDictAdds
        note = Note(collection: collection)
        label = FieldLabel()
        def = FieldDefinition()
        clearValue()
        
        lineNumber = 0
        fieldNumber = 0
        blankLines = 0
        fileSize   = 0
        bodyStarted = false
        indexStarted = false
        pendingBlankLines = 0
        var valueComplete = false
        var noteComplete = false
        
        reader.open()
        repeat {
            
            // Read and parse the next line and perform some basic accounting.
            noteLine = NoteLineIn(reader: reader,
                                  collection: collection,
                                  bodyStarted: bodyStarted,
                                  allowDictAdds: allowDictAdds)
            lineNumber += 1
            fileSize += noteLine.line.count + 1
            if noteLine.blankLine {
                blankLines += 1
            }
            
            // See if we should declare the value to be complete at this point.
            if label.validLabel && value.count > 0 && !bodyStarted {
                if noteLine.blankLine && blankLines == 1 && fieldNumber > 1 {
                    valueComplete = true
                } else if fieldNumber == 1 {
                    valueComplete = true
                } else if noteLine.mmdMetaStartEndLine
                    && note.fileInfo.format == .multiMarkdown {
                    valueComplete = true
                }
            }
            
            // If we've reached the end of the file, or the label for a new field,
            // then finish up the last field we were working on.
            if noteLine.lastLine
                || noteLine.validLabel
                || valueComplete {
                captureLastField()
            }
            
            // Reset the value complete flag.
            valueComplete = false
            
            // Now figure out what to do with this line.
            if noteLine.mmdMetaStartEndLine && lineNumber == 1 {
                note.fileInfo.format = .multiMarkdown
                note.fileInfo.mmdMetaStartLine = noteLine.line
            } else if noteLine.mmdMetaStartEndLine
                && note.fileInfo.format == .multiMarkdown
                && !bodyStarted {
                note.fileInfo.mmdMetaEndLine = noteLine.line
            } else if lineNumber == 1 && noteLine.mdH1Line && noteLine.value.count > 0 && !bodyStarted {
                label.set(NotenikConstants.title)
                label.validLabel = true
                def = note.collection.getDef(label: &label, allowDictAdds: allowDictAdds)!
                value = noteLine.value
                note.fileInfo.format = .markdown
            } else if note.fileInfo.format == .markdown && !bodyStarted && noteLine.mdTagsLine {
                label.set(NotenikConstants.tags)
                label.validLabel = true
                def = note.collection.getDef(label: &label, allowDictAdds: allowDictAdds)!
                value = noteLine.value
                valueComplete = true
            } else if noteLine.validLabel {
                label = noteLine.label
                def   = noteLine.definition!
                value = noteLine.value
                if def.fieldType.typeString == NotenikConstants.bodyCommon {
                    bodyStarted = true
                }
            } else if noteLine.blankLine {
                if fieldNumber > 1 && blankLines == 1 && !bodyStarted {
                    note.fileInfo.format = .multiMarkdown
                    label.set(NotenikConstants.body)
                    label.validLabel = true
                    def = note.collection.getDef(label: &label, allowDictAdds: allowDictAdds)!
                    clearValue()
                    bodyStarted = true
                } else {
                    if value.count > 0 {
                        pendingBlankLines += 1
                    }
                }
            } else if label.validLabel {
                appendNonBlankLine()
                if def.isBody {
                    value.append(reader.remaining)
                    captureLastField()
                    noteComplete = true
                }
            } else {
                // Value with no label
                label.set(NotenikConstants.body)
                label.validLabel = true
                def = note.collection.getDef(label: &label, allowDictAdds: allowDictAdds)!
                value = noteLine.line
                bodyStarted = true
                if lineNumber == 1 {
                    note.fileInfo.format = .plainText
                } else {
                    note.fileInfo.format = .multiMarkdown
                }
            }
            
            // Don't allow the title field to consume multiple lines. 
            if value.count > 0 && (def.fieldType.typeString == NotenikConstants.titleCommon || def.fieldType.typeString == NotenikConstants.dateCommon) {
                valueComplete = true
            }
            
            if noteLine.lastLine {
                noteComplete = true
            }
            
        } while !noteComplete
        
        reader.close()
        if !note.hasTitle() && defaultTitle.count > 0 && defaultTitle != NotenikConstants.templateFileName {
            _ = note.setTitle(defaultTitle)
        }
        return note
    }
    
    /// Add the last field found to the note.
    func captureLastField() {
        
        pendingBlankLines = 0
        guard label.validLabel && value.count > 0 else { return }
        let fieldInDict = collection.dict.contains(def)
        if fieldInDict || allowDictAdds {
            let field = NoteField(def: def, value: value, statusConfig: collection.statusConfig)
            if field.def.fieldType.typeString == NotenikConstants.indexCommon {
                if indexStarted {
                    note.appendToIndex(value)
                } else {
                    _ = note.setIndex(value)
                    indexStarted = true
                }
            } else {
                _ = note.setField(field)
            }
            fieldNumber += 1
        }
        label = FieldLabel()
        clearValue()
    }
    
    func appendNonBlankLine() {
        if value.count > 0 && valueLines == 0 {
            valueNewLine()
        }
        while pendingBlankLines > 0 && value.count > 0 {
            valueNewLine()
            pendingBlankLines -= 1
        }
        value.append(noteLine.line)
        valueNewLine()
        pendingBlankLines = 0
    }
    
    func valueNewLine() {
        value.append("\n")
        valueLines += 1
    }
    
    func clearValue() {
        value = ""
        valueLines = 0
    }
    
}
