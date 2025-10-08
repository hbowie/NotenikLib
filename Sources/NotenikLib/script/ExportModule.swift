//
//  ExportModule.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/30/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class ExportModule {
    
    var workspace = ScriptWorkspace()
    var command   = ScriptCommand()
    
    var exportFormat: ExportFormat = .webBookSite
    var webBookType:  WebBookType = .website
    
    init() {
        
    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .open:
            // ??? workspace.inputURL = URL(fileURLWithPath: command.valueWithPathResolved)
            open()
        default:
            logError("Export Module does not recognize an action of '\(command.action)")
        }
    }
    
    func open() {
        let outputURL = URL(fileURLWithPath: command.valueWithPathResolved)
        let modCommon = StringUtils.toCommon(command.modifier)
        
        guard let collectionURL = workspace.collection.fullPathURL else {
            logError("No input collection to export")
            return
        }
        
        switch modCommon {
        case "webbooksite", "webbookassite":
            exportFormat = .webBookSite
            webBookType  = .website
        default:
            logError("Export Open modifier of \(command.modifier) not recognized")
            return
        }
        
        let maker = WebBookMaker(input: collectionURL, output: outputURL, webBookType: webBookType)
        if maker != nil {
            workspace.collection.webBookPath = outputURL.path
            workspace.collection.webBookAsEPUB = true
            let filesWritten = maker!.generate()
            logInfo("Web book generated \(filesWritten) files at \(outputURL.path)")
        } else {
            logError("Web book could not be generated!")
        }
        
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ExportModule",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ExportModule",
                          level: .error,
                          message: msg)
        workspace.writeErrorToLog(msg)
    }
}

