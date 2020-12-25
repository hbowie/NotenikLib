//
//  DateTimeValue.swift
//
//  Created by Herb Bowie on 12/23/20.

//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A String value representing a date and time. This class serves as a wrapper around
/// the standard Swift Date and DateFormatter classes.
public class DateTimeValue: StringValue {
    
    var dateAndTime = Date()
    var formatter = DateFormatter()
    var ymdhmszFormatter = DateFormatter()
    var ymdhmsFormatter = DateFormatter()
    
    /// Default initialization
    public override init() {
        super.init()
        ymdhmszFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss xxxx"
        ymdhmsFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        super.set(ymdhmszFormatter.string(from: dateAndTime))
    }
    
    /// Set an initial value as part of initialization
    public convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Set to current date and time.
    public func setToNow() {
        dateAndTime = Date()
        super.set(ymdhmszFormatter.string(from: dateAndTime))
    }
    
    /// Set to String value.
    override func set(_ value: String) {
        var possibleDate = ymdhmszFormatter.date(from: value)
        if possibleDate != nil {
            dateAndTime = possibleDate!
            super.set(ymdhmszFormatter.string(from: dateAndTime))
            return
        }
        
        possibleDate = ymdhmsFormatter.date(from: value)
        if possibleDate != nil {
            dateAndTime = possibleDate!
            super.set(ymdhmszFormatter.string(from: dateAndTime))
            return
        }
        
        let dateValue = DateValue(value)
        possibleDate = dateValue.date
        if possibleDate != nil {
            dateAndTime = possibleDate!
            super.set(ymdhmszFormatter.string(from: dateAndTime))
            return
        }
        
        dateAndTime = Date()
        super.set(value)
        
    }
    
    /// Use the provided format string to format the date.
    ///
    /// - Parameter with: The format string to be used.
    /// - Returns: The formatted date.
    public func format(with: String) -> String {
        let customFormatter = DateFormatter()
        customFormatter.dateFormat = with
        return customFormatter.string(from: dateAndTime)
    }
    
    /// See if two of these objects have equal keys
    static func == (lhs: DateTimeValue, rhs: DateTimeValue) -> Bool {
        return lhs.dateAndTime == rhs.dateAndTime
    }
    
    /// See which of these objects should come before the other in a sorted list
    static func < (lhs: DateTimeValue, rhs: DateTimeValue) -> Bool {
        return lhs.dateAndTime < rhs.dateAndTime
    }
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return ymdhmszFormatter.string(from: dateAndTime)
    }

}
