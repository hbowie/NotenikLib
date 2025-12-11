//
//  IOJuggler.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/9/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class IOJuggler {
    
    // Singleton instance
    static let shared = IOJuggler()
    
    var ioNumber = 0
    
    func getNextIoNumber() -> Int {
        ioNumber += 1
        return ioNumber
    }
    
    private init() {
        
    }
}
