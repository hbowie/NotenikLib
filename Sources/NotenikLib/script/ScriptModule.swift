//
//  ScriptModule.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An enum identifying the module intended to receive a command. 
public enum ScriptModule: String {
    case blank    = ""
    case comment  = "<!--"
    case module   = "module"
    case script   = "script"
    case input    = "input"
    case filter   = "filter"
    case sort     = "sort"
    case template = "template"
    case output   = "output"
    case sync     = "sync"
    case browse   = "browse"
}
