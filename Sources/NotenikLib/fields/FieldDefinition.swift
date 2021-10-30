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
    
    public var fieldLabel:  FieldLabel = FieldLabel()
    public var fieldType:   AnyType = StringType()
    public var pickList:    PickList?
    public var lookupFrom:  String = ""
    
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
    }
    
    /// Initialize with a FieldLabel object
    convenience init (typeCatalog: AllTypes, label: FieldLabel) {
        self.init(typeCatalog: typeCatalog)
        self.fieldLabel = label
        fieldType = typeCatalog.assignType(label: label, type: nil)
        pickList = fieldType.genPickList()
    }
    
    /// Initialize with a string label and an integer type
    convenience init (typeCatalog: AllTypes, label: String, type: String) {
        self.init(typeCatalog: typeCatalog)
        fieldLabel.set(label)
        fieldType = typeCatalog.assignType(label: fieldLabel, type: type)
        pickList = fieldType.genPickList()
    }
    
    var isBody: Bool {
        return fieldType.isBody
    }
    
    public func copy() -> FieldDefinition {
        let copy = FieldDefinition(typeCatalog: typeCatalog)
        copy.fieldLabel = self.fieldLabel.copy()
        copy.fieldType  = self.fieldType
        copy.pickList   = self.pickList
        return copy
    }
    
    public var description: String {
        return("Proper: \(fieldLabel.properForm), Common: \(fieldLabel.commonForm), type: \(fieldType.typeString)")
    }
    
    public func display() {
        print("FieldDefinition")
        fieldLabel.display()
        print("Field Type String: \(fieldType.typeString)")
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
