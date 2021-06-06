//
//  LevelType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/4/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class LevelType: AnyType {
    
    var config = IntWithLabelConfig()
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.levelCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.level
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.levelCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return LevelValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        return LevelValue(str: str, config: config)
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
           return (label.commonForm == commonLabel
            || label.commonForm == "depth"))
        } else {
            return (type! == typeString)
        }
    }
}
