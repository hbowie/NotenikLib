//
//  MinutesToReadValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/9/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown

public class MinutesToReadValue: StringValue {
    
    convenience init(with counts: MkdownCounts) {
        self.init()
        calculate(with: counts)
    }
    
    let wordsPerMinute = 200
    
    func calculate(with counts: MkdownCounts) {
        let exactMinutes: Double = Double(counts.words) / Double(wordsPerMinute)
        let rounded: Double = exactMinutes.rounded()
        let roundedInt = Int(rounded)
        set("\(roundedInt)")
    }
    
}
