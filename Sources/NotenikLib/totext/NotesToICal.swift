//
//  NotesToICal.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/26/24.
//

import Foundation

import NotenikUtils

public class NotesToICal: NotesToText {
    
    /// Provide the usual file extension for this sort of text output.
    public var usualFileExtension: String {
        get { return "ics"}
    }
    
    var writer: LineWriter!
    
    var io: NotenikIO?
    
    public required init(writer: LineWriter) {
        self.writer = writer
    }
    
    public convenience init(writer: LineWriter, io: NotenikIO) {
        self.init(writer: writer)
        self.io = io
    }
    
    public func start() {
        writer.writeLine("BEGIN:VCALENDAR")
        writer.writeLine("VERSION:2.0")
        writer.writeLine("PRODID:-//Herb Bowie/Notenik for Mac//EN")
        writer.writeLine("CALSCALE:GREGORIAN")
    }
    
    public func finish() {
        writer.writeLine("END:VCALENDAR")
    }
    
    /// Write one note to text.
    /// - Parameter note: The note to be written.
    /// - Returns: +1 if note was written, -1 if a failure, zero if not written due to user wishes.
    public func oneNoteToText(note: Note) -> Int {
    
        // Let's see if we have what appears to be a good date
        guard let dateField = note.getDateAsField() else { return 0 }
        guard let dateValue = dateField.value as? DateValue else { return 0 }
        guard dateValue.isFullDate else { return 0 }
        guard let externalID = io?.collection?.externalID else { return 0 }
        
        // Begin the event
        writer.writeLine("BEGIN:VEVENT")
        
        // Identify the event
        fold("UID:\(externalID)-\(note.noteID.commonFileName)")
        
        // Identify date and time of last update
        var dtStamp = ""
        for c in note.envModDate {
            if c.isNumber && dtStamp.count < 15 {
                dtStamp.append(c)
                if dtStamp.count == 8 {
                    dtStamp.append("T")
                }
            }
        }
        dtStamp.append("Z")
        writer.writeLine("DTSTAMP:\(dtStamp)")
        
        // Provide the event summary (aka title)
        fold("SUMMARY:\(note.title.value)")

        // Indicate Start and End Date(s) and Time(s)
        let date = dateValue.yyyy + dateValue.mm + dateValue.dd
        
        var time = getTimeFromSeq(note: note)
        if time == nil {
            time = getTimeFromDate(dateValue: dateValue)
        }
        
        if time == nil {
            writer.writeLine("DTSTART;VALUE=DATE:\(date)")
            writer.writeLine("DTEND;VALUE=DATE:\(date)")
        } else {
            writer.writeLine("DTSTART:\(date)T\(time!.withoutPunctuation)")
            var duration = DurationValue("00:15:00")
            if note.hasDuration() {
                duration = note.duration
            }
            let endTime = time!.copy()
            _ = endTime.add(duration: duration)
            writer.writeLine("DTEND:\(date)T\(endTime.withoutPunctuation)")
        }
        
        if note.hasAddress() {
            fold("LOCATION:\(note.address.value)")
        }
        
        var desc = ""
        if let supplierField = note.getField(label: "supplier") {
            desc.append("Supplier: \(supplierField.value.value)\n\n")
        }
        if let confirmationField = note.getField(label: "confirmation") {
            desc.append("Confirmation: \(confirmationField.value.value)\n\n")
        }
        desc.append(note.body.value)
        
        if !desc.isEmpty {
            fold("DESCRIPTION:\(desc)")
        }
        if note.hasLink() {
            fold("URL:\(note.link.value)")
        }
            
        writer.writeLine("END:VEVENT")
        return 1
        
    }
    
    var out = ""
    var word = ""
    
    func fold(_ str: String) {
        out = ""
        word = ""
        for c in str {
            switch c {
            case "\n":
                checkWordLimit(plus: 2)
                word.append("\\n")
            case ",":
                checkWordLimit(plus: 2)
                word.append("\\,")
            case " ":
                checkWordLimit(plus: 1)
                endWordWithSpace()
            default:
                checkWordLimit(plus: 1)
                word.append(c)
            }
        }
        endWord()
        writeOut()
    }
    
    func checkWordLimit(plus: Int) {
        if word.count + plus > 74 {
            if !out.isEmpty {
                writeOut()
                writer.write(" ")
            }
            out = word
            writeOut()
            writer.write(" ")
            word = ""
        }
    }
    
    func endWordWithSpace() {
        word.append(" ")
        endWord()
    }
    
    func endWord() {
        guard !word.isEmpty else { return }
        if out.count + word.count > 74 {
            writeOut()
            writer.write(" ")
            out = word
        } else {
            out.append(word)
        }
        word = ""
    }
    
    func writeOut() {
        guard !out.isEmpty else { return }
        writer.writeLine(out)
    }
    
    func getTimeFromDate(dateValue: DateValue) -> TimeOfDay? {
        let timeOfDay = TimeOfDay()
        guard dateValue.hours.count == 2 else { return nil }
        timeOfDay.setHours(dateValue.hours)
        if dateValue.ampm.count == 2 {
            timeOfDay.setAmPm(dateValue.ampm)
        }
        if dateValue.minutes.count == 2 {
            timeOfDay.setMinutes(dateValue.minutes)
        } 
        if dateValue.seconds.count == 2 {
            timeOfDay.setSeconds(dateValue.seconds)
        }
        return timeOfDay
    }
    
    func getTimeFromSeq(note: Note) -> TimeOfDay? {
        guard let seqField = note.getSeqAsField() else { return nil }
        guard let seqValue = seqField.value as? SeqValue else { return nil }
        guard let seqStack = seqValue.seqStack else { return nil }
        guard seqStack.possibleTimeStack else { return nil }
        
        let timeOfDay = TimeOfDay()
        
        // Set hours
        timeOfDay.setHours(seqStack.hours)
        
        // Add minutes within hour
        if seqStack.count > 1 {
            let minutesSegment = seqStack.segments[1]
            if minutesSegment.digits && minutesSegment.possibleTimeSegment && minutesSegment.numberType == .digits {
                if let minutes = Int(minutesSegment.value) {
                    if minutes >= 0 && minutes < 60 {
                        timeOfDay.setMinutes(minutes)
                    }
                }
            }
        }
        
        // Add seconds within minute
        if seqStack.count > 2 {
            let secondsSegment = seqStack.segments[2]
            if secondsSegment.digits && secondsSegment.possibleTimeSegment && secondsSegment.numberType == .digits {
                if let seconds = Int(secondsSegment.value) {
                    if seconds >= 0 && seconds < 60 {
                        timeOfDay.setSeconds(seconds)
                    }
                }
            }
        }
        
        return timeOfDay
    }
    
}
