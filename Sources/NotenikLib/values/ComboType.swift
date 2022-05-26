//
//  ComboType.swift
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

class ComboType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.comboType
        
        /// The proper label typically assigned to fields of this type.
        properLabel = ""
        
        /// The common label typically assigned to fields of this type.
        commonLabel = ""
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> ComboValue {
        return ComboValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let comboValue = ComboValue(str)
        return comboValue
    }
    
    override func genComboList() -> ComboList? {
        return ComboList()
    }
    
}
