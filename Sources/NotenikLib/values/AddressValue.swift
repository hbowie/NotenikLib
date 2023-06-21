//
//  AddressValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/19/23.

//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A value for an address thta can be found on a map.
public class AddressValue: StringValue {
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Parse the input string and break it down into its various components
    public override func set(_ value: String) {
        super.set(value)
    }
    
    public var encoded: String {
        return value.replacingOccurrences(of: " ", with: "%20")
    }
    
    public func parameterString(parm: String, first: Bool = true) -> String {
        var sep = "&"
        if first {
            sep = "?"
        }
        return("\(sep)\(parm)=\(encoded)")
    }
    
    public var link: String {
        return "https://maps.apple.com/\(parameterString(parm: "address"))"
    }
    
}
