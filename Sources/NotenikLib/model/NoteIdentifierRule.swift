//
//  NoteIdentifierRule.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/10/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public enum NoteIdentifierRule: String, CaseIterable {
    case titleOnly      = "title only"
    case titleBeforeAux = "title before auxiliary field"
    case titleAfterAux  = "title after auxiliary field"
    case auxOnly        = "no title - auxiliary field only"
}
