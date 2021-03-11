//
//  ImageNameType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/8/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class ImageNameType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.imageNameCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.imageName
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.imageNameCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return ImageNameValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let imageName = ImageNameValue(str)
        return imageName
    }
    
}
