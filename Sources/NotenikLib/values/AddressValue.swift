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
    
    let pop = PopConverter.shared
    
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
        super.set(pop.removePercentTwenty(value))
    }
    
    public func parameterString(parm: String, first: Bool = true) -> String {
        var sep = "&"
        if first {
            sep = "?"
        }
        return("\(sep)\(parm)=\(value)")
    }
    
    public var link: String {
        let parmString = parameterString(parm: "address")
        let urlStr = "https://maps.apple.com/\(parmString)"
        let encoded = pop.toURL(urlStr)
        return encoded
    }
    
    public override func valueToDisplay() -> String {
        return pop.toXML(value)
    }
    
}
