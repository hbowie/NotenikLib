//
//  SyncDirection.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/20/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

public enum SyncDirection {
    case leftToRight
    case rightToLeft
    case bidirectional
    
    var syncRight: Bool {
        return self == .leftToRight || self == .bidirectional
    }
    var syncLeft: Bool {
        return self == .rightToLeft || self == .bidirectional
    }
}
