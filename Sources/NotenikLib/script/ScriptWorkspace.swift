//
//  ScriptWorkspace.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019-2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A workspace to be shared between the Script Engine and its various modules. 
public class ScriptWorkspace {
    
    var exportPath = ""
    
    var parentPath = ""
    
    public var scriptURL:     URL?
    
    var scriptWriter: DelimitedWriter?
    
    var scriptingStage: ScriptingStage = .none
    
    var scriptNoisy = true
    
    public var collection  = NoteCollection()
    
    public var mkdownContext: NotesMkdownContext?
    
    var typeCatalog = AllTypes()
    
    var inputURL:     URL?
    var explodeTags = false
    var maxDirDepth = 1
    
    var list        = NotesList()
    var fullList    = NotesList()
    
    var pendingRules: [FilterRule] = []
    var currentRules: [FilterRule] = []
    
    var pendingFields: [SortField] = []
    
    var template = Template()
    
    var webRootPath  = ""
    
    var syncLeftURL: URL?
    var syncRightURL: URL?
    var syncTotals = SyncTotals()
    var syncDirection: SyncDirection = .bidirectional
    var syncActions: SyncActions = .logOnly
    var respectBlanks: Bool = true
    
    var pendingErrors = ""
    var holdingErrors = false
    
    public var scriptLog   = ""
    
    var templateOutputConsumer: TemplateOutputConsumer?
    
    init() {
        let parentRealmPath = AppPrefs.shared.parentRealmPath
        if parentRealmPath.count > 0 {
            parentPath = parentRealmPath
        } /* else {
            if #available(OSX 10.12, *) {
                let home = FileManager.default.homeDirectoryForCurrentUser
                parentPath = home.path
            } 
        } */
    }
    
    public var parentURL: URL {
        return URL(fileURLWithPath: parentPath)
    }
    
    func newList() {
        list = NotesList()
        fullList = NotesList()
    }
    
    func openScriptWriter(fileURL: URL) {
        scriptURL = fileURL
        scriptWriter = DelimitedWriter(destination: fileURL, format: .tabDelimited)
        scriptWriter!.open()
        scriptingStage = .recording
        
        scriptWriter!.write(value: "module")
        scriptWriter!.write(value: "action")
        scriptWriter!.write(value: "modifier")
        scriptWriter!.write(value: "object")
        scriptWriter!.write(value: "value")
        scriptWriter!.endLine()
    }
    
    func writeCommandToScriptWriter(_ command: ScriptCommand) {
        scriptWriter!.write(value: "\(command.module)")
        scriptWriter!.write(value: "\(command.action)")
        scriptWriter!.write(value: command.modifier)
        scriptWriter!.write(value: command.object)
        scriptWriter!.write(value: command.value)
        scriptWriter!.endLine()
    }
    
    func closeScriptWriter() {
        guard let writer = scriptWriter else { return }
        let ok = writer.close()
        if !ok {
            writeErrorToLog("Problems writing script file")
        }
        scriptingStage = .none
    }
    
    func holdErrors() {
        holdingErrors = true
    }
    
    func releaseErrors() {
        scriptLog.append(pendingErrors)
        holdingErrors = false
        pendingErrors = ""
    }
    
    func writeErrorToLog(_ msg: String) {
        if holdingErrors {
            pendingErrors.append(formatError(msg) + "\n")
        } else {
            writeLineToLog(formatError(msg))
        }
    }
    
    func formatError(_ msg: String) -> String {
        return "  ## ERROR: " + msg
    }
    
    public func writeLineToLog(_ line: String) {
        scriptLog.append(line + "\n")
    }
    
    enum ScriptingStage {
        case none
        case inputSupplied
        case playing
        case outputSupplied
        case recording
    }
}
