//
//  Template.swift
//  Notenik
//
//  Created by Herb Bowie on 6/3/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A template to be used to create text file output
/// (such as an HTML file) from a Collection of Notes.
public class Template {
    
    public var util = TemplateUtil()
    var notesList = NotesList()
    var collection = NoteCollection()
    var workspace: ScriptWorkspace?
    
    var loopLines        = [TemplateLine]()
    var outerLinesBefore = [TemplateLine]()
    var outerLinesAfter  = [TemplateLine]()
    var endLines         = [TemplateLine]()
    var endGroupLines    = [[TemplateLine]]()
    
    var endingGroupNumber = -1
    var endGroupPendingIfs = 0
    
    var emptyNote: Note!
    
    public init() {
        
    }
    
    func setWebRoot(filePath: String) {
        util.setWebRoot(filePath: filePath)
    }
    
    func setWorkspace(_ workspace: ScriptWorkspace) {
        self.workspace = workspace
        util.setWorkspace(workspace)
    }
    
    /// Open a new template file.
    ///
    /// - Parameter templateURL: The location of the template file.
    /// - Returns: True if opened ok, false if errors.
    public func openTemplate(templateURL: URL) -> Bool {
        return util.openTemplate(templateURL: templateURL)
    }
    
    /// Open a template supplied as a string.
    /// - Parameter templateContents: The contents of a template file previously read from disk. 
    public func openTemplate(templateContents: String) {
        util.openTemplate(templateContents: templateContents)
    }
    
    public func supplyData(_ note: Note,
                             dataSource: String,
                             io: NotenikIO?,
                             bodyHTML: String? = nil,
                             minutesToRead: MinutesToReadValue? = nil) {
        self.notesList = NotesList()
        notesList.append(note)
        util.dataFileName = FileName(dataSource)
        util.io = io
        util.bodyHTML = bodyHTML
        util.minutesToRead = minutesToRead
    }
    
    /// Supply the Notenik data to be used with the template.
    ///
    /// - Parameters:
    ///   - notesList: The list of Notes to be used.
    ///   - dataSource: A path identifying the source of the notes.
    public func supplyData(notesList: NotesList, dataSource: String) {
        self.notesList = notesList
        util.dataFileName = FileName(dataSource)
        util.bodyHTML = nil
        util.minutesToRead = nil
    }
    
    /// Merge the supplied data with the template to generate output.
    ///
    /// - Returns: True if everything went smoothly, false if problems. 
    public func generateOutput() -> Bool {
        
        guard util.templateOK else { return false }
        if notesList.count > 0 {
            collection = notesList[0].collection
        } else {
            collection = NoteCollection()
        }
        
        loopLines = []
        outerLinesBefore = []
        outerLinesAfter = []
        endLines = []
        endGroupLines = []
        
        endingGroupNumber = -1
        endGroupPendingIfs = 0
        
        util.skippingData = false
        util.outputStage = .front
        var line = util.nextTemplateLine()
        emptyNote = Note(collection: collection)
        while line != nil {
            if util.outputStage == .front {
                line!.generateOutput(note: emptyNote)
            } else if util.outputStage == .loop {
                if line!.command != nil && line!.command! == .nextrec {
                    // Don't need to store the nextrec command line
                } else {
                    addToLoopLines(line: line!)
                }
            } else if util.outputStage == .postLoop {
                if line!.command != nil && line!.command! == .loop {
                    processLoop()
                    endLoopProcessing()
                } else {
                    line!.generateOutput(note: emptyNote)
                }
            }
            line = util.nextTemplateLine()
        }
        util.closeOutput()
        return true
    }
    
    /// Store another line that will be part of the loop we will execute for every note.
    func addToLoopLines(line: TemplateLine) {
        
        loopLines.append(line)
        
        // Capture end group lines in a separate array. 
        var nextEndingGroupNumber = -1
        if line.command != nil {
            switch line.command! {
            case .ifendgroup:
                endingGroupNumber = -1
                guard let groupNum = line.validGroupNumber() else { break }
                nextEndingGroupNumber = groupNum
            case .definegroup, .ifnewgroup, .ifchange, .ifendlist, .ifnewlist:
                endingGroupNumber = -1
            case .ifCmd:
                endGroupPendingIfs += 1
            case .endif:
                if endGroupPendingIfs > 0 {
                    endGroupPendingIfs -= 1
                } else {
                    endingGroupNumber = -1
                }
            default:
                break
            }
        }
        if endingGroupNumber >= 0 {
            addEndGroupLine(line: line, groupNumber: endingGroupNumber)
        }
        if nextEndingGroupNumber >= 0 {
            endingGroupNumber = nextEndingGroupNumber
        }
    }
    
    /// Add another template line to our list of lines to be executed when a group ends.
    func addEndGroupLine(line: TemplateLine, groupNumber: Int) {
        while endGroupLines.count <= groupNumber {
            endGroupLines.append([])
        }
        endGroupLines[groupNumber].append(line)
    }
    
    func endLoopProcessing() {
        util.endAllGroups()
        var i = util.endGroup.count - 1
        while i >= 0 {
            if util.endGroup[i] {
                if i < endGroupLines.count {
                    for endGroupLine in endGroupLines[i] {
                        endGroupLine.generateOutput(note: emptyNote)
                    }
                }
            }
            i -= 1
        }
    }
    
    /// Merge that data in the Notes collection with the template lines
    /// between the nextrec and loop commands. 
    func processLoop() {
        for note in notesList {
            processLoopForNote(note)
        }
    }
    
    func processLoopForNote(_ note: Note, endOfNotes: Bool = false) {
        util.resetGroupBreaks()
        util.skippingData = false
        util.endingGroup = false
        for line in loopLines {
            line.generateOutput(note: note)
        }
    }
}
