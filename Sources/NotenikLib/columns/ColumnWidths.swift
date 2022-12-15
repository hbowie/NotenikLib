//
//  ColumnWidths.swift
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

/// Stores all the column widths for a Collection. 
public class ColumnWidths: CustomStringConvertible {
    
    var columns: [String:ColumnWidth] = [:]
    
    public init() {
        loadDefaults()
    }
    
    public func loadDefaults() {
        add(title: "Title", min: 200, pref: 445, max: 1500)
        add(title: "Rank", min: 50, pref: 80, max: 250)
        add(title: "Klass", min: 60, pref: 80, max: 150)
        add(title: "Seq", min: 30, pref: 80, max: 250)
        add(title: "X", min: 12, pref: 20, max: 50)
        add(title: "status-digit", min: 20, pref: 30, max: 50)
        add(title: "Date", min: 80, pref: 120, max: 500)
        add(title: "Author", min: 100, pref: 200, max: 1000)
        add(title: "Tags", min: 50, pref: 100, max: 1200)
        add(title: "Date Added", min: 100, pref: 180, max: 250)
        add(title: "Date Mod", min: 100, pref: 180, max: 250)
    }
    
    public func set(_ str: String) {
        var title = ""
        var min = 0
        var pref = 0
        var max = 0
        var position = 0
        for char in str {
            if char == ";" {
                if !title.isEmpty && pref > 0 {
                    add(title: title, min: min, pref: pref, max: max)
                }
                title = ""
                min = 0
                pref = 0
                max = 0
                position = 0
            } else if char == ":" {
                position = 1
            } else if char == "," {
                position += 1
            } else if char.isWhitespace {
                // ignore spaces
            } else if position == 0 {
                title.append(char)
            } else if let digit = Int(String(char)) {
                if position == 1 {
                    min = min * 10 + digit
                } else if position == 2 {
                    pref = pref * 10 + digit
                } else if position == 3 {
                    max = max * 10 + digit
                }
            }
        }
    }
    
    public func add(title: String, min: Int, pref: Int, max: Int) {
        let column = ColumnWidth(title: title, min: min, pref: pref, max: max)
        add(column)
    }
    
    public func add(_ column: ColumnWidth) {
        columns[column.title] = column
    }
    
    public var description: String {
        var str = ""
        for (key, column) in columns {
            str.append("\(key): \(column.min), \(column.pref), \(column.max); ")
        }
        return str
    }
    
    public func getColumn(withTitle: String) -> ColumnWidth {
        let col = columns[StringUtils.toCommon(withTitle)]
        if col == nil {
            return ColumnWidth(title: withTitle, min: 50, pref: 150, max: 1000)
        } else {
            return col!
        }
    }
}
