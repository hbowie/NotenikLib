//
//  NotePosition.swift
//  Notenik
//
//  Created by Herb Bowie on 12/29/18.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An object that defines a particular Note's position within the sorted list
/// containing all Notes in the Collection. 
public class NotePosition {
    
    public var index = 0
    
    /// Is this a valid position pointing to an actual Note?
    public var valid: Bool {
        return index >= 0
    }
    
    /// Is this position that doesn't actually point to a Note?
    public var invalid: Bool {
        return index < 0
    }
    
    /// Default initializer with index = 0.
    public init() {
        
    }
    
    /// Convenience initializer with an index value.
    public convenience init(index: Int) {
        self.init()
        self.index = index
    }
    
    public func display() {
        print("NotePosition at index of \(index)")
    }
}
