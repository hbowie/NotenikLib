//
//  SeqType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/27/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class SeqType: AnyType {
    
    public var seqParms = SeqParms()
    
    override init() {
        
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = "seq"
        
        /// The proper label typically assigned to fields of this type.
        properLabel = "Seq"
        
        /// The common label typically assigned to fields of this type.
        commonLabel = "seq"
    }
    
    /// A factory method to create a new value of this type with no initial value.
    public override func createValue() -> StringValue {
        return SeqValue(seqParms: seqParms)
    }
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    public override func createValue(_ str: String) -> StringValue {
        let seq = SeqValue(str, seqParms: seqParms)
        return seq
    }
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    override func appliesTo(label: FieldLabel, type: String?) -> Bool {
        if type == nil || type!.count == 0 {
           return (label.commonForm == commonLabel
            || label.commonForm == "sequence"
            || label.commonForm == "rev"
            || label.commonForm == "revision"
            || label.commonForm == "version"
            || label.commonForm.starts(with: "seq"))
        } else {
            return (type! == typeString)
        }
    }
}
