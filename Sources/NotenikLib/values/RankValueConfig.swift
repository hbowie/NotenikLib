//
//  RankValueConfig.swift
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

/// Information about the meaning of rank values.
public class RankValueConfig {
    
    public private(set) var possibleValues: [RankValue] = []
    var padTo = 2
    
    // -----------------------------------------------------------
    //
    // MARK: Methods to get and set the options as a whole.
    //
    // -----------------------------------------------------------
    
    public init() {
        
    }
        
    convenience init (_ options: String) {
        self.init()
        set(options)
    }
    
    /// Sets all of the category values from one passed string
    ///
    /// - Parameter options: A string containing a list of integers,, each followed by its
    ///                      corresponding label. Punctuation is optional but may be added
    ///                      for readability.
    func set (_ options: String) {
        clear()
        var number = 0
        var label = SolidString()
        for c in options {
            if StringUtils.isDigit(c) && !label.isEmpty {
                set(number: number, label: label.str)
                label = SolidString()
                number = Int(String(c))!
            } else if StringUtils.isDigit(c) {
                number = (number * 10) + Int(String(c))!
            } else if StringUtils.isAlpha(c) {
                label.append(c)
            } else if StringUtils.isWhitespace(c) && !label.isEmpty {
                label.append(c)
            }
        }
        set(number: number, label: label.str)
    }
    
    /// Clear all of the status values
    func clear() {
        possibleValues = []
        padTo = 2
    }
    
    /// Set the label for a given number
    func set (number: Int, label: String) {
        guard number >= 0 && !label.isEmpty else { return }
        let numStr = "\(number)"
        if numStr.count > padTo {
            padTo = numStr.count
        }
        var i = 0
        var inserted = false
        let newValue = RankValue(number: number, label: label)
        while i < possibleValues.count && !inserted {
            if number > possibleValues[i].number {
                i += 1
            } else if number == possibleValues[i].count {
                possibleValues[i].label = label
                inserted = true
            } else {
                possibleValues.insert(newValue, at: i)
                inserted = true
            }
        }
        if !inserted {
            possibleValues.append(newValue)
        }
    }
    
    var possibleValuesAsString: String {
        var opts = ""
        for possible in possibleValues {
            if possible.number >= 0 && !possible.label.isEmpty {
                opts.append("\(possible.number) - \(possible.label); ")
            }
        }
        return opts
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Methods to deal with specific status values.
    //
    // -----------------------------------------------------------
    
    public func lookup(str: String) -> (Int, RankValue?) {
        let (numberIn, labelIn) = StringUtils.splitNumberAndLabel(str: str)
        var index = -1
        var value: RankValue? = nil
        if !labelIn.isEmpty {
            (index, value) = lookupByLabel(labelIn)
        }
        if numberIn >= 0 && (index < 0 || value == nil) {
            (index, value) = lookupByNumber(numberIn)
        }
        return (index, value)
    }
    
    public func lookupByNumber(_ number: Int) -> (Int, RankValue?) {
        var i = 0
        for possible in possibleValues {
            if number == possible.number {
                return (i, possible)
            } else {
                i += 1
            }
        }
        return (-1, nil)
    }
    
    public func lookupByLabel(_ label: String) -> (Int, RankValue?) {
        let labelLowered = label.lowercased()
        var i = 0
        for possible in possibleValues {
            if labelLowered == possible.label.lowercased() {
                return (i, possible)
            } else {
                i += 1
            }
        }
        return (-1, nil)
    }
    
    public func combine(number: Int, label: String) -> String {
        guard number > 0 || !label.isEmpty else { return "" }
        var numStr = "\(number)"
        if numStr.count < padTo {
            numStr = StringUtils.truncateOrPad(numStr, toLength: padTo)
        }
        return numStr + " - " + label
    }
    
    public func display() {
        print("RankValueConfig.display")
        for possible in possibleValues {
            possible.display()
        }
    }
    
}
