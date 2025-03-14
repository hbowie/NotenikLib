//
//  ApplyTemplateValues.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/20/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
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
        
        collection.dateCount = 0
        collection.linkCount = 0
        
        collection.creatorFound = false
        collection.authorDef = nil
        collection.personDef = nil
        
        collection.resetFieldInfo()
        
        for def in dict.list {
            
            // Attempt to parse the value field, if there is one.
            let val = templateNote.getFieldAsValue(label: def.fieldLabel.commonForm)
            if val.count > 0 {
                var parsed = false
                if def.fieldType.typeString == NotenikConstants.seqCommon {
                    if let seqValue = val as? SeqValue {
                        parseValue(def: def, value: seqValue.originalValue)
                        parsed = true
                    }
                }
                if !parsed {
                    parseValue(def: def, value: val.value)
                }
            }
            
            collection.registerDef(def)
            
        } // end of for loop through field definitions
        
        if !collection.creatorFound && collection.authorDef != nil {
            collection.creatorFieldDef = collection.authorDef!
        }
        
        // dict.checkTitle()
        
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
        
        if leftAngle == " " &&
            (def.fieldLabel.commonForm == NotenikConstants.statusCommon
                || def.fieldLabel.commonForm == NotenikConstants.levelCommon)
                && typeStr.count > 0 && typeValues.count == 0 {
            leftAngle = "<"
            typeValues = SolidString(typeStr)
            typeStr = SolidString(def.fieldLabel.commonForm)
        }
        
        let typeStrCommon = typeStr.common
        
        if leftAngle == " " && typeStrCommon == NotenikConstants.pickFromType && typeValues.count > 0 {
            leftAngle = "<"
        }
        
        guard leftAngle == "<" && typeStrCommon.count > 0 else { return }
        
        let originalDefTypeStr = def.fieldType.typeString
        
        if typeStrCommon == NotenikConstants.pickFromType && def.fieldLabel.commonForm == NotenikConstants.klassCommon {
            let pickList = KlassPickList(values: typeValues.str)
            pickList.setDefaults()
            def.pickList = pickList
            def.fieldType = collection.typeCatalog.klassType
        } else if typeStrCommon == NotenikConstants.pickFromType {
            let pickList = PickList(values: typeValues.str)
            if pickList.count > 0 {
                def.pickList = pickList
                def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStrCommon)
            }
        } else if typeStrCommon == NotenikConstants.klassCommon {
            def.fieldType = collection.typeCatalog.klassType
            let pickList = KlassPickList(values: typeValues.str)
            pickList.setDefaults()
            def.pickList = pickList
        } else if typeStrCommon == NotenikConstants.comboType {
            let comboList = ComboList()
            def.comboList = comboList
            def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStrCommon)
        } else if typeStrCommon == NotenikConstants.lookupType {
            def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStrCommon)
            def.lookupFrom = typeValues.str
            collection.lookupDefs.append(def)
        } else if typeStrCommon == NotenikConstants.lookBackType {
            def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStrCommon)
            def.lookupFrom = typeValues.str
            collection.lookBackDefs.append(def)
        } else if typeStrCommon == NotenikConstants.displaySeqCommon && !typeValues.isEmpty {
            let seqAltType = DisplaySeqType()
            seqAltType.formatString = typeValues.str
            def.fieldType = seqAltType
        } else if typeStrCommon == NotenikConstants.backlinksCommon && !typeValues.isEmpty {
            let backLinksType = BacklinkType()
            backLinksType.setInitialReveal(str: typeValues.str)
            def.fieldType = backLinksType
        } else if typeStrCommon == NotenikConstants.wikilinksCommon && !typeValues.isEmpty {
            let wikiLinksType = WikilinkType()
            wikiLinksType.setInitialReveal(str: typeValues.str)
            def.fieldType = wikiLinksType
        } else {
            def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStrCommon)
            def.pickList = def.fieldType.genPickList()
            def.comboList = def.fieldType.genComboList()
        }
        
        if def.fieldType.typeString == NotenikConstants.bodyCommon && def.fieldType.typeString != originalDefTypeStr {
            collection.dict.insertPositionFromEnd += 1
        }
        
        if def.fieldType.typeString == NotenikConstants.statusCommon {
            if typeValues.count > 0 {
                let config = collection.statusConfig
                config.set(typeValues.str)
                collection.typeCatalog.statusValueConfig = config
            }
        }
        
        if def.fieldType.typeString == NotenikConstants.levelCommon {
            if typeValues.count > 0 {
                let config = collection.levelConfig
                config.set(typeValues.str)
                collection.typeCatalog.levelValueConfig = config
            }
        }
        
        if def.fieldType.typeString == NotenikConstants.rankCommon {
            if typeValues.count > 0 {
                let config = collection.rankConfig
                config.set(typeValues.str)
                collection.typeCatalog.rankValueConfig = config
            }
        }
        
        if def.fieldType.typeString == NotenikConstants.seqCommon {
            if typeValues.count > 0 {
                collection.seqFormatter = SeqFormatter(with: typeValues.str)
            }
        }
        
        if def.fieldType.typeString == NotenikConstants.linkCommon {
            if typeValues.count > 0 {
                collection.linkFormatter = LinkFormatter(with: typeValues.str)
            }
        }
        
    }
} // end of class ApplyTemplateValues
