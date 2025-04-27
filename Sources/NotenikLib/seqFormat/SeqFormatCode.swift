//
//  SeqFormatCode.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/24/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class SeqFormatCode {
    
    var code: Character = " "
    var codeLowered: Character = " "
    var placeholder: Bool = false
    var literal: Bool = false
    var blank: Bool = false
    
    init(code: Character) {
        self.code = code
        self.codeLowered = code.lowercased().first!
        switch codeLowered {
        case "n", "i", "a", "?":
            placeholder = true
        case " ":
            blank = true
        default:
            literal = true
        }
    }
}
