//
//  ColumnWidth.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/14/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Stores the width parameters for a table column. 
public class ColumnWidth {
    
    public var title = ""
    public var min   = 0
    public var pref  = 0
    public var max   = 0
    
    public init(title: String, min: Int, pref: Int, max: Int) {
        self.title = StringUtils.toCommon(title)
        self.min = min
        self.pref = pref
        self.max = max
    }
    
    public func display() {
        print("ColumnWidth title = \(title), min = \(min), pref = \(pref), max = \(max)")
    }
}
