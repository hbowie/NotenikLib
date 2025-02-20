//
//  FieldUpdateRule.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/8/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

public enum FieldUpdateRule {
    case always
    case onlyIfExistingBlank
    case ignoreBlankImport
    case onlyIfImportHigher
}
