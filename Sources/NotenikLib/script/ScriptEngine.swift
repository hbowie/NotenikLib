//
//  ScriptEngine.swift
//  Notenik
//
//  Created by Herb Bowie on 7/23/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils

/// The core module for playing and recording scripts, and
/// executing script commands.
public class ScriptEngine: RowConsumer {
    
    var lastScriptURL: URL?
    
    var lastCommandModule: ScriptModule = .script
    var lastCommandAction: ScriptAction = .blank
    
    public var workspace = ScriptWorkspace()
    
    var command   = ScriptCommand()
    
    var reader:     DelimitedReader!
    var rowsRead  = 0
    
    static let pathPlaceHolder = "#PATH#"
    
    let input    = InputModule()
    let filter   = FilterModule()
    let sorter   = SortModule()
    let template = TemplateModule()
    let output   = OutputModule()
    let sync     = SyncModule()
    
    public init() {
 
    }
    
    public var templateOutputConsumer: TemplateOutputConsumer? {
        get {
            return workspace.templateOutputConsumer
        }
        set {
            workspace.templateOutputConsumer = newValue
        }
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    public func consumeField(label: String, value: String, rule: FieldUpdateRule = .always) {
        workspace.holdErrors()
        let labelLower = label.lowercased()
        let valueLower = value.lowercased()
        switch labelLower {
        case "module":
            let possibleCommand = getCommand(moduleStr: value)
            if possibleCommand != nil {
                command = possibleCommand!
            }
        case "action":
            command.setAction(value: valueLower)
        case "modifier":
            command.modifier = value
        case "object":
            command.object = value
        case "value":
            command.value = value
            if value.hasPrefix(ScriptEngine.pathPlaceHolder) {
                let scriptFileName = FileName(workspace.scriptURL!)
                let scriptFolderName = FileName(scriptFileName.path)
                var relativePath = String(value.dropFirst(ScriptEngine.pathPlaceHolder.count))
                if relativePath.hasPrefix("/") {
                    relativePath = String(relativePath.dropFirst(1))
                }
                command.valueWithPathResolved = scriptFolderName.resolveRelative(path: relativePath)
            } else {
                command.valueWithPathResolved = value
            }
        default:
            logError("Column heading of '\(label)' not recognized as valid within a script file")
        }
    }
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    public func consumeRow(labels: [String], fields: [String]) {
        rowsRead += 1
        playCommand(command)
        command = ScriptCommand(workspace: workspace)
    }
    
    /// Play a script command -- all script commands should be executed
    /// through this method, whether they come from a script being played
    /// or from the Scripter window.
    public func playCommand(_ command: ScriptCommand) {
        if command.module == .script {
            if command.action != .stop {
                stopIfRecording()
                if command.module != lastCommandModule || lastCommandAction == .play || command.action == .open {
                    let holdURL = workspace.scriptURL
                    let holdConsumer = workspace.templateOutputConsumer
                    workspace = ScriptWorkspace()
                    workspace.scriptURL = holdURL
                    workspace.templateOutputConsumer = holdConsumer
                    command.workspace = workspace
                }
            }
        }
        var verb = "Executing"
        if workspace.scriptingStage == .playing {
            verb = "Playing"
        }
        workspace.writeLineToLog("\(verb) Script Command: " + String(describing: command))
        workspace.releaseErrors()
        if workspace.scriptingStage == .recording && command.module != .script {
            workspace.writeCommandToScriptWriter(command)
        }
        switch command.module {
        case .script:
            playScriptCommand(command)
        case .input:
            input.playCommand(workspace: workspace, command: command)
        case .filter:
            filter.playCommand(workspace: workspace, command: command)
        case .sort:
            sorter.playCommand(workspace: workspace, command: command)
        case .template:
            template.playCommand(workspace: workspace, command: command)
        case .output:
            output.playCommand(workspace: workspace, command: command)
        case .sync:
            sync.playCommand(workspace: workspace, command: command)
        case .browse:
            browse(workspace: workspace, command: command)
        default:
            break
        }
        lastCommandModule = command.module
        lastCommandAction = command.action
    }
    
    /// Play a command to be executed by the Scripting Engine itself.
    func playScriptCommand(_ command: ScriptCommand) {
        if command.action == .open && command.modifier == "input" {
            scriptOpenInput(command)
        } else if command.action == .play {
            scriptPlay(command)
        } else if command.action == .open && command.modifier == "output" {
            scriptOpenOutput(command)
        } else if command.action == .record {
            scriptRecord(command)
        } else if command.action == .stop {
            scriptStopRecording(command)
        } else if command.action == .include {
            scriptInclude(command)
        } else if command.action == .set {
            if command.objectCommon == "lognoise" {
                if command.valueCommon == "noisy" {
                    workspace.scriptNoisy = true
                } else if command.valueCommon == "quiet" {
                    workspace.scriptNoisy = false
                } else {
                    logError("Script Set log noise value of \(command.valueCommon) not recognized")
                }
            } else {
                logError("Script Set object of \(command.objectCommon) not recognized")
            }
        } else {
            logError("Script Action of \(command.action) not recognized")
        }
    }
    
    /// Open a script file as input.
    func scriptOpenInput(_ command: ScriptCommand) {
        workspace.scriptURL = command.valueURL
        workspace.scriptingStage = .inputSupplied
    }
    
    /// Play a script file that has previously been opened.
    func scriptPlay(_ command: ScriptCommand) {
        
        if workspace.scriptingStage != .inputSupplied && lastScriptURL != nil {
            workspace.scriptingStage = .inputSupplied
            if workspace.scriptURL == nil {
                workspace.scriptURL = lastScriptURL
            }
        }
        guard workspace.scriptingStage == .inputSupplied else {
            logError("Script Play command encountered with no preceding Script Open Input")
            return
        }
        guard let scriptURL = workspace.scriptURL else {
            logError("Script Play command encountered but no valid script file specified")
            return
        }
        logInfo("Starting to play script located at \(scriptURL.path) on \(DateUtils.shared.dateTimeToday)")
        workspace.exportPath = command.value
        workspace.scriptingStage = .playing
        rowsRead = 0
        reader = DelimitedReader()
        reader.setContext(consumer: self)
        reader.read(fileURL: scriptURL)
        logInfo("Script execution complete on \(DateUtils.shared.dateTimeToday)")
        lastScriptURL = workspace.scriptURL
    }
    
    /// Open an output script file.
    func scriptOpenOutput(_ command: ScriptCommand) {
        workspace.scriptURL = command.valueURL
        workspace.scriptingStage = .outputSupplied
    }
    
    /// Start recording a script to an output file that has already
    /// been opened.
    func scriptRecord(_ command: ScriptCommand) {
        guard workspace.scriptingStage == .outputSupplied else {
            logError("Script Record command encountered with no preceding Script Open Output")
            return
        }
        guard let scriptURL = workspace.scriptURL else {
            logError("Script Record command encountered but no valid script file specified")
            return
        }
        logInfo("Starting to record script located at \(scriptURL.path) on \(DateUtils.shared.dateTimeToday)")
        workspace.openScriptWriter(fileURL: scriptURL)
    }
    
    func stopIfRecording() {
        if workspace.scriptingStage == .recording {
            stopRecording()
        }
    }
    
    func scriptStopRecording(_ command: ScriptCommand) {
        guard workspace.scriptingStage == .recording else {
            logError("Cannot Stop Script Recording since None is in Progress")
            return
        }
        stopRecording()
    }
    
    func scriptInclude(_ command: ScriptCommand) {
        
        guard let scriptURL = workspace.scriptURL else {
            logError("Script Include command encountered but no valid script file specified")
            return
        }
        
        var includeURL = scriptURL
        let ext = FileExtension(includeURL.pathExtension)
        
        includeURL.deletePathExtension()
        includeURL.deleteLastPathComponent()
        let fileName = command.value
        includeURL.appendPathComponent(fileName)
        let includeExt = FileExtension(fileName: fileName)
        if includeExt.isEmpty {
            includeURL.appendPathExtension(ext.withoutDot)
        }
        
        logInfo("Starting to include script located at \(includeURL.path) on \(DateUtils.shared.dateTimeToday)")
        reader.include(fileURL: includeURL)
        logInfo("Script inclusion complete on \(DateUtils.shared.dateTimeToday)")
    }
    
    func stopRecording() {
        lastScriptURL = workspace.scriptURL
        workspace.closeScriptWriter()
        logInfo("Stopped recording of script located at \(workspace.scriptURL!)")
    }
    
    /// Process a Browse command.
    /// - Parameters:
    ///   - workspace: The shared workspace to be used.
    ///   - command: The command to be executed.
    func browse(workspace: ScriptWorkspace, command: ScriptCommand) {
        guard let url = URL(string: command.value) else {
            logError("Cannot Browse a URL with a value of \(command.value)")
            return
        }
        guard NSWorkspace.shared.open(url) else {
            logError("Could not Browse the specified URL: \(command.value)")
            return
        }
    }
    
    /// Factory method to create a command populated with the given module.
    ///
    /// - Parameter moduleStr: A string naming the desired module.
    /// - Returns: Either the command with the specified module, or
    ///            nil if the module name was invalid.
    public func getCommand(moduleStr: String) -> ScriptCommand? {
        let command = ScriptCommand(workspace: workspace)
        let ok = command.setModule(value: moduleStr)
        if ok {
            return command
        }
        return nil
    }
    
    public func close() {
        if let mdc = workspace.mkdownContext {
            if mdc.io.collectionOpen {
                mdc.io.closeCollection()
            }
        }
    }
    
    func newWorkspace() {
        workspace = ScriptWorkspace()
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ScriptEngine",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log. 
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ScriptEngine",
                          level: .error,
                          message: msg)
        workspace.writeErrorToLog(msg)
    }

}
