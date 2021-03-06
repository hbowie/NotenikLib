//
//  NotePosition.swift
//  Notenik
//
//  Created by Herb Bowie on 12/29/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
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
    init() {
        
    }
    
    /// Convenience initializer with an index value.
    convenience init(index : Int) {
        self.init()
        self.index = index
    }
}
