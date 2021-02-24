//
//  NotenikFolderLocation.swift
//
//  Created by Herb Bowie on 8/26/20.
//
//  Copyright © 2020 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The general location of this folder, if known. 
public enum NotenikFolderLocation: Character {
    case appBundle       = "a"
    case iCloudContainer = "u"
    case iCloudDrive     = "c"
    case local           = "l"
    case undetermined    = "x"
}
