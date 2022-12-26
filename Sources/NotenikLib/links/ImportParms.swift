//
//  ImportParms.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/24/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class ImportParms {
    
    public var columnParm: ColumnParm = .ignore
    public var rowParm:    RowParm    = .add
    public var userOkToSettings = false
    public var titleFieldFound = false
    
    public init() {

    }
    
    public var addingFields: Bool {
        return columnParm == .add || columnParm == .replace
    }
    
    public var matching: Bool {
        return rowParm == .matchAndAdd || rowParm == .matchOnly
    }
    
    public enum ColumnParm: String {
        case ignore  = "Ignore"
        case add     = "Add"
        case replace = "Replace"
    }
    
    public enum RowParm: String {
        case add         = "Add"
        case matchAndAdd = "Match and Add"
        case matchOnly   = "Match Only"
    }
}
