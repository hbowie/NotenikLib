//
//  NoteLineMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/11/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// Format a note as a series of text lines. 
public class NoteLineMaker {
    
    public var writer: LineWriter
    let minCharsToValue = 8
    public var fieldsWritten = 0
    var fieldMods = " "
    var parentLabel = ""
    
    /// Initialize with no input, assuming the writer will be a Big String Writer.
    public init() {
        writer = BigStringWriter()
    }
    
    /// Initialize with the Line Writer to be used.
    ///
    /// - Parameter writer: The line writer to be used.
    public init(_ writer: LineWriter) {
        self.writer = writer
    }
    
    /// Format all of a note's fields and send them to the writer.
    ///
    /// - Parameter note: The note to be written.
    /// - Returns: The number of fields written.
    public func putNote(_ note: Note, includeAttachments: Bool = false) -> Int {
        
        if note.noteID.noteFileFormat == .multiMarkdown && note.collection.noteFileFormat == .yaml {
            note.noteID.noteFileFormat = note.collection.noteFileFormat
        } else if note.noteID.noteFileFormat == .toBeDetermined {
            note.noteID.setNoteFileFormat(newFormat: note.collection.noteFileFormat)
            if note.noteID.mmdOrYaml {
                note.noteID.mmdMetaStartLine = "---"
                note.noteID.mmdMetaEndLine = "---"
            }
        }
        
        if note.noteID.noteFileFormat == .yaml {
            if note.noteID.mmdMetaStartLine.isEmpty {
                note.noteID.mmdMetaStartLine = "---"
            }
            if note.noteID.mmdMetaEndLine.isEmpty {
                note.noteID.mmdMetaEndLine = "---"
            }
        }
        
        /// If we have more data than can fit in a restricted format,
        /// then switch formats.
        if note.noteID.noteFileFormat != .notenik
            && !note.noteID.mmdOrYaml {
            for def in note.collection.dict.list {
                let field = note.getField(def: def)
                if field != nil && field!.value.hasData {
                    if def.fieldLabel.commonForm == NotenikConstants.titleCommon
                        || def.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                        break
                    } else if def.fieldLabel.commonForm == NotenikConstants.tags {
                        if note.noteID.mmdOrYaml || note.noteID.noteFileFormat == .markdown {
                            break
                        } else {
                            note.noteID.noteFileFormat = .notenik
                        }
                    } else {
                        note.noteID.noteFileFormat = .notenik
                    }
                }
            }
        }
        
        fieldsWritten = 0
        fieldMods = " "
        writer.open()
        let collection = note.collection
        
        if note.noteID.mmdOrYaml && note.noteID.mmdMetaStartLine.count > 0 {
            writer.writeLine(note.noteID.mmdMetaStartLine)
        }
        if note.hasTitle() {
            putTitle(note)
        } else {
            putEmptyField(def: collection.titleFieldDef,
                          format: note.noteID.noteFileFormat,
                          newLabel: collection.newLabelForTitle)
        }
        if note.hasTags() {
            putTags(note)
        } else {
            putEmptyField(def: collection.tagsFieldDef,
                          format: note.noteID.noteFileFormat)
        }
        
