//
//  KlassDef.swift
//  NotenikLib
//
//  Created by Herb Bowie on 11/10/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The information that defines a Klass.
public class KlassDef {
    public var name = ""
    public var fieldDefs: [FieldDefinition] = []
    public var defaultValues: Note?
}
