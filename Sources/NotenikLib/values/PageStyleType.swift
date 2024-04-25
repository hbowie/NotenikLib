//
//  PageStyleType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/23/24.
//

import Foundation

public class PageStyleType: AnyType {
    
    public override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.pageStyleCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.pageStyle
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.pageStyleCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    public override func createValue() -> StringValue {
        return PageStyleValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    public override func createValue(_ str: String) -> StringValue {
        let pageStyle = PageStyleValue(str)
        return pageStyle
    }
    
}
