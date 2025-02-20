//
//  OmniFocusReader.swift
//
//  Created by Herb Bowie on 1/1/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).

import Foundation

public class OmniFocusReader: RowImporter, RowConsumer {
    
    var consumer:           RowConsumer!
    
    var noteLabels: [String] = []
    var noteValues: [String] = []
    
    var title = ""
    var taskID = ""
    var type = ""
    var status = ""
    var project = ""
    var context = ""
    var startDate = ""
    var dueDate = ""
    var completionDate = ""
    var duration = ""
    var flagged = ""
    var notes = ""
    var tags = ""
    
    public init() {
        noteLabels.append(NotenikConstants.title)
        noteLabels.append(NotenikConstants.tags)
        noteLabels.append(NotenikConstants.seq)
        noteLabels.append(NotenikConstants.date)
        noteLabels.append(NotenikConstants.body)
    }
    
    /// Initialize the class with a Row Consumer.
    public func setContext(consumer: RowConsumer) {
        self.consumer = consumer
    }
    
    /// Read the CSV rows from OmniFocus and convert them to
    /// Notenik fields.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    public func read(fileURL: URL) {
        let reader = DelimitedReader()
        reader.setContext(consumer: self)
        reader.read(fileURL: fileURL)
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    public func consumeField(label: String, value: String, rule: FieldUpdateRule = .always) {
        switch label {
        case "Task ID":
            taskID = value
        case "Type":
            type = value
        case "Name":
            title = value
        case "Status":
            status = value
        case "Project":
            project = value
        case "Context":
            context = value
        case "Start Date":
            startDate = value
        case "Due Date":
            dueDate = value
        case "Completion Date":
            completionDate = value
        case "Duration":
            duration = value
        case "Flagged":
            flagged = value
        case "Notes":
            notes = value
        case "Tags":
            tags = value
        default:
            print("Wasn't expecting a column titled \(label)")
        }
    }
    

    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    public func consumeRow(labels: [String], fields: [String]) {
        if type == "Action" && title.count > 0 {
            generateNoteRow()
        }
        title = ""
        taskID = ""
        type = ""
        status = ""
        project = ""
        context = ""
        startDate = ""
        dueDate = ""
        completionDate = ""
        duration = ""
        flagged = ""
        notes = ""
        tags = ""
    }
    
    func generateNoteRow() {
        noteValues = []
        
        // Return Note title
        generateNoteField(title)
        
        // Return Note tags
        if project.count > 0 && !tags.contains(project) {
            if tags.count > 0 {
                tags.append("; ")
            }
            tags.append(project)
        }
        if context.count > 0 && !tags.contains(context) {
            if tags.count > 0 {
                tags.append("; ")
            }
            tags.append(context)
        }
        generateNoteField(tags)
        
        // Return Note Seq field
        generateNoteField(taskID)
        
        // Generate Date field
        var dateAndTime = ""
        if dueDate.count > 0 {
            dateAndTime = dueDate
        } else if completionDate.count > 0 {
            dateAndTime = completionDate
        } else if startDate.count > 0 {
            dateAndTime = startDate
        }
        var date = ""
        if dateAndTime.hasSuffix(" 00:00:00 +0000") || dateAndTime.hasSuffix(" 01:00:00 +0000") {
            date = String(dateAndTime.prefix(10))
        } else {
            date = dateAndTime
        }
        generateNoteField(date)
        
        // Generate the body
        generateNoteField(notes)
        
        // Finish up the Note row.
        print("OmniFocusReader.generateNoteRow")
        print("  - Labels = \(noteLabels)")
        print("  - Fields = \(noteValues)")
        consumer.consumeRow(labels: noteLabels, fields: noteValues)
    }
    
    func generateNoteField(_ value: String) {
        print("OmniFocusReader.generateNoteField with value of \(value)")
        print("  - note values count = \(noteValues.count)")
        print("  - Label = \(noteLabels[noteValues.count])")
        consumer.consumeField(label: noteLabels[noteValues.count], value: value, rule: .always)
        noteValues.append(value)
    }
}
