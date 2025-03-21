//
//  DateModifiedType.swift
//
//  Created by Herb Bowie on 12/23/20.
//
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class DateModifiedType: AnyType {
    
    override init() {
         
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.dateModifiedCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.dateModified
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.dateModifiedCommon
        
        /// Can the user edit this type of field?
        userEditable = false
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return DateTimeValue(toNow: true)
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let dateModified = DateTimeValue(str)
        return dateModified
    }
    
}
