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
    
    override func set(_ value: String) {
        super.set(value.lowercased())
    }
    
    var frontMatter: Bool {
        switch value {
        case "front", "intro", "preface":
            return true
        default:
            return false
        }
    }
    
}
