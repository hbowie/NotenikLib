//
//  AnyType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The requirements that must be fulfilled for any field type class. 
public class AnyType {
    
    /// A string identifying this particular field type.
    public var typeString = ""
    
    /// The proper label typically assigned to fields of this type.
    var properLabel = ""
    
    /// The common label typically assigned to fields of this type.
    var commonLabel = ""
    
    /// Can the user edit this type of field?
    public var userEditable = true
    
    public var displayLines = 2
    
    // Display this field type for streamline reading (and similar display modes)?
    public var reducedDisplay = true
    
    init() {
        
    }
    
    /// A factory method to create a new value of this type with no initial value.
    public func createValue() -> StringValue {
        return StringValue()
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    public func createValue(_ str: String) -> StringValue {
        return StringValue(str)
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
            return commonLabel.count > 0 && label.commonForm == commonLabel
        } else {
            return type! == typeString
        }
    }
    
    // Is this field type a text block?
    public var isTextBlock: Bool {
        return (typeString == NotenikConstants.longTextType ||
                typeString == NotenikConstants.bodyCommon ||
                typeString == NotenikConstants.codeCommon ||
                typeString == NotenikConstants.teaserCommon ||
                typeString == NotenikConstants.pageStyleCommon)
    }
    
    var isBody: Bool {
        return (typeString == NotenikConstants.bodyCommon)
    }
    
    /// Return the value to use between the original value of an ID field and
    /// the appended increment used for uniqueness. 
    var idIncSep: String {
        return " "
    }
    
    /// Return an appropriate pick list (if any) for this field type.
    /// - Returns: An instance of PickList, or nil. 
    func genPickList() -> PickList? {
        return nil
    }
    
    func genComboList() -> ComboList? {
        return nil
    }
    
}
