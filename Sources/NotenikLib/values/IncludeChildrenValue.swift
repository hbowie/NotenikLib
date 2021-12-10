//
//  IncludeChildrenValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/10/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class IncludeChildrenValue: StringValue {
    
    let values = IncludeChildrenList.shared.values
    
    override func set(_ value: String) {
        let valueToMatch = value.prefix(2).lowercased()
        var i = 0
        var indexForNo = 0
        while i < values.count {
            let valueFromList = values[i].prefix(2).lowercased()
            if valueToMatch == valueFromList {
                break
            } else if valueFromList == "no" {
                indexForNo = i
            }
            i += 1
        }
        if i < values.count {
            self.value = values[i]
        } else {
            self.value = values[indexForNo]
        }
    }
    
}
