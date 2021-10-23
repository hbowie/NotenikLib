//
//  KlassValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/20/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class KlassValue: StringValue {
    
    let klassList = KlassList.shared
    
    override func set(_ value: String) {
        let index = klassList.matches(value: value)
        if index != NSNotFound {
            self.value = klassList.list[index]
            return
        }
        let closeMatch = klassList.startsWith(prefix: value)
        if closeMatch != nil {
            self.value = closeMatch!
            return
        }
        self.value = value
    }
    
}
