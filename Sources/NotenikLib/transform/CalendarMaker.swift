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

public class CalendarMaker {
    
    var writer: Markedup
    
    var lowYM = ""
    var highYM = ""
    
    var currDate: SimpleDate?
    
    var dayStarted = false
    var weekStarted = false
    var monthStarted = false
    
    public init(lowYM: String, highYM: String) {
        self.lowYM = lowYM
        self.highYM = highYM
        writer = Markedup(format: .htmlDoc)
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
    public func nextNote(_ note: Note) -> Bool {
        
        guard let date = note.date.simpleDate else { return false }
        let ym = date.yearAndMonth
        
        guard ym >= lowYM else { return false }
        guard ym <= highYM else { return true }
        
        positionToDate(date)
        
        if note.hasSeq() {
            writer.append("\(note.seq) ")
        }
        var notenikLink = "notenik://open?"
        let folderURL = URL(fileURLWithPath: note.collection.fullPath)
        let encodedPath = String(folderURL.absoluteString.dropFirst(7))
        notenikLink.append("path=\(encodedPath)")
        notenikLink.append("&id=\(note.id)")
        writer.link(text: note.title.value, path: notenikLink)
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
        
        if currDate != nil && date.dayOfWeek < currDate!.dayOfWeek {
            finishWeekCode()
        }
        
        if !weekStarted {
            startWeekCode(for: date)
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
        for dayOfWeek in 1...7 {
            writer.startTableHeader(klass: "notenik-calendar-name-of-day")
            writer.writeLine(DateUtils.dayOfWeekNames[dayOfWeek])
            writer.finishTableHeader()
        }
        writer.finishTableRow()
        
        monthStarted = true
        
        startWeekCode(for: date)
        
        let firstDayOfMonth = date.copy()
        firstDayOfMonth.setDayOfMonth(01)
        let firstDayOfWeek = firstDayOfMonth.dayOfWeek
        if firstDayOfWeek > 1 {
            writer.startTableData(klass: "notenik-calendar-filler", colspan: firstDayOfWeek - 1)
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
        
        if currDate!.dayOfWeek < 7 {
            writer.startTableData(klass: "notenik-calendar-filler", colspan: 7 - currDate!.dayOfWeek)
            writer.writeNonBreakingSpace()
            writer.finishTableData()
        }
        finishWeekCode()
        writer.finishTable()
        monthStarted = false
    }
    
    func startWeekCode(for date: SimpleDate) {
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
