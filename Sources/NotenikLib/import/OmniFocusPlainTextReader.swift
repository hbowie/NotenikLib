//
//  OmniFocusPlainTextReader.swift
//
//  Created by Herb Bowie on 1/2/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).

import Foundation

import NotenikUtils

/// An object that can read a plain text file exported from OmniFocus,
/// and then return fields and rows to a Row Consumer.
public class OmniFocusPlainTextReader: RowImporter {
    
    var consumer: RowConsumer?
    
    var noteLabels: [String] = []
    var noteValues: [String] = []
    
    var parents: [String] = []
    
    var taskDepth = 0
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
    var repeatMethod = ""
    var repeatRule = ""
    
    var tasks: [String: OmniTask] = [:]
    
    public init() {
        noteLabels.append(NotenikConstants.title)
        noteLabels.append(NotenikConstants.tags)
        noteLabels.append(NotenikConstants.seq)
        noteLabels.append(NotenikConstants.date)
        noteLabels.append(NotenikConstants.recurs)
        noteLabels.append(NotenikConstants.body)
    }
    
    public func setContext(consumer: RowConsumer) {
        self.consumer = consumer
    }
    
    public func read(fileURL: URL) {
        
        // Prepare to process the file.
        guard let reader = BigStringReader(fileURL: fileURL) else { return }
        reader.open()
        
        var moreLines = true
        var bodyLine = ""
        var fieldName = ""
        var fieldValue = ""
        var spaceCount = 0
        
        // Process each line in the file.
        var possibleLine = reader.readLine()
        while moreLines {
            
            // Check for end of file.
            guard let line = possibleLine else {
                endOfTask()
                moreLines = false
                continue
            }
            
            // Scan the characters in the line.
            var tabCount = 0
            var linePosition: LinePosition = .countingTabs
            var lineType: LineType = .unknown
            for char in line {
                switch linePosition {
                case .countingTabs:
                    if char == "\t" {
                        tabCount += 1
                    } else if char == "-" && line.contains("@parallel(") {
                        endOfTask()
                        lineType = .task
                        fieldName = ""
                        fieldValue = ""
                        spaceCount = 0
                        linePosition = .dash
                        taskDepth = tabCount
                    } else {
                        lineType = .body
                        bodyLine = ""
                        bodyLine.append(char)
                        linePosition = .body
                    }
                case .body:
                    bodyLine.append(char)
                case .dash:
                    if char == "@" {
                        linePosition = .atSign
                        fieldName = ""
                    } else if char.isWhitespace {
                        if title.count > 0 {
                            spaceCount += 1
                        }
                    } else {
                        if spaceCount > 0 {
                            title.append(" ")
                            spaceCount = 0
                        }
                        title.append(char)
                    }
                case .atSign:
                    if char == "(" {
                        linePosition = .leftParen
                        fieldValue = ""
                    } else {
                        fieldName.append(char)
                    }
                case .leftParen:
                    if char == ")" {
                        switch fieldName {
                        case "autodone", "parallel":
                            break
                        case "due":
                            dueDate = fieldValue
                        case "done":
                            completionDate = fieldValue
                        case "repeat-method":
                            repeatMethod = fieldValue
                        case "repeat-rule":
                            repeatRule = fieldValue
                        case "context":
                            context = fieldValue
                        case "tags":
                            tags = fieldValue
                        default:
                            logError("Encountered unexpected field name of \(fieldName)")
                        }
                        linePosition = .rightParen
                    } else {
                        fieldValue.append(char)
                    }
                case .rightParen:
                    if char.isWhitespace {
                        // skip whitespace
                    } else if char == "@" {
                        linePosition = .atSign
                        fieldName = ""
                    } else {
                        logError("Character of \(char) found on task line between right paren and at sign")
                    }
                }
            }
                
            // Finish up processing of this line.
            if lineType == .body {
                if notes.count > 0 {
                    notes.append("\n")
                }
                notes.append(bodyLine)
                bodyLine = ""
            }
            
            // Get the next line.
            possibleLine = reader.readLine()
        }
        
        // Finish up processing of the file.
        reader.close()
        
        // Now go through the omni tasks we've stored, converting to
        // Notenik fields, and passing back fields and rows.
        for (_, task) in tasks {
            generateNoteRow(task)
        }
    }
    
