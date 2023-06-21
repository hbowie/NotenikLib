//
//  PickListValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/11/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class PickListValue: StringValue {
    
    public var pickList = PickList()
    
    convenience init(pickList: PickList) {
        self.init()
        self.pickList = pickList
    }
    
    /// Set a new value for the object
    public override func set(_ value: String) {
        let valueLower = value.lowercased()
        var setValue = value
        for value in pickList.values {
            if valueLower == value.value.lowercased() {
                setValue = value.value
                break
            }
        }
        self.value = setValue
    }
}
