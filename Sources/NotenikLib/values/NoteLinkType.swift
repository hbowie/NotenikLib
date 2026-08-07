//
//  NoteLinkType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/30/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class NoteLinkType: AnyType {
    
    var klassSelector = ""
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.noteLinkCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.noteLink
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.noteLinkCommon
        
        // Display this field type for streamline reading (and similar display modes)?
        reducedDisplay = true
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
            return (label.commonForm == commonLabel)
        } else {
            return (type! == typeString)
        }
    }
    
    /// A factory method to create a new value of this type with no initial value.
    public override func createValue() -> StringValue {
        return NoteLinkValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    public override func createValue(_ str: String) -> StringValue {
        let noteLink = NoteLinkValue(str)
        return noteLink
    }
    
    public func setKlassSelector(_ str: String) {
        self.klassSelector = str
    }
    
    public func hasKlassSelector() -> Bool {
        return !klassSelector.isEmpty
    }
    
    public func getKlassSelector() -> String {
        return klassSelector
    }
}
