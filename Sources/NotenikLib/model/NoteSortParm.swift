//
//  NoteSortParm.swift
//  Notenik
//
//  Created by Herb Bowie on 12/27/18.
//  Copyright © 2018 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public enum NoteSortParm: Int {
    case title          = 0
    case seqPlusTitle   = 1
    case tasksByDate    = 2
    case tasksBySeq     = 3
    case author         = 4
    case tagsPlusTitle  = 5
    case tagsPlusSeq    = 6
    case custom         = 7
    case dateAdded      = 8
    case dateModified   = 9
    case datePlusSeq    = 10
    case rankSeqTitle   = 11
    case klassTitle     = 12
    case klassDateTitle = 13
    case lastNameFirst  = 14
    
    // Get or set with a String containing the raw value
    var str: String {
        get {
            return String(self.rawValue)
        }
        set {
            self = .title
            if newValue.count > 0 {
                let sortParmInt = Int(newValue)
                if sortParmInt != nil {
                    let sortParmRaw = sortParmInt!
                    let sortParmWork: NoteSortParm? = NoteSortParm(rawValue: sortParmRaw)
                    if sortParmWork != nil {
                        self = sortParmWork!
                    }
                }
            }
        }
    }
}
