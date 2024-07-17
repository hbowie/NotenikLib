//
//  KlassType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/20/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class KlassType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.klassCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.klass
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.klassCommon
        
        reducedDisplay = false
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return KlassValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let klass = KlassValue(str)
        return klass
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
            return (label.commonForm == commonLabel || label.commonForm == "klass")
        } else if type! == NotenikConstants.pickFromType && label.commonForm == commonLabel {
            return true
        } else {
            return (type! == typeString)
        }
    }
    
    /// Return an appropriate pick list (if any) for this field type.
    /// - Returns: An instance of PickList, or nil.
    override func genPickList() -> PickList? {
        return KlassPickList()
    }
    
}
