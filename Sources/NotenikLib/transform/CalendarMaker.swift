//
//  CalendarMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 1/19/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Format Notes into a traditional Calendar layout, expressed in HTML. 
public class CalendarMaker {
    
    var writer: Markedup
    
    var lowYM = ""
    var highYM = ""
    
    var currDate: SimpleDate?
    
    var dayStarted = false
    var weekStarted = false
    var monthStarted = false
    
    let firstWeekday = Calendar.current.firstWeekday
    
    public init(format: MarkedupFormat, lowYM: String, highYM: String) {
        self.lowYM = lowYM
        self.highYM = highYM
        writer = Markedup(format: format)
    }
    
    public func startCalendar(title: String, prefs: DisplayPrefs) {
        
        writer.startDoc(withTitle: title,
                          withCSS: prefs.displayCSS,
                          linkToFile: false,
                          withJS: nil)
        currDate = nil
    }
    
    public func finishCalendar() -> String {
        
        if currDate != nil {
            finishMonth()
        }
        writer.finishDoc()
        return writer.code
    }
    
    /// Process the next Note.
    /// - Parameter note: The note to be processed.
    /// - Returns: True when we've passed the last month to be included.
    public func nextNote(_ note: Note, link: String? = nil) -> Bool {
        
        guard let date = note.date.simpleDate else { return false }
        let ym = date.yearAndMonth
        
        guard ym >= lowYM || lowYM.isEmpty else { return false }
        guard ym <= highYM || highYM.isEmpty else { return true }
        
        positionToDate(date)
        
        if note.hasSeq() {
            writer.append("\(note.seq) ")
        }
        var noteLink = ""
        if link != nil {
            noteLink = link!
        } else {
            var notenikLink = "notenik://open?"
            let folderURL = URL(fileURLWithPath: note.collection.fullPath)
            let encodedPath = String(folderURL.absoluteString.dropFirst(7))
            notenikLink.append("path=\(encodedPath)")
            notenikLink.append("&id=\(note.id)")
            noteLink = notenikLink
        }
        writer.link(text: note.title.value, path: noteLink)
        writer.lineBreak()
        
        return false
    }
    
    /// Make sure we've generated weeks and days preceding this date, and then start this day.
    func positionToDate(_ date: SimpleDate) {
        
        if currDate == nil {
            startMonth(for: date)
        }
        
        while currDate! < date {
            finishDayCode()
            let nextDate = currDate!.copy()
            nextDate.addDays(1)
            startDay(for: nextDate)
        }
    }
    
    func startDay(for date: SimpleDate) {
        
        if currDate != nil && date.yearAndMonth > currDate!.yearAndMonth {
            finishMonth()
        }
        
        if !monthStarted {
            startMonth(for: date)
        }
        
        if currDate != nil && date.calendarColumn < currDate!.calendarColumn {
            finishWeekCode()
        }
        
        if !weekStarted {
            startWeekCode()
        }
        
        if currDate != nil && currDate! < date {
            startDayCode(for: date)
        }
    }
    

    
    func startMonth(for date: SimpleDate) {
        
        writer.startTable(klass: "notenik-calendar")
        
        writer.startTableRow()
        writer.startTableHeader(klass: "notenik-calendar-name-of-month", colspan: 7)
        writer.writeLine("\(date.monthName), \(date.year)")
        writer.finishTableHeader()
        writer.finishTableRow()
        
        writer.startTableRow()
        for columnIndex in 0...6 {
            writer.startTableHeader(klass: "notenik-calendar-name-of-day")
            writer.writeLine(DateUtils.shared.dayOfWeekName(for: columnIndex))
            writer.finishTableHeader()
        }
        writer.finishTableRow()
        
        monthStarted = true
        
        startWeekCode()
        
        let firstDayOfMonth = date.copy()
        firstDayOfMonth.setDayOfMonth(01)
        let firstDayOfMonthCalendarColumn = firstDayOfMonth.calendarColumn
        if firstDayOfMonthCalendarColumn > 0 {
            writer.startTableData(klass: "notenik-calendar-filler", colspan: firstDayOfMonthCalendarColumn)
            writer.writeNonBreakingSpace()
            writer.finishTableData()
        }
        
        startDayCode(for: firstDayOfMonth)
        
    }
        
    func finishMonth() {
        guard monthStarted else { return }
        
        let nextDate = currDate!.copy()
        while nextDate.day < currDate!.daysInMonth {
            finishDayCode()
            nextDate.addDays(1)
            startDay(for: nextDate)
        }
        finishDayCode()
        
        if currDate!.calendarColumn < 6 {
            writer.startTableData(klass: "notenik-calendar-filler", colspan: 6 - currDate!.calendarColumn)
            writer.writeNonBreakingSpace()
            writer.finishTableData()
        }
        finishWeekCode()
        writer.finishTable()
        monthStarted = false
    }
    
    func startWeekCode() {
        writer.startTableRow()
        weekStarted = true
    }
    
    func finishWeekCode() {
        guard weekStarted else { return }
        writer.finishTableRow()
        weekStarted = false
    }
    
    func startDayCode(for date: SimpleDate) {
        guard !dayStarted else { return }
        writer.startTableData(klass: "notenik-calendar-day-data")
        writer.startParagraph(klass: "notenik-calendar-day-of-month")
        writer.writeLine("\(date.day)")
        writer.finishParagraph()
        writer.startParagraph(klass: "notenik-calendar-day-contents")
        currDate = date.copy()
        dayStarted = true
    }
    
    func finishDayCode() {
        guard dayStarted else { return }
        writer.finishParagraph()
        writer.finishTableData()
        dayStarted = false
    }
    
}