    /// We have all the input for one task - do something with it and get ready for the next task.
    func endOfTask() {
        if title.count > 0 && completionDate.count == 0 {
            storeOmniTask()
        }
        taskDepth = 0
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
        repeatMethod = ""
        repeatRule = ""
    }
    
    /// Store an Omni Task in an internal dictionary for now, combining duplicates.
    func storeOmniTask() {
        
        let newTask = OmniTask()

        newTask.title = title
        newTask.tags = tags
        newTask.context = context
        newTask.dueDate = dueDate
        newTask.repeatMethod = repeatMethod
        newTask.repeatRule = repeatRule
        newTask.body = notes
        newTask.parents = []
        if taskDepth > 0 {
            var i = 0
            while i < taskDepth {
                if i < parents.count {
                    newTask.parents.append(parents[i])
                }
                i += 1
            }
        }
        
        let existingTask = tasks[title]
        if existingTask == nil {
            tasks[title] = newTask
        } else {
            if existingTask!.parents.count < newTask.parents.count {
                existingTask!.parents = newTask.parents
            }
        }
        
        while parents.count > taskDepth {
            parents.remove(at: parents.count - 1)
        }
        parents.append(title)
    }
    
    /// Generate the fields needed for a Notenik note.
    func generateNoteRow(_ task: OmniTask) {
        
        noteValues = []
        
        // Return Note title
        generateNoteField(task.title)
        
        // Generate the tags.
        var workTags = task.tags
        if task.context.count > 0 && !workTags.contains(task.context) {
            if workTags.count > 0 {
                workTags.append("; ")
            }
            workTags.append(task.context)
        }
        
        if task.parents.count > 0 {
            var parentsTag = ""
            for parent in task.parents {
                if parentsTag.count > 0 {
                    parentsTag.append(".")
                }
                parentsTag.append(parent)
            }
            if !workTags.contains(parentsTag) {
                if workTags.count > 0 {
                    workTags.append("; ")
                }
                workTags.append(parentsTag)
            }
        }
        generateNoteField(workTags)
        
        // Return Note Seq field
        generateNoteField("")
        
        // Generate Date field
        var date = ""
        if task.dueDate.count > 10 {
            date = String(task.dueDate.prefix(10))
        } else {
            date = task.dueDate
        }
        generateNoteField(date)
        
        // Generate the recurs field
        var recurs = ""
        var freq = ""
        var interval = ""
        if task.repeatMethod == "" {
            // Do nothing if blank
        } else if task.repeatMethod != "fixed" {
            logError("Don't know what to do with repeat method of \(task.repeatMethod)")
        } else {
            let components = task.repeatRule.components(separatedBy: ";")
            for component in components {
                let str = String(component)
                let subs = str.components(separatedBy: "=")
                if subs.count != 2 {
                    logError("Don't know what to do with this repeat rule component: \(str)")
                } else {
                    switch subs[0] {
                    case "FREQ":
                        freq = String(subs[1])
                    case "INTERVAL":
                        interval = String(subs[1])
                    default:
                        logError("Don't know what to do with this repeat rule component: \(subs[0])")
                    }
                }
            }
            recurs = "every "
            var pluralizer = ""
            if interval != "" && interval != "1" {
                recurs.append("\(interval) ")
                pluralizer = "s"
            }
            switch freq {
            case "WEEKLY":
                recurs.append("week")
                recurs.append(pluralizer)
            case "MONTHLY":
                recurs.append("month")
                recurs.append(pluralizer)
            default:
                logError("Don't know what to do with frequency of \(freq)")
            }
        }
        
        generateNoteField(recurs)
        
        // Generate the body
        generateNoteField(task.body)
        
        // Finish up the Note row.
        consumer!.consumeRow(labels: noteLabels, fields: noteValues)
        
        // Save parent projects.
        while parents.count > taskDepth {
            parents.remove(at: parents.count - 1)
        }
        parents.append(title)
    }
    
    func generateNoteField(_ value: String) {
        consumer!.consumeField(label: noteLabels[noteValues.count], value: value)
        noteValues.append(value)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "OmniFocusPlainTextReader",
                          level: .error,
                          message: msg)
    }
    
    enum LineType {
        case unknown
        case task
        case body
    }
    
    enum LinePosition {
        case countingTabs
        case body
        case dash
        case atSign
        case leftParen
        case rightParen
    }
}

