//
//  ImageLayoutType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/6/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class ImageLayoutType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.imageLayoutCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.imageLayout
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.imageLayoutCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return ImageLayoutValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let layout = ImageLayoutValue(str)
        return layout
    }
    
}
