//
//  WikilinkType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/3/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class WikilinkType: AnyType {
    
    var initialReveal = false
    
    override init() {

        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.wikilinksCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.wikilinks
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.wikilinksCommon
        
        /// Can the user edit this type of field?
        userEditable = false
    
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return WikilinkValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let wikilinks = WikilinkValue(str)
        return wikilinks
    }
    
    func setInitialReveal(str: String) {
        if str.lowercased().starts(with: "rev") {
            initialReveal = true
        }
    }
    
}
