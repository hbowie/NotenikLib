//
//  AuthorType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/26/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).

import Foundation

class AuthorType: AnyType {
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = NotenikConstants.authorCommon
        
        /// The proper label typically assigned to fields of this type.
        properLabel = NotenikConstants.author
        
        /// The common label typically assigned to fields of this type.
        commonLabel = NotenikConstants.authorCommon
    }
    
    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return AuthorValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        let author = AuthorValue(str)
        return author
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
            switch label.commonForm {
            case commonLabel: return true
            case "authors": return true
            case "by": return true
            case "creator": return true
            case "creators": return true
            default: return false
            }
        } else {
            return (type! == typeString)
        }
    }
    
    /// Return an appropriate pick list (if any) for this field type.
    /// - Returns: An instance of PickList, or nil.
    override func genPickList() -> PickList? {
        return AuthorPickList()
    }
    
}
