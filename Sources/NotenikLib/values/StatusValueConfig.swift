//
//  StatusValueConfig.swift
//  Notenik
//
//  Created by Herb Bowie on 12/7/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Information about the meaning of status values in the range of 0 through 9
public class StatusValueConfig {
    
    public var statusOptions : [String] = []
    
    public var freeformValues: [String] = []
    
    public var doneThreshold = 6
    
    // -----------------------------------------------------------
    //
    // MARK: Methods to get and set the options as a whole.
    //
    // -----------------------------------------------------------
    
    init() {
        statusOptions.append("Idea")             // 0
        statusOptions.append("Proposed")         // 1
        statusOptions.append("Approved")         // 2
        statusOptions.append("Planned")          // 3
        statusOptions.append("In Work")          // 4
        statusOptions.append("Held")             // 5
        statusOptions.append("Completed")        // 6
        statusOptions.append("Follow-Up")        // 7
        statusOptions.append("Canceled")         // 8
        statusOptions.append("Closed")           // 9
    }
        
    convenience init (_ options: String) {
        self.init()
        set(options)
    }
    
    /// Get the lowest index for this config. This should be the least complete status. 
    public var lowIndex: Int {
        var i = 0
        for option in statusOptions {
            if option.count > 0 && option != " "  { return i }
            i += 1
        }
        return 0
    }
    
    /// Get the highest index for this config. This should be the most complete status.
    public var highIndex: Int {
        var i = 10
        while i > 0 {
            i -= 1
            let option = statusOptions[i]
            if option.count > 0 && option != " " { return i }
        }
        return 9
    }
    
    
    /// Sets all of the status values from one passed string
    ///
    /// - Parameter options: A string containing a list of digits, each followed by its
    ///                      corresponding label. Punctuation is optional but may be added
    ///                      for readability.
    func set (_ options: String) {
        clear()
        var i = -1
        var label = ""
        for c in options {
            if StringUtils.isDigit(c) {
                set(i: i, label: label)
                label = ""
                i = Int(String(c))!
            } else if StringUtils.isAlpha(c) || StringUtils.isWhitespace(c) {
                label.append(c)
            }
        }
        set(i: i, label: label)
    }
    
    /// Clear all of the status values
    func clear() {
        var i = 0
        while i <= 9 {
            statusOptions[i] = ""
            i += 1
        }
        freeformValues = []
    }
    
    /// Set the label for a given index
    func set (i : Int, label: String) {
        if i >= 0 && i <= 9 {
            statusOptions[i] = StringUtils.trim(label)
        }
    }
    
    var statusOptionsAsString: String {
        var opts = ""
        var i = 0
        for statusOpt in statusOptions {
            if statusOpt.count > 0 && statusOpt != " " {
                opts.append("\(i) - \(statusOpt); ")
            }
            i += 1
        }
        return opts
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Methods to deal with specific status values.
    //
    // -----------------------------------------------------------
    
    func registerValue(_ value: String) {
        let (index, _) = match(value)
        if index >= 0 { return }
        let valueLower = StringUtils.trim(value).lowercased()
        for ff in freeformValues {
            if valueLower == ff { return }
        }
        freeformValues.append(valueLower)
        freeformValues.sort()
    }
    
    /// Is this status integer valid?
    func validStatus(_ i: Int) -> Bool {
        let label = get(i)
        return label.count > 0 && label != " "
    }
    
    /// Is this status label (or partial label) valid?
    func validStatus(_ label: String) -> Bool {
        let i = get(label)
        return i >= 0
    }
    
    /// Return the corresponding label for the passed index, or an
    /// empty string if the index is invalid.
    public func get (_ i: Int) -> String {
        if i < 0 || i > 9 {
            return ""
        } else {
            return statusOptions[i]
        }
    }
    
    /// Format a String starting with the status integer, followed by a hyphen,
    /// followed by the standard label.
    public func getFullString(fromLabel label: String) -> String {
        
        let (i, _) = match(label)
        if i >= 0 {
            return getFullString(fromIndex: i)
        } else {
            return label
        }
    }
    
    /// Format a String starting with the status integer, followed by a hyphen,
    /// followed by the standard label. 
    func getFullString(fromIndex i: Int) -> String {
        if i >= 0 && i <= 9 {
            return String(i) + " - " + statusOptions[i]
        } else {
            return ""
        }
    }
    
    public func normalize(str: String, withDigit: Bool) -> String {
        
        let (index, label) = match(str)
        if withDigit && index >= 0 {
            return String(index) + " - " + label
        } else {
            return label
        }
    }
    
    public func getIndexFor(str: String) -> Int? {
        
        let (index, _) = match(str)
        if index >= 0 {
            return index
        } else {
            return nil
        }
    }
    
    /// Return the corresponding index for the passed label (or partial label),
    /// or -1 if the label is invalid. 
    public func get(_ label: String) -> Int {
        
        let (index, _) = match(label)
        return index
    }
    
    /// Look for a matching status entry, by either a digit or a partial label.
    /// - Parameter str: A status string, possibly starting with a digit.
    /// - Returns: The index pointing to the entry, or -1 if no match; and
    ///            the matching label, or the input string, if no match.
    public func match(_ str: String) -> (Int, String) {
        
        var position: ScanPosition = .beginning
        var alphaLabel = ""
        var pendingSpaces = 0
        for char in str.lowercased() {
            
            if position == .beginning {
                if char.isWhitespace {
                    continue
                } else if let index = char.wholeNumberValue {
                    if index >= 0 && index <= 9 {
                        let statusOption = statusOptions[index]
                        if !statusOption.isEmpty {
                            return (index, statusOption)
                        }
                    }
                }
                position = .seekingAlpha
            }
            
            if position == .seekingAlpha {
                if char.isWhitespace || char.isNumber || char == "-" {
                    continue
                }
                position = .alphaFound
            }
            
            if position == .alphaFound {
                if char.isWhitespace {
                    pendingSpaces += 1
                } else {
                    if pendingSpaces > 0 {
                        alphaLabel.append(" ")
                        pendingSpaces = 0
                    }
                    alphaLabel.append(char)
                }
            }
        }
        
        // Make sure we have an alpha label worth trying to match.
        guard alphaLabel.count > 2 else { return (-1, str) }
        
        // Look for at least a partial match.
        var i = 0
        for nextLabel in statusOptions {
            guard !nextLabel.isEmpty else {
                i += 1
                continue
            }
            if nextLabel.lowercased().hasPrefix(alphaLabel) {
                return (i, nextLabel)
            }
            i += 1
        }
        
        // No match, so return the input string.
        return (-1, str)
    }
    
    func display() {
        print("")
        print("Display for StatusValueConfig")
        var i = 0
        print("  Done Threshold = \(doneThreshold)")
        print("  Status Values: ")
        while i < 10 {
            print("  \(i). \(statusOptions[i])")
            i += 1
        }
    }
    
    enum ScanPosition {
        case beginning
        case seekingAlpha
        case alphaFound
    }
    
}
