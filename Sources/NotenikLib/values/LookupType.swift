//
//  LookupType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 8/18/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class LookupType: AnyType {
    
    override init() {
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.lookupType
        
        /// The proper label typically assigned to fields of this type.
        properLabel = ""
        
        /// The common label typically assigned to fields of this type.
        commonLabel = ""
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return LookupValue()
    }
    
    func createValue(pickList: PickList) -> StringValue {
        return PickListValue(pickList: pickList)
    }
    
}
