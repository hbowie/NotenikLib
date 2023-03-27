//
//  TextFormatType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/26/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class TextFormatType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.textFormatCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.textFormat
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.textFormatCommon
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.isEmpty {
            return label.commonForm == NotenikConstants.textFormatCommon
        } else {
            return (type! == typeString)
        }
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> TextFormatValue {
        return TextFormatValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> TextFormatValue {
        let format = TextFormatValue(str)
        return format
    }
    
}

