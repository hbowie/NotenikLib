//
//  AKAEntries.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/12/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class AKAentries {
    
    public var akaDict   = [String : Note]()
    
    public init() {
        
    }
    
    public func getNote(commonID: String) -> Note? {
        return akaDict[commonID]
    }
    
    public func setNote(id: String, note: Note) {
        let commonID = StringUtils.toCommon(id)
        akaDict[commonID] = note
    }
}
