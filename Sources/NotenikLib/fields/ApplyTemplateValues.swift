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

import NotenikUtils

/// A utility class that will examine the values found for each field in the Collection's template,
/// and use those values to make appropriate changes to the Collection's Field Dictionary.
class ApplyTemplateValues {
    
    var collection:   NoteCollection!
    var dict:         FieldDictionary!
    var templateNote: Note
    
    /// Initialize with the template note after it has already been populated.
    init(templateNote: Note) {
        self.templateNote = templateNote
    }
    
    /// Go through the Note's values, and apply them to the dictionary, where appropriate.
    /// Assumption: field lables found in the template have already been added
    /// to the Collection's dictionary, using default types based on the labels. 
    func applyValuesToDict(collection: NoteCollection) {
        
        self.collection = collection
        self.dict = collection.dict
        
        var dateCount = 0

        for def in dict.list {
            let val = templateNote.getFieldAsValue(label: def.fieldLabel.commonForm)
            if val.count > 0 {
                parseValue(def: def, value: val.value)
            }
            
            if def.fieldType.typeString == NotenikConstants.titleCommon
                    && collection.idFieldDef.fieldLabel.commonForm == NotenikConstants.titleCommon {
                collection.idFieldDef = def
            }
            
            if def.fieldType.typeString == NotenikConstants.titleCommon
                    && collection.titleFieldDef.fieldLabel.commonForm == NotenikConstants.titleCommon {
                collection.titleFieldDef = def
            }
            
            if def.fieldType.typeString == NotenikConstants.tagsCommon
                && collection.tagsFieldDef.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                collection.tagsFieldDef = def
            }
            
            if def.fieldType.typeString == NotenikConstants.dateCommon {
                dateCount += 1
                if dateCount == 1 {
                    collection.dateFieldDef = def
                }
            }
            
            if def.fieldType.typeString == NotenikConstants.statusCommon
                && collection.statusFieldDef.fieldLabel.commonForm == NotenikConstants.statusCommon {
                collection.statusFieldDef = def
            }
            
            if def.fieldType.typeString == NotenikConstants.bodyCommon
                    && collection.bodyFieldDef.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                collection.bodyFieldDef = def
            }
            
            if def.fieldType is TimestampType {
                collection.hasTimestamp = true
            }
            
        } // end of for loop through field definitions
    } // end of func applyValuesToDict
    
    /// Parse the value and modify the definition accordingly.
    func parseValue(def: FieldDefinition, value: String) {
        
        var typeStr = SolidString()
        var typeValues = SolidString()
        
        var leftAngle: Character = " "
        var colon: Character = " "
        for char in value {
            if char == "<" && leftAngle == " " && typeStr.count == 0 {
                leftAngle = char
            } else if char == ">" && leftAngle == "<" {
                break
            } else if char == ":" && colon == " " {
                colon = char
            } else if colon == ":" {
                typeValues.append(char)
            } else {
                typeStr.append(char)
            }
        }
        
        if leftAngle == " " && def.fieldLabel.commonForm == NotenikConstants.statusCommon && typeStr.count > 0 && typeValues.count == 0 {
            leftAngle = "<"
            typeValues = SolidString(typeStr)
            typeStr = SolidString(NotenikConstants.statusCommon)
        }
        
        let typeStrCommon = typeStr.common
        
        if leftAngle == " " && typeStrCommon == NotenikConstants.pickFromType && typeValues.count > 0 {
            leftAngle = "<"
        }
        
        guard leftAngle == "<" && typeStrCommon.count > 0 else { return }
        
        if typeStrCommon == NotenikConstants.pickFromType {
            let pickList = PickList(values: typeValues.str)
            if pickList.count > 0 {
                def.pickList = pickList
            }
        } else {
            def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStrCommon)
            def.pickList = def.fieldType.genPickList()
        }
        
        if def.fieldType.typeString == NotenikConstants.statusCommon {
            if typeValues.count > 0 {
                let config = collection.statusConfig
                config.set(typeValues.str)
                collection.typeCatalog.statusValueConfig = config
            }
        }
        
    }
} // end of class ApplyTemplateValues
