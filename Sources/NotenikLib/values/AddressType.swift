//
//  AddressType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/19/23.

//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class AddressType: AnyType {
    
    override init() {
        
        super.init()
        
         /// A string identifying this particular field type.
        typeString  = NotenikConstants.addressCommon
         
         /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.address
         
         /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.addressCommon
    }
     
     /// A factory method to create a new value of this type with no initial value.
     override func createValue() -> StringValue {
         return AddressValue()
     }
     
     /// A factory method to create a new value of this type with the given value.
     /// - Parameter str: The value to be used to populate the field with a value.
     override func createValue(_ str: String) -> StringValue {
         let address = AddressValue(str)
         return address
     }
     
     /// Is this type suitable for a particular field, given its label and type (if any)?
     /// - Parameter label: The label.
     /// - Parameter type: The type string (if one is available)
     override func appliesTo(label: FieldLabel, type: String?) -> Bool {
         if type == nil || type!.count == 0 {
            return (label.commonForm == commonLabel
                        || label.commonForm == "Street Address")
         } else {
             return (type! == typeString)
         }
     }
}
