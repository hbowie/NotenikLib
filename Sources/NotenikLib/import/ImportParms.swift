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

import NotenikUtils

public class ImportParms {
    
    public var format:     ImportFormat = .csv
    public var columnParm: ColumnParm   = .ignore
    public var rowParm:    RowParm      = .add
    public var consolidateLookups = false
    public var userOkToSettings = false
    public var titleFieldFound = false
    public var input = 0
    public var added = 0
    public var modified = 0
    public var ignored = 0
    public var rejected = 0
    
    public init() {

    }
    
    public var addingFields: Bool {
        return columnParm == .add || columnParm == .replace
    }
    
    public var matching: Bool {
        return rowParm == .matchAndAdd || rowParm == .matchOnly
    }
    
    public func logTotals() {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ImportParms", level: .info,
                          message: "\(input) rows/notes were input to the import process")
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ImportParms", level: .info,
                          message: "\(added) rows/notes were added")
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ImportParms", level: .info,
                          message: "\(modified) rows/notes were modified")
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ImportParms", level: .info,
                          message: "\(ignored) rows/notes were ignored based on import parms")
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ImportParms", level: .info,
                          message: "\(rejected) rows/notes were rejected due to problems")
    }
    
    public func display() {
        print("Display ImportParms")
        print("  - Column parm: \(columnParm)")
        print("  - Row parm:    \(rowParm)")
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
