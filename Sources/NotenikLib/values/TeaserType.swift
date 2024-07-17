//
//  TeaserType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/26/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class TeaserType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.teaserCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.teaser
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.teaserCommon
        
        reducedDisplay = false
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
            return label.commonForm == NotenikConstants.teaserCommon || label.commonForm == "preview" || label.commonForm == "summary"
        } else {
            return (type! == typeString)
        }
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> TeaserValue {
        return TeaserValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> TeaserValue {
        let teaser = TeaserValue(str)
        return teaser
    }
    
}
