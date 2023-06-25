//
//  DirectionsValue.swift
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
public class DirectionsValue: StringValue {
    
    let pop = PopConverter.shared
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    public func set(source: AddressValue?, destination: AddressValue?) {
        clear()
        guard let dest = destination else { return }
        var first = true
        if let start = source {
            value = start.parameterString(parm: "saddr", first: first)
            first = false
        }
        value.append(dest.parameterString(parm: "daddr", first: first))
    }
    
    public var link: String {
        guard !value.isEmpty else { return "" }
        guard !directionsRequested else { return "" }
        let urlStr = "https://maps.apple.com/\(value)"
        let encoded = pop.toURL(urlStr)
        return encoded
    }
    
    public override func valueToDisplay() -> String {
        var display = ""
        var parmString = value
        if value.hasPrefix("?") {
            parmString.removeFirst()
        }
        let components = parmString.components(separatedBy: CharacterSet(charactersIn: "&"))
        for component in components {
            if !display.isEmpty {
                display.append("; ")
            }
            let parms = component.components(separatedBy: CharacterSet(charactersIn: "="))
            var parmIx = 0
            for parm in parms {
                switch parmIx {
                case 0:
                    if parm == "saddr" {
                        display.append("from ")
                    } else if parm == "daddr" {
                        display.append("to ")
                    } else {
                        display.append("\(parm) = ")
                    }
                case 1:
                    let unencoded = parm.replacingOccurrences(of: "%20", with: " ")
                    display.append(pop.toXML(unencoded))
                default:
                    break
                }
                parmIx += 1
            }
        }
        return display
    }
    
    public var directionsRequested: Bool {
        return value == NotenikConstants.directionsRequested
    }
    
}
