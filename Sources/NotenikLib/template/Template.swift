//
//  Template.swift
//  Notenik
//
//  Created by Herb Bowie on 6/3/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
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
    
    public func closeTemplate() {
        util.closeTemplate()
    }
    
    public func supplyData(_ note: Note,
                             dataSource: String,
                             io: NotenikIO?,
                             bodyHTML: String? = nil,
                             minutesToRead: MinutesToReadValue? = nil) {
        util.notesList = NotesList()
        util.notesList.append(note)
        util.dataFileName = FileName(dataSource)
        util.dataCount = 0
        util.dataMax = 1
        util.io = io
        util.bodyHTML = bodyHTML
        util.mdResults.minutesToRead = minutesToRead
    }
    
    /// Supply the Notenik data to be used with the template.
    ///
    /// - Parameters:
    ///   - notesList: The list of Notes to be used.
    ///   - dataSource: A path identifying the source of the notes.
    public func supplyData(notesList: NotesList, dataSource: String, io: NotenikIO? = nil) {
        util.notesList = notesList
        util.dataFileName = FileName(dataSource)
        util.dataCount = 0
        util.dataMax = notesList.count
        if io != nil {
            util.io = io!
        }
        util.bodyHTML = nil
        util.mdResults.minutesToRead = nil
    }
    
    /// Merge the supplied data with the template to generate output.
    ///
    /// - Returns: True if everything went smoothly, false if problems. 
    public func generateOutput(templateOutputConsumer: TemplateOutputConsumer? = nil) -> Bool {
        
        if templateOutputConsumer != nil {
            if workspace == nil {
                workspace = ScriptWorkspace()
            }
            workspace!.templateOutputConsumer = templateOutputConsumer
            if util.workspace == nil {
                util.setWorkspace(workspace!)
            } else {
                util.workspace!.templateOutputConsumer = templateOutputConsumer
            }
        }
        util.outputFilesWritten = 0
        util.outputFilesSkipped = 0
        guard util.templateOK else {
            util.logError("Template not ready for output generation!")
            return false
        }
        if util.notesList.count > 0 {
            collection = util.notesList[0].collection
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
                line!.generateOutput(note: emptyNote, position: -1)
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
                    line!.generateOutput(note: emptyNote, position: -1)
                }
            }
            line = util.nextTemplateLine()
        }
        util.closeOutput()
        util.logInfo("\(util.outputFilesWritten) output files written")
        util.logInfo("\(util.outputFilesSkipped) output files with no changes")
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
                        endGroupLine.generateOutput(note: emptyNote, position: -1)
                    }
                }
            }
            i -= 1
        }
    }
    
    /// Merge that data in the Notes collection with the template lines
    /// between the nextrec and loop commands. 
    func processLoop() {
        if util.outputOpen {
            util.wikiStyle = "2"
            util.parms.wikiLinks.format = .fileName
            util.parms.wikiLinks.prefix = "#"
            util.parms.wikiLinks.suffix = ""
        } else {
            util.wikiStyle = "1"
            util.parms.wikiLinks.format = .fileName
            util.parms.wikiLinks.prefix = ""
            util.parms.wikiLinks.suffix = ".html"
        }
        
        util.notesIndex = -1
        for note in util.notesList {
            util.notesIndex += 1
            util.dataCount = util.notesIndex + 1
            util.note = note
            if workspace != nil {
                workspace!.mkdownContext?.identifyNoteToParse(id: note.noteID.commonID,
                                                          text: note.noteID.text,
                                                          fileName: note.noteID.commonFileName,
                                                          shortID: note.shortID.value)
            }
            processLoopForNote(note)
        }
    }
    
    func processLoopForNote(_ note: Note, endOfNotes: Bool = false) {
        util.resetGroupBreaks()
        util.bodyHTML = nil
        util.mdResults = TransformMdResults()
        util.skippingData = false
        util.endingGroup = false
        for line in loopLines {
            line.generateOutput(note: note, position: util.notesIndex)
        }
    }
}