        var i = 0
        while i < collection.dict.count {
            let def = collection.dict.getDef(i)
            fieldMods = " "
            if def != nil &&
                def! != collection.titleFieldDef &&
                def! != collection.bodyFieldDef &&
                def! != collection.tagsFieldDef &&
                def! != collection.textFormatFieldDef {
                if def == collection.backlinksDef {
                    let field = note.getFieldAsValue(def: def!)
                    if let backlinkField = field as? BacklinkValue {
                        let notePointers = backlinkField.notePointers
                        putWikilinks(note: note, def: def!, notePointers: notePointers)
                    }
                } else if def == collection.wikilinksDef {
                    let field = note.getFieldAsValue(def: def!)
                    if let wikilinkField = field as? WikilinkValue {
                        let notePointers = wikilinkField.notePointers
                        putWikilinks(note: note, def: def!, notePointers: notePointers)
                    }
                } else if def!.parentField {
                    parentLabel = def!.fieldLabel.properForm
                    putParent(parentLabel: def!.fieldLabel.properForm)
                } else {
                    let field = note.getField(def: def!)
                    if field == nil || field!.value.isEmpty {
                        putEmptyField(def: def, format: note.noteID.noteFileFormat)
                    } else {
                        putField(field, format: note.noteID.noteFileFormat)
                    }
                }
            }
            i += 1
        }
        if note.noteID.mmdOrYaml && note.noteID.mmdMetaEndLine.count > 0 {
            writer.writeLine(note.noteID.mmdMetaEndLine)
            if note.noteID.noteFileFormat == .yaml {
                writer.writeLine("")
            }
        }
        if includeAttachments && !note.attachments.isEmpty {
            let attachmentsPath = note.collection.lib.getPath(type: .attachments)
            print("Attachments path: \(attachmentsPath)")
            let statusConfig = note.collection.statusConfig
            var attachmentsValue = ""
            for attachment in note.attachments {
                let attachmentPath = FileUtils.joinPaths(path1: attachmentsPath, path2: attachment.fullName)
                if !attachmentsValue.isEmpty {
                    attachmentsValue.append("; ")
                }
                attachmentsValue.append(attachmentPath)
            }
            let attachmentsField = NoteField(label: "Attachments",
                                             value: attachmentsValue,
                                             typeCatalog: note.collection.typeCatalog,
                                             statusConfig: statusConfig)
            putField(attachmentsField, format: note.noteID.noteFileFormat)
        }
        if note.hasBody() {
            putBody(note)
        } else {
            putEmptyField(def: collection.bodyFieldDef,
                          format: note.noteID.noteFileFormat)
        }
        writer.close()
        return fieldsWritten
    }
    
    func putTitle(_ note: Note) {
        switch note.noteID.noteFileFormat {
        case .markdown:
            writer.writeLine("# \(note.title.value)")
            fieldsWritten += 1
        case .multiMarkdown:
            putField(note.getTitleAsField(), format: note.noteID.noteFileFormat, newLabel: note.collection.newLabelForTitle)
        case .notenik:
            putField(note.getTitleAsField(), format: note.noteID.noteFileFormat, newLabel: note.collection.newLabelForTitle)
        case .plainText:
            break
        default:
            putField(note.getTitleAsField(), format: note.noteID.noteFileFormat, newLabel: note.collection.newLabelForTitle)
        }
    }
    
    func putTags(_ note: Note) {
        let tags = note.tags
        fieldMods = " "
        if note.collection.hashTagsOption == .fieldWithHashSymbols {
            fieldMods = "#"
        }
        switch note.noteID.noteFileFormat {
        case .markdown:
            if note.collection.hashTagsOption == .fieldWithHashSymbols {
                writer.writeLine(tags.valueToWrite(mods: fieldMods))
            } else {
                writer.writeLine("#\(note.tags.value)")
            }
            fieldsWritten += 1
        case .multiMarkdown:
            putField(note.getTagsAsField(), format: note.noteID.noteFileFormat)
        case .notenik:
            if note.collection.hashTagsOption != .inlineHashtags {
                putField(note.getTagsAsField(), format: note.noteID.noteFileFormat)
            }
        case .plainText:
            break
        default:
            putField(note.getTagsAsField(), format: note.noteID.noteFileFormat)
        }
    }
    
    func putWikilinks(note: Note, def: FieldDefinition, notePointers: WikiLinkTargetList) {
        if !note.noteID.mmdOrYaml {
            writer.endLine()
        }
        for notePointer in notePointers {
            writer.writeLine("\(def.fieldLabel.properForm): \(notePointer.pathSlashItem)")
        }
        fieldsWritten += 1
    }
    
    func putBody(_ note: Note) {
        switch note.noteID.noteFileFormat {
        case .plainText:
            putFieldValueOnSameLine(note.body)
        case .markdown:
            writer.endLine()
            putFieldValueOnSameLine(note.body)
        case .multiMarkdown:
            if !note.noteID.mmdMetaEndLine.isEmpty && note.noteID.mmdMetaEndLine != " " {
                writer.endLine()
            }
            putFieldValueOnSameLine(note.body)
        case .yaml:
            putFieldValueOnSameLine(note.body)
        case .notenik:
            putField(note.getBodyAsField(), format: .notenik, newLabel: note.collection.newLabelForBody)
        default:
            putField(note.getBodyAsField(), format: note.noteID.noteFileFormat, newLabel: note.collection.newLabelForBody)
        }
        fieldsWritten += 1
    }
    
    func putParent(parentLabel: String) {
        writer.writeLine("\(parentLabel):")
    }
    
    /// Write a field's label and value, along with the usual Notenik formatting.
    ///
    /// - Parameter field: The Note Field to be written.
    public func putField(_ possibleField: NoteField?, format: NoteFileFormat, newLabel: String = "") {
        guard let field = possibleField else { return }
        guard field.value.hasData else { return }
        guard field.def.fieldType.typeString != NotenikConstants.folderCommon else { return }
        var multiCount = 1
        if let multi = field.value as? MultiValues {
            multiCount = multi.multiCount
        }
        putFieldName(field.def, multiCount: multiCount, format: format, newLabel: newLabel)
        putFieldValue(field, format: format)
        fieldsWritten += 1
    }
    
    public func putEmptyField(def: FieldDefinition?, format: NoteFileFormat, newLabel: String = "") {
        guard def != nil else { return }
        guard def!.fieldType.typeString != NotenikConstants.folderCommon else { return }
        guard def!.writeEmpty else { return }
        putFieldName(def!, multiCount: 0, format: format, newLabel: newLabel)
        if !def!.fieldType.isTextBlock {
            writer.endLine()
        }
        fieldsWritten += 1
    }
    
    /// Write the field label to the writer, along with any necessary preceding and following text.
    ///
    /// - Parameter def: The Field Definition for the field.
    func putFieldName(_ def: FieldDefinition, multiCount: Int = 1, format: NoteFileFormat, newLabel: String = "") {
        if fieldsWritten > 0 && format == .notenik {
            writer.endLine()
        }
        var proper = def.fieldLabel.properForm
        if !newLabel.isEmpty {
            proper = newLabel
        }
        if !parentLabel.isEmpty && def.fieldLabel.parentLabel == parentLabel {
            writer.write("  \(proper):")
        } else {
            writer.write("\(proper):")
        }
        var usingYAMLdashLines = false
        if format == .yaml {
            if multiCount > 1 {
                usingYAMLdashLines = true
            }
        }
        if def.fieldType.isTextBlock && format == .notenik {
            writer.endLine()
            writer.endLine()
        } else if !usingYAMLdashLines {
            writer.write(" ")
            if format != .yaml {
                var charsWritten = proper.count + 2
                while charsWritten < minCharsToValue {
                    writer.write(" ")
                    charsWritten += 1
                }
            }
        }
    }
    
    func putFieldValue(_ field: NoteField, format: NoteFileFormat) {
        if format == .yaml {
            putFieldValueInYAML(field)
        } else {
            putFieldValueOnSameLine(field.value)
        }
    }
    
    func putFieldValueInYAML(_ field: NoteField) {
        var written = false
        if let multi = field.value as? MultiValues {
            if multi.multiCount > 1 {
                writer.endLine()
                var i = 0
                while i < multi.multiCount {
                    writer.writeLine("- \(multi.multiAt(i)!)")
                    i += 1
                }
                written = true
            }
        }
        if !written {
            putFieldValueOnSameLine(field.value)
        }
    }
    
    /// Write the field value to the writer.
    ///
    /// - Parameter value: A StringValue or one of its descendants.
    func putFieldValueOnSameLine(_ value: StringValue) {
        writer.writeLine(value.valueToWrite(mods: fieldMods))
    }
}
