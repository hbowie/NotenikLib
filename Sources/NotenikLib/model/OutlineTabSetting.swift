//
//  OutlineTabSetting.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/28/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public enum OutlineTabSetting: Int {
    case none = 0
    case withSeq = 1
    case sansSeq = 2
    
    public var isEnabled: Bool {
        return self != .none
    }
    
    public var notEnabled: Bool {
        return self == .none
    }
}
