//
//  TemplateLineMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/7/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class TemplateLineMaker {
    
    public var writer: BigStringWriter
    
    /// Initialize with no input, assuming the writer will be a Big String Writer.
    public init() {
        writer = BigStringWriter()
    }
    
    /// Initialize with the Line Writer to be used.
    ///
    /// - Parameter writer: The line writer to be used.
    public init(_ writer: BigStringWriter) {
        self.writer = writer
    }
    
    public func putTemplate(collection: NoteCollection, subFolder: Bool = false) {
        
        writer.open()
        
        let dict = collection.dict
        var written: [String: FieldDefinition] = [:]
        for def in dict.list {
            if written[def.fieldLabel.commonForm] == nil {
                if def.fieldType.typeString == NotenikConstants.folderCommon && subFolder {
                    continue
                }
                var value = ""
                if def.fieldLabel.commonForm == NotenikConstants.timestampCommon {
                    collection.hasTimestamp = true
                } else if def.fieldLabel.commonForm == NotenikConstants.statusCommon {
                    value = collection.statusConfig.statusOptionsAsString
                } else if def.fieldType.typeString == NotenikConstants.rankCommon {
                    value = "<rank: \(collection.rankConfig.possibleValuesAsString)>"
                } else if def.fieldLabel.commonForm == NotenikConstants.levelCommon {
                    value = "<level: \(collection.levelConfig.intsWithLabels)>"
                } else if def.fieldType.typeString == NotenikConstants.linkCommon {
                    value = "<link\(collection.linkFormatter.toCodes(withOptionalPrefix: true))>"
                } else if def.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                    value = ""
                } else if def.fieldType is LongTextType {
                    value = "<longtext>"
                } else if def.fieldType.typeString == NotenikConstants.lookupType {
                    value = "<lookup: \(def.lookupFrom)>"
                } else if def.fieldType.typeString == NotenikConstants.lookBackType {
                    value = "<lookback: \(def.lookupFrom)>"
                } else if def.pickList != nil 
                            && def.fieldType.typeString != NotenikConstants.authorCommon
                            && def.fieldType.typeString != NotenikConstants.stringType {
                    value = def.pickList!.getTypeWithValues(type: def.fieldType.typeString)
                } else if def.pickList != nil && def.fieldType.typeString == NotenikConstants.pickFromType {
                    value = def.pickList!.getTypeWithValues()
                } else if def.fieldType.typeString == NotenikConstants.seqCommon
                            && collection.seqFormatter.formatStack.count > 0 {
                    value = "<seq: \(collection.seqFormatter.toCodes())>"
                } else if def.fieldType.typeString == NotenikConstants.displaySeqCommon {
                    if let displaySeqType = def.fieldType as? DisplaySeqType {
                        value = "<displayseq: \(displaySeqType.formatString)>"
                    } else {
                        value = "<displayseq>"
                    }
                } else if def.fieldType.typeString == NotenikConstants.backlinksCommon {
                    if let backLinksType = def.fieldType as? BacklinkType {
                        if backLinksType.initialReveal {
                            value = "<backlinks: reveal>"
                        } else {
                            value = "<backlinks>"
                        }
                    }
                } else if def.fieldType.typeString == NotenikConstants.wikilinksCommon {
                    if let wikiLinksType = def.fieldType as? WikilinkType {
                        if wikiLinksType.initialReveal {
                            value = "<wikilinks: reveal>"
                        } else {
                            value = "<wikilinks>"
                        }
                    }
                } else if def.fieldType.typeString != NotenikConstants.stringType {
                    value = "<\(def.fieldType.typeString)>"
                }
                var label = def.fieldLabel.properForm
                if def.fieldType.typeString == NotenikConstants.titleCommon && !collection.newLabelForTitle.isEmpty {
                    label = collection.newLabelForTitle
                } else if def.fieldType.typeString == NotenikConstants.bodyCommon && !collection.newLabelForBody.isEmpty {
                    label = collection.newLabelForBody
                    value = "<body>"
                }
                writer.writeLine("\(label): \(value)")
                writer.endLine()
                written[def.fieldLabel.commonForm] = def
            }
        }
        
        writer.close()
    }
    
    public var str: String {
        return writer.bigString
    }
}
