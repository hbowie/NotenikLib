//
//  AKAType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/8/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class AKAType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.akaCommon
    
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.aka
    
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.akaCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return AKAValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let aka = AKAValue()
        aka.set(str)
        return aka
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
            switch label.commonForm {
            case commonLabel: return true
            case "alsoknownas": return true
            case "alias": return true
            case "aliases": return true
            default: return false
            }
        } else {
            return (type! == typeString)
        }
    }
    
}
