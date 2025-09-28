//
//  KlassDict.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/28/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class KlassDict: Sequence {
    
    var klassDefs: [KlassDef] = []
    
    public init() {}
    
    public func append(_ def: KlassDef) {
        klassDefs.append(def)
        klassDefs.sort()
    }
    
    public func sort() {
        klassDefs.sort()
    }
    
    public var count: Int {
        return klassDefs.count
    }
    
    public var isEmpty: Bool {
        return klassDefs.isEmpty
    }
    
    public func hasKlass(_ klassName: String?) -> Bool {
        guard let kName = klassName else { return false }
        guard !kName.isEmpty else { return false }
        let kNameLower = kName.lowercased()
        var ix = 0
        while ix < klassDefs.count {
            if klassDefs[ix].name.lowercased() == kNameLower {
                return true
            }
            ix += 1
        }
        return false
    }
    
    public func klassFor(_ klassName: String?) -> KlassDef? {
        guard let kName = klassName else { return nil }
        guard !kName.isEmpty else { return nil }
        let kNameLower = kName.lowercased()
        var ix = 0
        while ix < klassDefs.count {
            if klassDefs[ix].name.lowercased() == kNameLower {
                return klassDefs[ix]
            }
            ix += 1
        }
        return nil
    }
    
    public subscript(index: Int) -> KlassDef {
        get {
            return klassDefs[index]
        }
        set(value) {
            klassDefs[index] = value
        }
    }
    
    public func makeIterator() -> KlassIterator {
        return KlassIterator(klassDict: self)
    }
    
    public class KlassIterator: IteratorProtocol {
        
        public typealias Element = KlassDef
        
        private var klassDict = KlassDict()
        
        private var ix = -1
        
        public init(klassDict: KlassDict) {
            self.klassDict = klassDict
        }
        
        public func next() -> KlassDef? {
            ix += 1
            if ix >= 0 && ix < klassDict.count {
                return klassDict[ix]
            } else {
                return nil
            }
        }
        
        
        
        
        
    }
    
}
