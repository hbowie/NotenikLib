//
//  LookBackFieldDef.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/4/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class LookBackFieldDef: CustomStringConvertible {
    
    var lkUpFieldLabel = ""
    var lkBkCollectionID = ""
    var lkBkFieldLabel = ""
    
    var description: String {
        return "lkUpFieldLabel = \(lkUpFieldLabel), lkBkCollectionID = \(lkBkCollectionID), lkBkFieldLabel = \(lkBkFieldLabel)"
    }
    
    init(lkUpFieldLabel: String) {
        self.lkUpFieldLabel = lkUpFieldLabel
    }
}
