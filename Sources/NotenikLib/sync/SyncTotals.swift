//
//  SyncTotals.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/22/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class SyncTotals {
    
    public var leftAdds = 0
    public var leftMods = 0
    public var leftDels = 0
    public var rightAdds = 0
    public var rightMods = 0
    public var rightDels = 0
    
    public init() {}
    
    public var totalsMsg: String {
        var msg = ""
        msg.append("Additions to left side:      \(leftAdds)\n")
        msg.append("Modifications to left side:  \(leftMods)\n")
        msg.append("Deletions from left side:    \(leftDels)\n")
        msg.append("Additions to right side:     \(rightAdds)\n")
        msg.append("Modifications to right side: \(rightMods)\n")
        msg.append("Deletions from right side:   \(rightDels)")
        return msg
    }
}
