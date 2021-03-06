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
    
    public var doneThreshold = 6 
    
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
    var lowIndex: Int {
        var i = 0
        for option in statusOptions {
            if option.count > 0 && option != " "  { return i }
            i += 1
        }
        return 0
    }
    
    /// Get the highest index for this config. This should be the most complete status.
    var highIndex: Int {
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
    
    /// Is this status integer valid?
    func validStatus(_ i : Int) -> Bool {
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
        let i = get(label)
        return getFullString(fromIndex: i)
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
    
    /// Return the corresponding index for the passed label (or partial label),
    /// or -1 if the label is invalid. 
    public func get(_ label: String) -> Int {
        if label.count > 0 {
            let firstChar = StringUtils.charAt(index: 0, str: label)
            var index = 0
            if StringUtils.isDigit(firstChar) {
                index = Int(String(firstChar))!
                let statusOption = statusOptions[index]
                if statusOption.count > 0 {
                    return index
                }
            }
        }
        let lower = label.lowercased()
        var j = 0
        var looking = true
        var alphaLabel = ""
        while j < lower.count {
            let nextChar = StringUtils.charAt(index: j, str: lower)
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
        var i = 0
        while !found && i <= 9 {
            let nextLabel = statusOptions[i]
            found = nextLabel.count > 0 && nextLabel.lowercased().hasPrefix(lower)
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
        print("Display for StatusValueConfig")
        var i = 0
        print("  Done Threshold = \(doneThreshold)")
        print("  Status Values: ")
        while i < 10 {
            print("  \(i). \(statusOptions[i])")
            i += 1
        }
    }

    
}
