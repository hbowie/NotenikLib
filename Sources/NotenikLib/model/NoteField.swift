//
//  NoteField.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A particular field, consisting of a definition and a value, belonging to a particular Note. 
public class NoteField: CustomStringConvertible {
    
    public var def:   FieldDefinition
    public var value: StringValue
    
    init() {
        def = FieldDefinition()
        value = StringValue()
    }
    
    convenience init(def: FieldDefinition, value: StringValue) {
        self.init()
        self.def = def
        self.value = value
    }
    
    convenience init(def: FieldDefinition, statusConfig: StatusValueConfig, levelConfig: IntWithLabelConfig) {
        self.init()
        self.def = def
        value = def.fieldType.createValue("")
    }
    
    convenience init(def: FieldDefinition, value: String, statusConfig: StatusValueConfig, levelConfig: IntWithLabelConfig) {
        self.init()
        self.def = def
        self.value = def.fieldType.createValue(value)
    }
    
    convenience init(label: String,
                     value: String,
                     typeCatalog: AllTypes,
                     statusConfig: StatusValueConfig,
                     levelConfig: IntWithLabelConfig) {
        self.init()
        self.def = FieldDefinition(typeCatalog: typeCatalog, label: label)
        self.value = def.fieldType.createValue(value)
    }
    
    public var description: String {
        return "\(def.fieldLabel), type: \(type(of: value)), value: \(value.value)"
    }
    
    func display() {
        print("NoteField.display")
        print("FieldDefinition has label of \(def.fieldLabel)")
        print("Value has type of \(type(of: value))")
        print("Value has value of \(value.value)")
    }
}
