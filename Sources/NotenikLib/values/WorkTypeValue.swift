//
//  WorkTypeValue.swift
//  Notenik
//
//  Created by Herb Bowie on 8/31/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Indicates the type of work produced by a creator. 
public class WorkTypeValue: StringValue {
    
    let types = WorkTypeList.shared
    
    override func set(_ value: String) {
        let index = types.matchesOriginal(value: value)
        if index == NSNotFound {
            self.value = value
        } else {
            self.value = types.originalTypes[index]
        }
    }

}
