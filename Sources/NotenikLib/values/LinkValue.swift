//
//  LinkValue.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A value represented as some sort of link. 
public class LinkValue: StringValue {
    
    var link = NotenikLink()
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Convenience init with an actual URL object
    convenience init (_ url : URL) {
        self.init()
        set(url)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return link.sortKey
    }
    
    /// Return the link value as an optional URL
    var url: URL? {
        return link.url
    }
    
    /// Set the link value from an actual URL
    func set(_ url : URL) {
        link.set(with: url)
        super.set(link.str)
    }
    
    /// Parse the input string and break it down into its various components
    override func set(_ value: String) {
        super.set(value)
        link.set(with: value, assume: .assumeWeb)
    }
    
    public func display() {
        link.display()
    }
}
