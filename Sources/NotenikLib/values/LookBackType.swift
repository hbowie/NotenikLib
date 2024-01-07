//
//  LookBackType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/31/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class LookBackType: AnyType {
    
    override init() {

        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.lookBackType
        
        /// The proper label typically assigned to fields of this type.
        properLabel = ""
        
        /// The common label typically assigned to fields of this type.
        commonLabel = ""
        
        /// Can the user edit this type of field?
        userEditable = false
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return LookBackValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        return LookBackValue()
    }
    
}
