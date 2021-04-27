//
//  MicroBlogIntegrator.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/27/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class MicroBlogIntegrator {
    
    var ui:   MicroBlogUI
    var info: MicroBlogInfo
    
    /// Initialize with a caller and in info object.
    public init(ui: MicroBlogUI, info: MicroBlogInfo) {
        self.ui = ui
        self.info = info
    }
    
}
