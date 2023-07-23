//
//  EmailValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/21/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Holds one email address. 
class EmailValue: StringValue {
    
    /// Return the link value as an optional URL
    var url: URL? {
        if !value.isEmpty {
            if value.starts(with: "mailto:") {
                return URL(string: value)
            } else {
                return URL(string: "mailto:\(value)")
            }
        } else {
            return nil
        }
    }
}
