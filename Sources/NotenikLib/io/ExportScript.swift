//
//  ExportScript.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/27/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The name of a script to be used by an export operation. 
public class ExportScript {
    
    public var scriptName = ""
    
    public init(scriptName: String) {
        self.scriptName = scriptName
    }
}
