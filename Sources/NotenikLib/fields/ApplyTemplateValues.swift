//
//  ApplyTemplateValues.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/20/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A utility class that will examine the values found for each field in the Collection's template,
/// and use those values to make appropriate values to the Collection's FieldDictionary.
class ApplyTemplateValues {
    
    var templateNote: Note
    
    /// Initialize with the template note after it has already been populated.
    init(templateNote: Note) {
        self.templateNote = templateNote
    }
    
    /// Go through the Note's values, and apply them to the dictionary, where appropriate.
    /// Assumption: field lables found in the template have already been added
    /// to the Collection's dictionary, using default types based on the labels. 
    func applyValuesToDict(collection: NoteCollection) {
        let dict = collection.dict
        for def in dict.list {
            var idField = false
            let val = templateNote.getFieldAsValue(label: def.fieldLabel.commonForm)
            if val.value.hasPrefix("<") && val.value.hasSuffix(">") {
                var typeStr = ""
                for char in val.value {
                    if char != "<" && char != ">" {
                        typeStr.append(char)
                        if typeStr.count == 4 && typeStr.lowercased() == "id, " {
                            idField = true
                            typeStr = ""
                        }
                    }
                }
                if typeStr.hasPrefix(PickList.pickFromLiteral) {
                    let pickList = PickList(values: typeStr)
                    if pickList.count > 0 {
                        def.pickList = pickList
                    }
                } else {
                    def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStr)
                    def.pickList = def.fieldType.genPickList()
                }
            } else if val.value.hasPrefix(PickList.pickFromLiteral) || val.value.hasPrefix("<" + PickList.pickFromLiteral) {
                let pickList = PickList(values: val.value)
                if pickList.count > 0 {
                    def.pickList = pickList
                }
            }
            if idField {
                collection.idFieldDef = def
            }
            if def.fieldType is TimestampType {
                collection.hasTimestamp = true
            }
        } // end of for loop through field definitions
    } // end of func applyValuesToDict
} // end of class ApplyTemplateValues
