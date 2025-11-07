//
//  LineParser.swift
//  Notenik
//
//  Created by Herb Bowie on 12/10/18.
//  Copyright © 2018 - 2024 Herb Bowie (https://hbowie.net)
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
    var flexibleFieldAssignment = false
    
    var note:           Note
    
    var textLine: String?
    var noteLine: NoteLineIn!
    
    var trailingSpaceCount = 0
    
    var possibleParentLabel = ""
    
    var label        = FieldLabel()
    var def          = FieldDefinition()
    var value        = ""
    var valueLines   = 0
    var pendingBlankLines = 0
    
    var mmdMetaStartEndLineCount = 0
    var bodyStarted  = false
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
    public func getNote(defaultTitle: String,
                        template: Bool = false,
                        allowDictAdds: Bool = true,
                        flexibleFieldAssignment: Bool = false) -> Note {
        
        // print("NoteLineParser.getNote")
        // print("  - allow dict adds? \(allowDictAdds)")
        // print("  - flexible field assignment? \(flexibleFieldAssignment)")
        
        self.allowDictAdds = allowDictAdds
        self.flexibleFieldAssignment = flexibleFieldAssignment
        note = Note(collection: collection)
        possibleParentLabel = ""
        label = FieldLabel()
        def = FieldDefinition()
        clearValue()
        
        lineNumber = 0
        fieldNumber = 0
        blankLines = 0
        fileSize   = 0
        mmdMetaStartEndLineCount = 0
        bodyStarted = false
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
                                  possibleParentLabel: possibleParentLabel,
                                  allowDictAdds: allowDictAdds)

            lineNumber += 1
            fileSize += noteLine.line.count + 1
            if noteLine.blankLine {
                blankLines += 1
            }
            
            if !noteLine.indented {
                possibleParentLabel = ""
            }
            
            // See if we should declare the value to be complete at this point.
            if label.validLabel && value.count > 0 && !bodyStarted {
                if noteLine.blankLine
                    && blankLines == 1
                    && mmdMetaStartEndLineCount == 0
                    && fieldNumber > 1 {
                    valueComplete = true
                } else if fieldNumber == 1 && !noteLine.yamlDashLine {
                    valueComplete = true
                } else if noteLine.mmdMetaStartEndLine
                            && (note.noteID.mmdOrYaml) {
                    valueComplete = true
                } else if noteLine.blankLine && !def.fieldType.isTextBlock {
                    valueComplete = true
                }
            }
            
            if noteLine.validLabel && !noteLine.valueFound {
                possibleParentLabel = noteLine.label.properForm
            }
            
            // If we've reached the end of the file, or the label for a new field,
            // then finish up the last field we were working on.
            if noteLine.lastLine
                || noteLine.validLabel
                || valueComplete {
                captureLastField(template: template)
            }
            
            // Reset the value complete flag.
            valueComplete = false
            
            // Now figure out what to do with this line.
            if noteLine.mmdMetaStartEndLine && lineNumber == 1 {
                note.noteID.setNoteFileFormat(newFormat: .multiMarkdown)
                note.noteID.mmdMetaStartLine = noteLine.line
                mmdMetaStartEndLineCount = 1
            } else if noteLine.mmdMetaStartEndLine 
                        && note.noteID.mmdOrYaml
                        && fieldNumber > 1
                        && !bodyStarted
                        && mmdMetaStartEndLineCount > 0 {
                note.noteID.mmdMetaEndLine = noteLine.line
                def = note.collection.bodyFieldDef
                clearValue()
                bodyStarted = true
            } else if noteLine.mmdMetaStartEndLine && note.noteID.noteFileFormat == .toBeDetermined && !bodyStarted && blankLines == 0 {
                note.noteID.mmdMetaEndLine = noteLine.line
                note.noteID.noteFileFormat = .multiMarkdown
            } else if lineNumber == 1 && noteLine.mdH1Line && noteLine.value.count > 0 && !bodyStarted {
                def = collection.titleFieldDef
                value = noteLine.value
                note.noteID.noteFileFormat = .markdown
            } else if note.noteID.noteFileFormat == .markdown && !bodyStarted && noteLine.mdTagsLine {
                def = collection.tagsFieldDef
                value = noteLine.value
                valueComplete = true
            } else if noteLine.validLabel {
                label = noteLine.label
                def   = noteLine.definition!
                value = noteLine.value
                fieldNumber += 1
                if def.fieldType.typeString == NotenikConstants.bodyCommon {
                    bodyStarted = true
                }
                if noteLine.label.hasParent {
                    collection.dict.setParentDef(labelStr: noteLine.label.parentLabel)
                    if note.noteID.noteFileFormat == .plainText || note.noteID.noteFileFormat == .markdown || note.noteID.noteFileFormat == .multiMarkdown {
                        note.noteID.noteFileFormat = .yaml
                    }
                }
            } else if noteLine.blankLine {
                if fieldNumber > 1 
                    && blankLines == 1
                    && mmdMetaStartEndLineCount == 0
                    && !bodyStarted {
                    if note.noteID.noteFileFormat != .yaml && fieldNumber > 2 {
                        note.noteID.noteFileFormat = .multiMarkdown
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
                if noteLine.yamlDashLine && note.noteID.noteFileFormat == .multiMarkdown {
                    note.noteID.noteFileFormat = .yaml
                }
                if noteLine.yamlDashLine && note.noteID.noteFileFormat == .yaml
                    && def.fieldType.typeString != NotenikConstants.bodyCommon
                    && def.fieldType.typeString != NotenikConstants.longTextType
                    && def.fieldType.typeString != NotenikConstants.longTitleCommon
                    && def.fieldType.typeString != NotenikConstants.teaserCommon {
                    appendYAMLvalue()
                } else {
                    appendNonBlankLine()
                }
                if def.isBody {
                    value.append(reader.remaining)
                    captureLastField(template: template)
                    noteComplete = true
                }
            } else {
                // Value with no label
                label.set(collection.bodyFieldDef.fieldLabel.properForm)
                label.validLabel = true
                fieldNumber += 1
                if let labelDef = note.collection.getDef(label: &label, allowDictAdds: allowDictAdds) {
                    def = labelDef
                    value = noteLine.line
                    bodyStarted = true
                    if lineNumber == 1 {
                        note.noteID.noteFileFormat = .plainText
                    } else {
                        if !note.noteID.mmdOrYaml {
                            note.noteID.noteFileFormat = .markdown
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
        if !note.hasTitle() && defaultTitle.count > 0 && defaultTitle != NotenikConstants.templateFileName {
            _ = note.setTitle(defaultTitle)
        }
        if note.noteID.noteFileFormat == .toBeDetermined {
            note.noteID.noteFileFormat = .notenik
        }
        note.identify()
        return note
    }
    
    /// Add the last field found to the note.
    func captureLastField(template: Bool) {
        
        // print("  - captureLastField)")
        // print("    - field def: \(def)")
        
        pendingBlankLines = 0
        guard label.validLabel && value.count > 0 else { return }
        let fieldInDict = collection.dict.contains(def)
        var field = NoteField()
        
        // See which field definition we want to use.
        if !fieldInDict && flexibleFieldAssignment {
            if fieldNumber == 1 {
                field = NoteField(def: collection.titleFieldDef,
                                  statusConfig: collection.statusConfig,
                                  levelConfig: collection.levelConfig)
            } else if def.fieldLabel.commonForm.contains("date") && collection.dateCount == 1 {
                field = NoteField(def: collection.dateFieldDef,
                                  statusConfig: collection.statusConfig,
                                  levelConfig: collection.levelConfig)
            }
        }
        
        if field.def.fieldLabel.isEmpty {
            if fieldInDict || allowDictAdds {
                field = NoteField(def: def,
                                  statusConfig: collection.statusConfig,
                                  levelConfig: collection.levelConfig)
            }
        }
        
        if !field.def.fieldLabel.isEmpty {
            if template {
                field.value = StringValue(value)
            } else {
                field.setValue(value)
            }
            if field.def.fieldType.typeString == NotenikConstants.indexCommon {
                if let indexField = note.getField(def: field.def) {
                    field = indexField
                    if let oldValue = field.value as? IndexValue {
                        oldValue.append(value)
                    } else {
                        field.value.set(value)
                    }
                } else {
                    _ = note.setField(field)
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
                if tags.hashtagsOption == .fieldWithHashSymbols {
                    if collection.hashTagsOption == .notenikField {
                        collection.hashTagsOption = .fieldWithHashSymbols
                    }
                }
            }
            
            switch field.def.fieldType.typeString {
            case NotenikConstants.titleCommon:
                break
            case NotenikConstants.bodyCommon:
                break
            case NotenikConstants.tagsCommon:
                if note.noteID.noteFileFormat == .plainText {
                    note.noteID.noteFileFormat = .yaml
                }
            default:
                if note.noteID.noteFileFormat == .plainText || note.noteID.noteFileFormat == .markdown {
                    note.noteID.noteFileFormat = .yaml
                }
            }
            
            // fieldNumber += 1
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
            && (note.noteID.noteFileFormat == .multiMarkdown || note.noteID.noteFileFormat == .toBeDetermined) {
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
