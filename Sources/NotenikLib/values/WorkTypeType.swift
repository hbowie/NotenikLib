//
//  WorkTypeType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/27/19.
//  Copyright © 2019 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class WorkTypeType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.workTypeCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.workType
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.workTypeCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return WorkTypeValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let workType = WorkTypeValue(str)
        return workType
    }
    
}
