//
//  FieldDefinition.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2019 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The label used to identify this field, along with the field type.
public class FieldDefinition: Comparable, CustomStringConvertible {
    
    var typeCatalog: AllTypes!
    
    public var fieldLabel:      FieldLabel = FieldLabel()
    public var fieldType:       AnyType = StringType()
    public var parentField:     Bool = false
    public var pickList:        PickList?
    public var comboList:       ComboList?
    public var lookupFrom:      String = ""
    
    /// Initialize with no parameters, defaulting to a simple String type.
    init() {
        
    }
    
    init(typeCatalog: AllTypes) {
        self.typeCatalog = typeCatalog
        fieldLabel.set("unknown")
        fieldType = typeCatalog.assignType(label: fieldLabel, type: nil)
    }
    
    /// Initialize with a string label and guess the type
    convenience init(typeCatalog: AllTypes, label: String) {
        self.init(typeCatalog: typeCatalog)
        fieldLabel.set(label)
        fieldType = typeCatalog.assignType(label: fieldLabel, type: nil)
        pickList = fieldType.genPickList()
        comboList = fieldType.genComboList()
    }
    
    /// Initialize with a FieldLabel object
    convenience init (typeCatalog: AllTypes, label: FieldLabel) {
        self.init(typeCatalog: typeCatalog)
        self.fieldLabel = label
        fieldType = typeCatalog.assignType(label: label, type: nil)
        pickList = fieldType.genPickList()
        comboList = fieldType.genComboList()
    }
    
    /// Initialize with a string label and an integer type
    public convenience init (typeCatalog: AllTypes, label: String, type: String) {
        self.init(typeCatalog: typeCatalog)
        fieldLabel.set(label)
        fieldType = typeCatalog.assignType(label: fieldLabel, type: type)
        pickList = fieldType.genPickList()
        comboList = fieldType.genComboList()
    }
    
    public func applyTypeConfig(_ configStr: String, collection: NoteCollection) {
        guard !configStr.isEmpty else { return }
        switch fieldType.typeString {
        case NotenikConstants.statusCommon:
            let config = collection.statusConfig
            config.set(configStr)
            collection.typeCatalog.statusValueConfig = config
        case NotenikConstants.rankCommon:
            let config = collection.rankConfig
            config.set(configStr)
            collection.typeCatalog.rankValueConfig = config
        case NotenikConstants.levelCommon:
            let config = collection.levelConfig
            config.set(configStr)
            collection.typeCatalog.levelValueConfig = config
        case NotenikConstants.linkCommon:
            collection.linkFormatter = LinkFormatter(with: configStr)
        case NotenikConstants.lookupType:
            lookupFrom = configStr
        case NotenikConstants.pickFromType:
            pickList = PickList(values: configStr)
        case NotenikConstants.klassCommon:
            let klassPicker = KlassPickList(values: configStr)
            klassPicker.setDefaults()
            pickList = klassPicker
        case NotenikConstants.comboType:
            comboList = ComboList()
        case NotenikConstants.seqCommon:
            collection.seqFormatter = SeqFormatter(with: configStr)
        case NotenikConstants.displaySeqCommon:
            if let seqAltType = fieldType as? DisplaySeqType {
                seqAltType.formatString = configStr
            }
        default:
            break
        }
    }
    
    /// Generate a type configuration string, if one is appropriate. 
    public func extractTypeConfig(collection: NoteCollection) -> String {
        switch fieldType.typeString {
        case NotenikConstants.statusCommon:
            return collection.statusConfig.statusOptionsAsString
        case NotenikConstants.rankCommon:
            return collection.rankConfig.possibleValuesAsString
        case NotenikConstants.levelCommon:
            return collection.levelConfig.intsWithLabels
        case NotenikConstants.linkCommon:
            return collection.linkFormatter.toCodes(withOptionalPrefix: false)
        case NotenikConstants.lookupType:
            return lookupFrom
        case NotenikConstants.pickFromType:
            if pickList == nil {
                return ""
            } else {
                return pickList!.getValueString()
            }
        case NotenikConstants.seqCommon:
            if collection.seqFormatter.formatStack.count > 0 {
                return collection.seqFormatter.toCodes()
            } else {
                return ""
            }
        case NotenikConstants.displaySeqCommon:
            if let displaySeqType = fieldType as? DisplaySeqType {
                return displaySeqType.formatString
            } else {
                return ""
            }
        default:
            return ""
        }
    }
    
    var isBody: Bool {
        return fieldType.isBody
    }
    
    public func copy() -> FieldDefinition {
        let copy = FieldDefinition(typeCatalog: typeCatalog)
        copy.fieldLabel = self.fieldLabel.copy()
        copy.fieldType  = self.fieldType
        copy.pickList   = self.pickList
        copy.comboList  = self.comboList
        return copy
    }
    
    public var description: String {
        return("Proper: \(fieldLabel.properForm), Common: \(fieldLabel.commonForm), type: \(fieldType.typeString)")
    }
    
    /// Should a field of this type be initialized from an optional class template, when
    /// one is available?
    /// - Parameter typeString: The field type.
    /// - Returns: True if copying from the class template is ok, false otherwise.
    public var shouldInitFromKlassTemplate: Bool {
        return typeCatalog.shouldInitFromKlassTemplate(typeString: fieldType.typeString)
    }
    
    public func display() {
        print("FieldDefinition")
        fieldLabel.display()
        print("Field Type String: \(fieldType.typeString)")
        print("Lookup from: \(lookupFrom)")
    }
    
    /// See if one field label is less than another, using the common form of the label.
    public static func < (lhs: FieldDefinition, rhs: FieldDefinition) -> Bool {
        return lhs.fieldLabel < rhs.fieldLabel
    }
    
    /// See if one field label is equal to another, using the common form of the label.
    public static func == (lhs: FieldDefinition, rhs: FieldDefinition) -> Bool {
        return lhs.fieldLabel == rhs.fieldLabel
    }
}
