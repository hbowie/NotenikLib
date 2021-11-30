//
//  LevelValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/4/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A level (as in heading level, or outline level) field value, in the range of 1 - 6.
public class LevelValue: StringValue {
    
    public var level = 1
    public var label = ""
    
    /// Default initialization
    public override init() {
        super.init()
        value = "1"
    }
        
    /// Convenience initializer using an integer and a configuration.
    public convenience init (i: Int, config: IntWithLabelConfig) {
        self.init()
        set(i: i, config: config)
    }
    
    /// Convenience initializer using a string and a Status Value Config
    public convenience init (str: String, config: IntWithLabelConfig) {
        self.init()
        set(str: str, config: config)
    }
    
    /// Is this value empty?
    public override var isEmpty: Bool {
        return (value.count == 0)
    }
    
    /// Does this value have any data stored in it?
    public override var hasData: Bool {
        return (value.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public override var sortKey: String {
        return value
    }
    
    /// Increment this level to the next valid value.
    public func increment(config: IntWithLabelConfig) {
        var incIndex = 0
        if level < config.high {
            incIndex = level + 1
            while incIndex < config.high && !config.validInt(incIndex) {
                incIndex += 1
            }
            set(i: incIndex, config: config)
        }
    }
    
    /// Set the level using an integer and the passed configuration.
    public func set (i: Int, config: IntWithLabelConfig) {
        if config.validInt(i) {
            self.value = config.intWithLabel(forInt: i)
            self.label = config.label(forInt: i)
            level = i
        }
    }
    
    /// Set the level based on the current label value
    public func set(_ config: IntWithLabelConfig) {
        set (str: value, config: config)
    }
    
    /// Set the level using a string and the passed configuration.
    public func set(str: String, config: IntWithLabelConfig) {
        super.set(str)
        var digitsCount = 0
        for c in str {
            if StringUtils.isDigit(c) {
                digitsCount += 1
            }
        }
        guard digitsCount < 2 else { return }
        var i = config.get(str)
        if i >= 0 {
            level = i
            self.value = config.intWithLabel(forInt: i)
            self.label = config.label(forInt: i)
        } else {
            let trimmed = StringUtils.trim(str)
            if trimmed.count >= 1 {
                let c = StringUtils.charAt(index: 0, str: trimmed)
                if StringUtils.isDigit(c) {
                    i = Int(String(c))!
                    if config.validInt(i) {
                        level = i
                        self.value = config.intWithLabel(forInt: i)
                        self.label = config.label(forInt: i)
                    }
                }
            }
        }
    }
    
    /// Get the integer representation of this status value
    public func getInt() -> Int {
        return level
    }
    
    public func display() {
        print("LevelValue int = \(level), value = \(value)")
    }
    
    static func < (lhs: LevelValue, rhs: LevelValue) -> Bool {
        return lhs.level < rhs.level
    }
    
    static func == (lhs: LevelValue, rhs: LevelValue) -> Bool {
        return lhs.level == rhs.level
    }
    
}
