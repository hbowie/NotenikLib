//
//  DurationValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/3/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A time duration, expressed in hours, minutes and seconds, with colons separating. 
public class DurationValue: StringValue {
    
    var hours   = 0
    var minutes = 0
    var seconds = 0
    
    /// Set an initial value as part of initialization
    public convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Set to String value.
    public override func set(_ value: String) {
        
        self.value = value
        
        let str = value + ":"
        
        hours = 0
        minutes = 0
        seconds = 0
        
        var phase = 0
        var number = 0
        for c in str {
            if c == ":" {
                switch phase {
                case 0:
                    hours = number
                case 1:
                    minutes = number
                case 2:
                    seconds = number
                default:
                    break
                }
                number = 0
                phase += 1
            } else if let n = Int(String(c)) {
                number = (number * 10) + n
            }
        }
    }
    
    public func display() {
        print("Duration: hours = \(hours) minutes = \(minutes) seconds = \(seconds)")
    }
    
}
