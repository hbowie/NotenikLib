//
//  LineMaker.swift
//  Notenik
//
//  Created by Herb Bowie on 2/11/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Format a note as a series of text lines. 
public class NoteLineMaker {
    
    public var writer: LineWriter
    let minCharsToValue = 8
    public var fieldsWritten = 0
    
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
    public func putNote(_ note: Note) -> Int {
        if note.fileInfo.format == .toBeDetermined {
            note.fileInfo.format = .notenik
        }
        
        /// If we have more data than can fit in a restricted format,
        /// then switch to the Notenik format.
        if note.fileInfo.format != .notenik
            && note.fileInfo.format != .multiMarkdown {
            for def in note.collection.dict.list {
                let field = note.getField(def: def)
                if field != nil && field!.value.hasData {
                    if def.fieldLabel.commonForm == NotenikConstants.title
                        || def.fieldLabel.commonForm == NotenikConstants.body {
                        break
                    } else if def.fieldLabel.commonForm == NotenikConstants.tags {
                        if note.fileInfo.format == .multiMarkdown {
                            break
                        } else {
                            note.fileInfo.format = .notenik
                        }
                    } else {
                        note.fileInfo.format = .notenik
                    }
                }
            }
        }
        
        fieldsWritten = 0
        writer.open()
        if note.fileInfo.format == .multiMarkdown && note.fileInfo.mmdMetaStartLine.count > 0 {
            writer.writeLine(note.fileInfo.mmdMetaStartLine)
        }
        if note.hasTitle() {
            putTitle(note)
        }
        if note.hasTags() {
            putTags(note)
        }
        
        let collection = note.collection
        var i = 0
        while i < collection.dict.count {
            let def = collection.dict.getDef(i)
            if def != nil &&
                def! != collection.titleFieldDef &&
                def! != collection.bodyFieldDef &&
                def! != collection.tagsFieldDef {
                let field = note.getField(def: def!)
                putField(field, format: note.fileInfo.format)
            }
            i += 1
        }
        if note.fileInfo.format == .multiMarkdown && note.fileInfo.mmdMetaEndLine.count > 0 {
            writer.writeLine(note.fileInfo.mmdMetaEndLine)
            writer.endLine()
        }
        if note.hasBody() {
            putBody(note)
        }
        writer.close()
        return fieldsWritten
    }
    
    func putTitle(_ note: Note) {
        switch note.fileInfo.format {
        case .markdown:
            writer.writeLine("# \(note.title.value)")
            fieldsWritten += 1
        case .multiMarkdown:
            putField(note.getTitleAsField(), format: note.fileInfo.format)
        case .notenik:
            putField(note.getTitleAsField(), format: note.fileInfo.format)
        case .plainText:
            break
        default:
            putField(note.getTitleAsField(), format: note.fileInfo.format)
        }
    }
    
    func putTags(_ note: Note) {
        switch note.fileInfo.format {
        case .markdown:
            writer.writeLine("#\(note.tags.value)")
            fieldsWritten += 1
        case .multiMarkdown:
            putField(note.getTagsAsField(), format: note.fileInfo.format)
        case .notenik:
            putField(note.getTagsAsField(), format: note.fileInfo.format)
        case .plainText:
            break
        default:
            putField(note.getTagsAsField(), format: note.fileInfo.format)
        }
    }
    
    func putBody(_ note: Note) {
        switch note.fileInfo.format {
        case .markdown:
            putFieldValue(note.body)
            fieldsWritten += 1
        case .multiMarkdown:
            writer.endLine()
            putFieldValue(note.body)
            fieldsWritten += 1
        case .notenik:
            putField(note.getBodyAsField(), format: note.fileInfo.format)
        case .plainText:
            putFieldValue(note.body)
            fieldsWritten += 1
        default:
            putField(note.getBodyAsField(), format: note.fileInfo.format)
        }
    }
    
    /// Write a field's label and value, along with the usual Notenik formatting.
    ///
    /// - Parameter field: The Note Field to be written.
    public func putField(_ field: NoteField?, format: NoteFileFormat) {
        if field != nil && field!.value.hasData {
            putFieldName(field!.def, format: format)
            putFieldValue(field!.value)
            fieldsWritten += 1
        }
    }
    
    /// Write the field label to the writer, along with any necessary preceding and following text.
    ///
    /// - Parameter def: The Field Definition for the field.
    func putFieldName(_ def: FieldDefinition, format: NoteFileFormat) {
        if fieldsWritten > 0 && format == .notenik {
            writer.endLine()
        }
        let proper = def.fieldLabel.properForm
        writer.write(proper)
        writer.write(": ")
        if def.fieldType.isTextBlock {
            writer.endLine()
            writer.endLine()
        } else {
            var charsWritten = proper.count + 2
            while charsWritten < minCharsToValue {
                writer.write(" ")
                charsWritten += 1
            }
        }
    }
    
    /// Write the field value to the writer.
    ///
    /// - Parameter value: A StringValue or one of its descendants.
    func putFieldValue(_ value: StringValue) {
        writer.writeLine(value.value)
    }
}
