//
//  DateTimeValue.swift
//
//  Created by Herb Bowie on 12/23/20.

//  Copyright © 2020 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A String value representing a date and time. This class serves as a wrapper around
/// the standard Swift Date and DateFormatter classes, with some additional
/// parsing tricks up its sleeve..
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
    public override func set(_ value: String) {
        
        if value.isEmpty {
            dateAndTime = Date()
            super.set(ymdhmszFormatter.string(from: dateAndTime))
            return
        }
        
        var possibleDate = ymdhmszFormatter.date(from: value)
        if possibleDate != nil {
            dateAndTime = possibleDate!
            let str = ymdhmszFormatter.string(from: dateAndTime)
            super.set(str)
            return
        }
        
        possibleDate = ymdhmsFormatter.date(from: value)
        if possibleDate != nil {
            dateAndTime = possibleDate!
            super.set(ymdhmszFormatter.string(from: dateAndTime))
            return
        }
        
        setLiberal(value)
        
    }
    
    var yyyy = ""
    var mm = ""
    var dd = ""
    var hours = ""
    var minutes = ""
    var seconds = ""
    var timeZone = ""
    
    var alphaMonth = false
    
    /**
     Set the date's value to a new string, parsing the input and attempting to
     identify the year, month and date
     */
    func setLiberal(_ value: String) {
        
        yyyy = ""
        mm = ""
        dd = ""
        hours = ""
        minutes = ""
        seconds = ""
        timeZone = ""
        alphaMonth = false
        
        let parseContext = ParseContext()
        
        var word = DateWord()
        
        for c in value {
            if word.numbers && c == ":" {
                parseContext.lookingForTime = true
                word.colon = true
                // word.append(c)
                processWord(context: parseContext, word: word)
                word = DateWord()
            } else if StringUtils.isDigit(c) {
                if word.letters {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                } else if word.numbers && word.count == 4 {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                } else if word.numbers && yyyy.count == 4 && word.count == 2 {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                }
                word.numbers = true
                word.append(c)
            } else if StringUtils.isAlpha(c) {
                if word.numbers {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                }
                word.letters = true
                word.append(c)
            } else {
                if word.letters && word.hasData {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                } else if word.numbers && word.hasData {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                    if c == "," && dd.count > 0 {
                        parseContext.lookingForTime = true
                    }
                }
            } // end if c is some miscellaneous punctuation
            
        } // end for c in value
        
        if word.hasData {
            processWord(context: parseContext, word: word)
        }
        
        let dateStr = "\(yyyy)-\(mm)-\(dd) \(hours):\(minutes):\(seconds) \(timeZone)"
        super.set(dateStr)
        if let possibleDate = ymdhmszFormatter.date(from: dateStr) {
            dateAndTime = possibleDate
        }
        
    } // end func set
    
    /**
     Process each parsed word once it's been completed.
     */
    func processWord(context: ParseContext, word: DateWord) {

        if word.letters {
            processWhenLetters(context: context, word: word)
        } else if word.numbers {
            processWhenNumbers(context: context, word: word)
        } else {
            // contains something other than digits or letters?
        }
    }
    
    /**
     Process a word containing letters.
     */
    func processWhenLetters(context: ParseContext, word: DateWord) {
        if context.lookingForTime && timeZone.isEmpty {
            timeZone = word.word
        } else if mm.count > 0 && dd.count > 0 {
            // Don't overlay the first month if a range was supplied
        } else {
            let monthIndex = DateUtils.shared.matchMonthName(word.word)
            if monthIndex > 0 {
                if mm.count > 0 {
                    dd = String(mm)
                }
                mm = String(format: "%02d", monthIndex)
                alphaMonth = true
            }
        }
    }
    
    /**
     Process a word containing digits.
     */
    func processWhenNumbers(context: ParseContext, word: DateWord) {
        let number: Int? = Int(word.word)
        if number == nil {
            // nothing to do
        } else if number! > 1000 {
            yyyy = String(number!)
        } else if context.lookingForTime {
            if hours.isEmpty {
                hours = String(format: "%02d", number!)
            } else if minutes.isEmpty {
                minutes = String(format: "%02d", number!)
            } else if seconds.isEmpty {
                seconds = String(format: "%02d", number!)
            }
        } else if mm.count == 0 && number! >= 1 && number! <= 12 {
            mm = String(format: "%02d", number!)
        } else if dd.count == 0 && number! >= 1 && number! <= 31 {
            dd = String(format: "%02d", number!)
        } else if yyyy.count == 0 {
            if number! > 1900 {
                yyyy = String(number!)
            } else if number! > 9 {
                yyyy = "20" + String(number!)
            } else {
                yyyy = "200" + String(number!)
            }
        } // end if we're just examining a normal number that is part of a date
    } // end of func processWhenNumbers
    
    /// Use the provided format string to format the date.
    ///
    /// - Parameter with: The format string to be used.
    /// - Returns: The formatted date.
    public func format(with: String) -> String {
        let customFormatter = DateFormatter()
        customFormatter.dateFormat = with
        return customFormatter.string(from: dateAndTime)
    }
    
    public var ymdhmsFormat: String {
        return ymdhmsFormatter.string(from: dateAndTime)
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
    public override var sortKey: String {
        return ymdhmszFormatter.string(from: dateAndTime)
    }
    
    /// An inner class containing the parsing context.
    class ParseContext {
        var lookingForTime = false
    }
    
    /// An inner class representing one word parsed from a date string.
    class DateWord {
        var word = ""
        var lower = ""
        var numbers = false
        var letters = false
        var colon = false
        
        init() {
            
        }
        
        func append(_ c: Character) {
            word.append(c)
        }
        
        var isEmpty: Bool {
            return (word.count == 0)
        }
        
        var hasData: Bool {
            return (word.count > 0)
        }
        
        var count: Int {
            return word.count
        }
        
        func lowercased() -> String {
            if word.count > 0 && lower.count == 0 {
                lower = word.lowercased()
            }
            return lower
        }
    }

}
