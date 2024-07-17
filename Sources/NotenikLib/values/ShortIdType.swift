//
//  ShortIdType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/25/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class ShortIdType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.shortIdCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.shortId
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.shortIdCommon
        
        /// Can the user edit this type of field?
        userEditable = false
        
        reducedDisplay = false
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return ShortIdValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let tags = TagsValue(str)
        return tags
    }
    
}
