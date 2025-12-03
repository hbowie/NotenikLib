//
//  InclusionsType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 11/30/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class InclusionsType: AnyType {
    
    var initialReveal = false
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.inclusionsCommon
         
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.inclusions
         
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.inclusionsCommon
        
        /// Can the user edit this type of field?
        userEditable = false
    }
     
     /// A factory method to create a new value of this type with no initial value.
     override func createValue() -> StringValue {
         let inclusions = InclusionsValue()
         return inclusions
     }
     
     /// A factory method to create a new value of this type with the given value.
     /// - Parameter str: The value to be used to populate the field with a value.
     override func createValue(_ str: String) -> StringValue {
         let inclusions = InclusionsValue(str)
         return inclusions
     }
     
     /// Is this type suitable for a particular field, given its label and type (if any)?
     /// - Parameter label: The label.
     /// - Parameter type: The type string (if one is available)
     override func appliesTo(label: FieldLabel, type: String?) -> Bool {
         if type == nil || type!.count == 0 {
            return (label.commonForm == commonLabel)
         } else {
            return (type! == typeString)
         }
     }
    
    public func setInitialReveal(str: String) {
        if str.lowercased().starts(with: "rev") {
            initialReveal = true
        }
    }
}
