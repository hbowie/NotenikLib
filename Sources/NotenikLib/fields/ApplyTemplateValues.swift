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
        var linkCount = 0
        
        var creatorFound = false
        var authorDef: FieldDefinition?
        for def in dict.list {
            
            // Attempt to parse the value field, if there is one.
            let val = templateNote.getFieldAsValue(label: def.fieldLabel.commonForm)
            if val.count > 0 {
                parseValue(def: def, value: val.value)
            }
            
            //
            // If needed, update the various singular field definitions for the Collection.
            //
            
            if def.fieldLabel.commonForm == NotenikConstants.authorCommon
                || def.fieldLabel.commonForm == NotenikConstants.artistCommon {
                authorDef = def
            } else if def.fieldLabel.commonForm == NotenikConstants.klassCommon
                        || def.fieldLabel.commonForm == "klass" {
                if collection.klassFieldDef == nil {
                    collection.klassFieldDef = def
                }
            }
            
            switch def.fieldType.typeString {
                
            case NotenikConstants.akaCommon:
                collection.akaFieldDef = def
            
            case NotenikConstants.artistCommon:
                collection.creatorFieldDef = def
                creatorFound = true
                
            case NotenikConstants.attribCommon:
                collection.attribFieldDef = def
                
            case NotenikConstants.authorCommon:
                collection.creatorFieldDef = def
                creatorFound = true
                
            case NotenikConstants.backlinksCommon:
                collection.backlinksDef = def
                
            case NotenikConstants.bodyCommon:
                if collection.bodyFieldDef.fieldLabel.commonForm == NotenikConstants.bodyCommon {
                    collection.bodyFieldDef = def
                }
            
            case NotenikConstants.dateCommon:
                dateCount += 1
                if dateCount == 1 {
                    collection.dateFieldDef = def
                }
                
            case NotenikConstants.imageNameCommon:
                if collection.imageNameFieldDef == nil {
                    collection.imageNameFieldDef = def
                }
                
            case NotenikConstants.indexCommon:
                if collection.indexFieldDef.fieldLabel.commonForm == NotenikConstants.indexCommon {
                    collection.indexFieldDef = def
                }
                
            case NotenikConstants.linkCommon:
                linkCount += 1
                if linkCount == 1 {
                    collection.linkFieldDef = def
                }
                
            case NotenikConstants.minutesToReadCommon:
                if collection.minutesToReadDef == nil {
                    collection.minutesToReadDef = def
                }
                
            case NotenikConstants.recursCommon:
                if collection.recursFieldDef.fieldLabel.commonForm == NotenikConstants.recursCommon {
                    collection.recursFieldDef = def
                }
                
            case NotenikConstants.seqCommon:
                if collection.seqFieldDef == nil {
                    collection.seqFieldDef = def
                }
                
            case NotenikConstants.levelCommon:
                if collection.levelFieldDef == nil {
                    collection.levelFieldDef = def
                }
                
            case NotenikConstants.shortIdCommon:
                if collection.shortIdDef == nil {
                    collection.shortIdDef = def
                }
                
            case NotenikConstants.statusCommon:
                if collection.statusFieldDef.fieldLabel.commonForm == NotenikConstants.statusCommon {
                    collection.statusFieldDef = def
                }
                
            case NotenikConstants.tagsCommon:
                if collection.tagsFieldDef.fieldLabel.commonForm == NotenikConstants.tagsCommon {
                    collection.tagsFieldDef = def
                }
                
            case NotenikConstants.timestampCommon:
                collection.hasTimestamp = true
                if collection.dateAddedFieldDef == nil {
                    collection.dateAddedFieldDef = def
                }
                
            case NotenikConstants.titleCommon:
                if collection.idFieldDef.fieldLabel.commonForm == NotenikConstants.titleCommon {
                    collection.idFieldDef = def
                }
                if collection.titleFieldDef.fieldLabel.commonForm == NotenikConstants.titleCommon {
                    collection.titleFieldDef = def
                }
                
            case NotenikConstants.wikilinksCommon:
                collection.wikilinksDef = def
                
            case NotenikConstants.workLinkCommon:
                collection.workLinkFieldDef = def
                
            case NotenikConstants.workTitleCommon:
                collection.workTitleFieldDef = def
                
            case NotenikConstants.workTypeCommon:
                collection.workTypeFieldDef = def
                
            case NotenikConstants.dateAddedCommon:
                collection.dateAddedFieldDef = def
                
            default:
                break
                
            }
            
        } // end of for loop through field definitions
        
        if !creatorFound && authorDef != nil {
            collection.creatorFieldDef = authorDef!
        }
        
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
            let pickList = KlassPickList(values: typeValues.str)
            pickList.setDefaults()
            def.pickList = pickList
        } else if typeStrCommon == NotenikConstants.lookupType {
            def.fieldType = collection.typeCatalog.assignType(label: def.fieldLabel, type: typeStrCommon)
            def.lookupFrom = typeValues.str
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
        
        if def.fieldType.typeString == NotenikConstants.levelCommon {
            if typeValues.count > 0 {
                let config = collection.levelConfig
                config.set(typeValues.str)
                collection.typeCatalog.levelValueConfig = config
            }
        }
        
    }
} // end of class ApplyTemplateValues
