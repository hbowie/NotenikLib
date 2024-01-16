//
//  MultiFileRequestStack.swift
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

public class MultiFileRequestStack {
    
    var stack: [MultiFileRequest] = []
    
    public var count: Int { return stack.count }
    
    subscript(i: Int) -> MultiFileRequest? { return stack[i] }
    
    init() {
        
    }
    
    func removeFirst() {
        stack.removeFirst()
    }
    
    public func requestPrepForLookup(shortcut: String, collectionPath: String, realm: Realm) {
        let request = MultiFileRequest()
        request.requestType = .prepForLookup
        request.shortcut = shortcut
        request.collectionPath = collectionPath
        request.realm = realm
        stack.append(request)
    }
    
    public func populateLookBacks(io: FileIO) {
        let request = MultiFileRequest()
        request.requestType = .populateLookBacks
        request.io = io
        stack.append(request)
    }
}
