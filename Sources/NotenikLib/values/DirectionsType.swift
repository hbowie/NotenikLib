//
//  DirectionsType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/20/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class DirectionsType: AnyType {
    
    override init() {
        
        super.init()
        
         /// A string identifying this particular field type.
        typeString  = NotenikConstants.directionsCommon
         
         /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.directions
         
         /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.directionsCommon
    }
     
     /// A factory method to create a new value of this type with no initial value.
     override func createValue() -> StringValue {
         return DirectionsValue()
     }
     
     /// A factory method to create a new value of this type with the given value.
     /// - Parameter str: The value to be used to populate the field with a value.
     override func createValue(_ str: String) -> StringValue {
         let directions = DirectionsValue(str)
         return directions
     }
     
     /// Is this type suitable for a particular field, given its label and type (if any)?
     /// - Parameter label: The label.
     /// - Parameter type: The type string (if one is available)
     override func appliesTo(label: FieldLabel, type: String?) -> Bool {
         if type == nil || type!.count == 0 {
            return (label.commonForm == commonLabel
                        || label.commonForm == "Navigation"
                        || label.commonForm == "Driving Directions")
         } else {
             return (type! == typeString)
         }
     }
}
