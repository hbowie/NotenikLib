//
//  LineParser.swift
//  Notenik
//
//  Created by Herb Bowie on 12/10/18.
//  Copyright © 2018 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Read lines from a text file,  and create a Note from their content.
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
    var wikilinkStarted = false
    var backlinkStarted = false
    
    var lineNumber   = 0
    var fieldNumber  = 0
    var blankLines   = 0
    var fileSize     = 0
    
    /// Initialize with a functioning Line Reader
    public init (collection: NoteCollection, reader: BigStringReader) {
        
        self.collection = collection
        self.dict = collection.dict
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
        wikilinkStarted = false
        backlinkStarted = false
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
                } else if fieldNumber == 1 && !noteLine.yamlDashLine {
                    valueComplete = true
                } else if noteLine.mmdMetaStartEndLine
                            && (note.fileInfo.format == .multiMarkdown || note.fileInfo.format == .yaml) {
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
            } else if noteLine.mmdMetaStartEndLine && note.fileInfo.mmdOrYaml && !bodyStarted {
                note.fileInfo.mmdMetaEndLine = noteLine.line
            } else if noteLine.mmdMetaStartEndLine && note.fileInfo.format == .toBeDetermined && !bodyStarted && blankLines == 0 {
                note.fileInfo.mmdMetaEndLine = noteLine.line
                note.fileInfo.format = .multiMarkdown
            } else if lineNumber == 1 && noteLine.mdH1Line && noteLine.value.count > 0 && !bodyStarted {
                def = collection.titleFieldDef
                value = noteLine.value
                note.fileInfo.format = .markdown
            } else if note.fileInfo.format == .markdown && !bodyStarted && noteLine.mdTagsLine {
                def = collection.tagsFieldDef
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
                    if note.fileInfo.format != .yaml && fieldNumber > 2 {
                        note.fileInfo.format = .multiMarkdown
                    }
                    def = note.collection.bodyFieldDef
                    clearValue()
                    bodyStarted = true
                } else {
                    if value.count > 0 {
                        pendingBlankLines += 1
                    }
                }
            } else if label.validLabel {
                if noteLine.yamlDashLine && note.fileInfo.format == .multiMarkdown {
                    note.fileInfo.format = .yaml
                }
                if noteLine.yamlDashLine && note.fileInfo.format == .yaml
                    && def.fieldType.typeString != NotenikConstants.bodyCommon
                    && def.fieldType.typeString != NotenikConstants.longTextType
                    && def.fieldType.typeString != NotenikConstants.teaserCommon {
                    appendYAMLvalue()
                } else {
                    appendNonBlankLine()
                }
                if def.isBody {
                    value.append(reader.remaining)
                    captureLastField()
                    noteComplete = true
                }
            } else {
                // Value with no label
                label.set(collection.bodyFieldDef.fieldLabel.properForm)
                label.validLabel = true
                if let labelDef = note.collection.getDef(label: &label, allowDictAdds: allowDictAdds) {
                    def = labelDef
                    value = noteLine.line
                    bodyStarted = true
                    if lineNumber == 1 {
                        note.fileInfo.format = .plainText
                    } else {
                        if !note.fileInfo.mmdOrYaml {
                            note.fileInfo.format = .markdown
                        }
                    }
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
        if !note.hasTitle() && defaultTitle.count > 0 && defaultTitle != ResourceFileSys.templateFileName {
            _ = note.setTitle(defaultTitle)
        }
        if note.fileInfo.format == .toBeDetermined {
            note.fileInfo.format = .notenik
        }
        return note
    }
    
    /// Add the last field found to the note.
    func captureLastField() {
        
        pendingBlankLines = 0
        guard label.validLabel && value.count > 0 else { return }
        let fieldInDict = collection.dict.contains(def)
        if fieldInDict || allowDictAdds {
            let field = NoteField(def: def,
                                  value: value,
                                  statusConfig: collection.statusConfig,
                                  levelConfig: collection.levelConfig)
            if field.def.fieldType.typeString == NotenikConstants.indexCommon {
                if indexStarted {
                    note.appendToIndex(value)
                } else {
                    _ = note.setIndex(value)
                    indexStarted = true
                }
            } else if field.def.fieldType.typeString == NotenikConstants.backlinksCommon {
                if backlinkStarted {
                    note.appendToBacklinks(value)
                } else {
                    _ = note.setBacklinks(value)
                    backlinkStarted = true
                }
            } else if field.def.fieldType.typeString == NotenikConstants.wikilinksCommon {
                if wikilinkStarted {
                    note.appendToWikilinks(value)
                } else {
                    _ = note.setWikilinks(value)
                    wikilinkStarted = true
                }
            } else {
                _ = note.setField(field)
            }
            
            if let tags = field.value as? TagsValue {
                if tags.hashTags {
                    collection.hashTags = true
                }
            }
            
            switch field.def.fieldType.typeString {
            case NotenikConstants.titleCommon:
                break
            case NotenikConstants.bodyCommon:
                break
            case NotenikConstants.tagsCommon:
                if note.fileInfo.format == .plainText {
                    note.fileInfo.format = .yaml
                }
            default:
                if note.fileInfo.format == .plainText || note.fileInfo.format == .markdown {
                    note.fileInfo.format = .yaml
                }
            }
            
            fieldNumber += 1
        }
        label = FieldLabel()
        clearValue()
    }
    
    func appendYAMLvalue() {
        if !value.isEmpty {
            if def.fieldType.typeString == NotenikConstants.authorCommon {
                value.append(", ")
            } else {
                value.append("; ")
            }
        }
        value.append(noteLine.value)
    }
    
    func appendNonBlankLine() {
        if value.count > 0 && valueLines == 0 {
            valueNewLine()
        }
        while pendingBlankLines > 0 && value.count > 0 {
            valueNewLine()
            pendingBlankLines -= 1
        }
        if !bodyStarted && blankLines == 0 && noteLine.indented && noteLine.valueFound
            && (note.fileInfo.format == .multiMarkdown || note.fileInfo.format == .toBeDetermined) {
            value.append(noteLine.value)
        } else {
            value.append(noteLine.line)
        }
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
