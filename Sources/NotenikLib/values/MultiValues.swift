//
//  MultiValues.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/15/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

/// A protocol for values that have sub-values that can be independently counted and addressed.
protocol MultiValues {
    
    /// The number of sub-values within this multi-value.
    var multiCount: Int { get }
    
    
    /// Return a sub-value at the given index position.
    /// - Returns: The indicated sub-value, for a valid index, otherwise nil. 
    func multiAt(_ index: Int) -> String?
    
    /// The preferred delimiter to use to separate each sub-value when combining into a String. 
    var multiDelimiter: String { get }
}
