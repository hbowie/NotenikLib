//
//  WorkTitleType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/27/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class WorkTitleType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = "worktitle"
        
        /// The proper label typically assigned to fields of this type.
        properLabel = "Work Title"
        
        /// The common label typically assigned to fields of this type.
        commonLabel = "worktitle"
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return WorkTitleValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let work = WorkTitleValue(str)
        return work
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
           return (label.commonForm == commonLabel
            || label.commonForm == "work")
        } else {
            return (type! == typeString)
        }
    }
}
