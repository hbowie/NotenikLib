//
//  MarkType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/29/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MarkType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.markCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.mark
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.markCommon
        
        reducedDisplay = true
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return MarkValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let marked = MarkValue(str)
        return marked
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.isEmpty {
            if label.commonForm == commonLabel || label.commonForm == "marked" {
                return true
            } else {
                return false
            }
        } else {
            return (type! == typeString || type! == "marked")
        }
    }
    
}
