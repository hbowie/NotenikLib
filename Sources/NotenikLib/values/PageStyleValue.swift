//
//  PageStyleValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/23/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class PageStyleValue: StringValue {
    
    /// Number of blank lines encountered but not yet added to value
    var pendingBlankLines = 0
    
    /// Append an additional string to this value.
    ///
    /// - Parameter additional: An additional string to be appended to this value
    func append (_ additional : String) {
        addPendingBlankLines()
        value.append(additional)
    }
    
    /// Append the passed text, followed by a new line character.
    ///
    /// - Parameter line: An additonal string of text to be appended.
    func appendLine(_ line : String) {
        if line.count > 0 {
            addPendingBlankLines()
            value.append(line)
            value.append("\n")
        } else if value.count > 0 {
            pendingBlankLines += 1
        }
    }
    
    /// When something non-blank is encountered, add all the pending blank lines.
    func addPendingBlankLines() {
        while pendingBlankLines > 0 {
            value.append("\n")
            pendingBlankLines -= 1
        }
    }
}
