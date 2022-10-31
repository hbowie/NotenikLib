//
//  RankValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/22/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A representation of an item's category, using both a string label and an integer value.
public class RankValue: StringValue {
    
    public internal(set) var number = 0
    public internal(set) var label = ""
    public internal(set) var labelLowered = ""
    
    /// Initialize with no initial value
    public override init() {
        super.init()
    }
    
    public convenience init(number: Int, label: String) {
        self.init()
        self.number = number
        self.label = label
        labelLowered = label.lowercased()
        if number <= 0 && label.isEmpty {
            value = ""
        } else {
            value = "\(number) - \(label)"
        }
    }
    
    public convenience init(number: Int, label: String, config: RankValueConfig) {
        self.init()
        self.number = number
        self.label = label
        labelLowered = label.lowercased()
        value = config.combine(number: number, label: label)
    }
    
    /// Convenience initializer using an integer and a Category Value Config
    convenience init (number: Int, config: RankValueConfig) {
        self.init()
        set(number: number, config: config)
    }
    
    /// Convenience initializer using a string and a Status Value Config
    convenience init (str: String, config: RankValueConfig) {
        self.init()
        set(str: str, config: config)
    }
    
    /// Set the status using an integer and the passed Rank Value Config
    func set (number: Int, config: RankValueConfig) {
        let (_, possible) = config.lookupByNumber(number)
        if possible != nil {
            self.number = possible!.number
            self.label = possible!.label
            self.value = config.combine(number: number, label: possible!.label)
        } else {
            self.number = number
            self.label = "???"
        }
        labelLowered = label.lowercased()
    }
    
    /// Set the rank using a string and the passed  Value Configuration.
    func set(str: String, config: RankValueConfig) {
        let (_, possible) = config.lookup(str: str)
        if possible != nil {
            self.number = possible!.number
            self.label = possible!.label
            self.value = config.combine(number: possible!.number, label: possible!.label)
        } else {
            let (number, label) = RankValue.extractNumberAndLabel(str: str)
            if number <= 0 && label.isEmpty {
                self.number = 0
                self.label = ""
                self.value = ""
            } else {
                self.number = number
                self.label = label
                self.value = config.combine(number: number, label: label)
            }
        } 
        labelLowered = label.lowercased()
    }
    
    public func get(config: RankValueConfig) -> String {
        return config.combine(number: number, label: label)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public func getSortKey(config: RankValueConfig) -> String {
        return config.combine(number: number, label: label)
    }
    
    public func display() {
        print("  - Rank Value - number: \(number), label: \(label)")
    }
    
    public static func extractNumberAndLabel(str: String) -> (Int, String) {
        var number = 0
        var label = ""
        for c in str {
            if StringUtils.isDigit(c) {
                number = (number * 10) + Int(String(c))!
            } else if StringUtils.isAlpha(c) {
                label.append(c)
            } else if StringUtils.isWhitespace(c) && !label.isEmpty {
                label.append(" ")
            }
        }
        return (number, label)
    }
    
}
