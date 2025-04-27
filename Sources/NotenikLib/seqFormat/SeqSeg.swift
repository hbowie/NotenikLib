//
//  SeqSeg.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/25/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class SeqSeg {
    var val = ""
    var type: SeqCharType = .whitespace
    
    init() {}
    
    init(_ c: Character) {
        val = String(c)
        type = determineCharType(c)
    }
    
    func fits(_ c: Character) -> Bool {
        guard !val.isEmpty else {
            return true
        }
        let newType = determineCharType(c)
        return newType == type
    }
    
    func append(_ c: Character) {
        val.append(c)
        type = determineCharType(c)
    }
    
    func determineCharType(_ c: Character) -> SeqCharType {
        if c.isWhitespace {
            return .whitespace
        } else if c.isLetter {
            return .alpha
        } else if c.isNumber {
            return .numeric
        } else {
            return .punctuation
        }
    }
}
