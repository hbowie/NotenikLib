//
//  TimeOfDay.swift
//  Notenik Lib
//
//  Created by Herb Bowie on 3/3/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class TimeOfDay {
    
    var hours = 0
    var minutes = 0
    var seconds = 0
    
    public var hh: String {
        return String(format: "%02d", hours)
    }
    
    public var mm: String {
        return String(format: "%02d", minutes)
    }
    
    public var ss: String {
        return String(format:"%02d", seconds)
    }
    
    public var withoutPunctuation: String {
        return hh + mm + ss
    }
    
    public init() {
        
    }
    
    public func setHours(_ hStr: String) {
        if let n = Int(hStr) {
            hours = n
        }
    }
    
    public func setHours(_ hours: Int) {
        self.hours = hours
    }
    
    public func setAmPm(_ amPm: String) {
        let lowered = amPm.lowercased()
        if lowered == "pm" {
            if hours < 12 {
                hours = hours + 12
            }
        } else if lowered == "am" && hours == 12 {
            hours = 0
        }
    }
    
    public func setMinutes(_ mStr: String) {
        if let n = Int(mStr) {
            minutes = n
        }
    }
    
    public func setMinutes(_ minutes: Int) {
        self.minutes = minutes
    }
    
    public func setSeconds(_ sStr: String) {
        if let n = Int(sStr) {
            seconds = n
        }
    }
    
    public func setSeconds(_ seconds: Int) {
        self.seconds = seconds
    }
    
    public func copy() -> TimeOfDay {
        let tod2 = TimeOfDay()
        tod2.setHours(hours)
        tod2.setMinutes(minutes)
        tod2.setSeconds(seconds)
        return tod2
    }
    
    public func add(duration: DurationValue) -> Int {
        self.seconds += duration.seconds
        adjustSeconds()
        self.minutes += duration.minutes
        adjustMinutes()
        self.hours += duration.hours
        return adjustHours()
    }
    
    func adjustSeconds() {
        let oldSeconds = seconds
        seconds = oldSeconds % 60
        minutes += oldSeconds / 60
    }
    
    func adjustMinutes() {
        let oldMinutes = minutes
        minutes = oldMinutes % 60
        hours += oldMinutes / 60
    }
    
    func adjustHours() -> Int {
        let oldHours = hours
        hours = oldHours % 24
        return oldHours / 24
    }
    
    func display() {
        print("TimeOfDay hours = \(hours), minutes = \(minutes), seconds = \(seconds)")
    }
    
}
