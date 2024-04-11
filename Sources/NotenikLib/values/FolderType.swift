//
//  FolderType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/1/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class FolderType: AnyType {
    
    public override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.folderCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.folder
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.folderCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    public override func createValue() -> StringValue {
        return FolderValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    public override func createValue(_ str: String) -> StringValue {
        let folder = FolderValue(str)
        return folder
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
            return (label.commonForm == commonLabel || label.commonForm == "subfolder")
        } else {
            return (type! == typeString)
        }
    }
    
    override func genComboList() -> ComboList? {
        return ComboList()
    }
    
}
