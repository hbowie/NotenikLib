//
//  MultiFileRequest.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/12/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class MultiFileRequest {
    
    var requestType: MultiRequestType = .undefined
    
    var shortcut = ""
    
    var collectionPath = ""
    
    var realm = Realm()
    
    var io = FileIO()
    
    enum MultiRequestType {
        case undefined
        case populateLookBacks
        case prepForLookup
    }
    
}
