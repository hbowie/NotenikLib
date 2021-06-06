//
//  IntWithLabelConfig.swift
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

/// Configuration information for a field that can have both an integer and character values.
public class IntWithLabelConfig {
    
    public var low = 0
    
    public var high = 9
    
    public var defaultLabels: [String] = []
    
    public var labels: [String] = []
    
    init() {
        clear()
    }
        
    convenience init (_ options: String) {
        self.init()
        set(options)
    }
    
    /// Sets all of the status values from one passed string
    ///
    /// - Parameter options: A string containing a list of digits, each followed by its
    ///                      corresponding label. Punctuation is optional but may be added
    ///                      for readability.
    func set (_ options: String) {
        clear()
        var firstInt = true
        var i = -1
        var label = ""
        for c in options {
            if StringUtils.isDigit(c) {
                set(i: i, label: label, firstInt: &firstInt)
                label = ""
                i = Int(String(c))!
            } else if StringUtils.isAlpha(c) || StringUtils.isWhitespace(c) {
                label.append(c)
            }
        }
        set(i: i, label: label, firstInt: &firstInt)
    }
    
    /// Clear all of the status values
    func clear() {
        labels = []
        while labels.count < 10 {
            labels.append("")
        }
    }
    
    /// Set the label for a given index
    func set (i: Int, label: String, firstInt: inout Bool) {
        if i >= 0 && i <= 9 {
            labels[i] = StringUtils.trim(label)
            if firstInt {
                low = i
                firstInt = false
            }
            high = i
        }
    }
    
    var intsWithLabels: String {
        var str = ""
        var i = low
        while i <= high {
            let label = labels[i]
            if label.count > 0 && label != " " {
                str.append("\(intWithLabel(forInt: i)); ")
            }
            i += 1
        }
        return str
    }
    
    /// Is this status integer valid?
    func validInt(_ i: Int) -> Bool {
        guard i >= low && i <= high else { return false }
        let label = label(forInt: i)
        return label.count > 0 && label != " "
    }
    
    /// Is this status label (or partial label) valid?
    func validLabel(_ label: String) -> Bool {
        let i = get(label)
        return i >= 0
    }
    
    /// Return the corresponding label for the passed index, or an
    /// empty string if the index is invalid.
    public func label(forInt i: Int) -> String {
        guard i >= low && i <= high else { return "" }
        return labels[i]
    }
    
    /// Format a String starting with the status integer, followed by a hyphen,
    /// followed by the standard label.
    public func intWithLabel(forLabel label: String) -> String {
        let i = get(label)
        return intWithLabel(forInt: i)
    }
    
    /// Format a String starting with the status integer, followed by a hyphen,
    /// followed by the standard label.
    func intWithLabel(forInt i: Int) -> String {
        guard i >= low && i <= high else { return "" }
        return("\(i) - \(labels[i])")
    }
    
    /// Return the corresponding index for the passed label (or partial label),
    /// or -1 if the label is invalid.
    public func get(_ label: String) -> Int {
        if label.count > 0 {
            let firstChar = StringUtils.charAt(index: 0, str: label)
            var index = 0
            if StringUtils.isDigit(firstChar) {
                index = Int(String(firstChar))!
                let label = labels[index]
                if label.count > 0 {
                    return index
                }
            }
        }
        let lowerLabel = label.lowercased()
        var j = 0
        var looking = true
        var alphaLabel = ""
        while j < lowerLabel.count {
            let nextChar = StringUtils.charAt(index: j, str: lowerLabel)
            if StringUtils.isDigit(nextChar) || nextChar == " " || nextChar == "-" {
                // Keep looking
            } else {
                looking = false
            }
            if !looking {
                alphaLabel.append(nextChar)
            }
            j += 1
        }
        var found = false
        var i = low
        while !found && i <= high {
            let nextLabel = labels[i]
            found = nextLabel.count > 0 && nextLabel.lowercased().hasPrefix(lowerLabel)
            if !found {
                i += 1
            }
        }
        if found {
            return i
        } else {
            return -1
        }
    }
    
    func display() {
        print("")
        print("Display for IntWithLabelConfig")
        var i = low
        while i <= high {
            print("  \(intWithLabel(forInt: i))")
            i += 1
        }
    }
    
}
