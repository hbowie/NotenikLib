//
//  SyncModule.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/22/25.
////  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// The input module for the scripting engine.
class SyncModule {
    
    var workspace = ScriptWorkspace()
    var command = ScriptCommand()
    
    init() {

    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .open:
            if command.object.lowercased() == "left" {
                workspace.syncLeftURL = URL(fileURLWithPath: command.valueWithPathResolved)
            } else if command.object.lowercased() == "right" {
                workspace.syncRightURL = URL(fileURLWithPath: command.valueWithPathResolved)
            } else {
                logError("Sync Module does not recognize an object value of \(command.object) for an Open action")
            }
        case .set:
            set()
        case .sync:
            sync()
        default:
            logError("Input Module does not recognize an action of '\(command.action)")
        }
    }
    
    func set() {
        switch command.object {
        case "direction":
            let val = StringUtils.toCommon(command.value)
            if let syncDir = SyncDirection(rawValue: val) {
                workspace.syncDirection = syncDir
            } else {
                logError("\(command.value) is not a valid sync direction: must be bidirectional, left-to-right, or right-to-left")
            }
        case "respectblanks":
            let respectBlanks = BooleanValue(command.value)
            workspace.respectBlanks = respectBlanks.isTrue
        case "actions":
            let val = StringUtils.toCommon(command.value)
            if let syncActions = SyncActions(rawValue: val) {
                workspace.syncActions = syncActions
            } else {
                logError("\(command.value) is not a valid sync actions value: must be log-only, log-details, or log-summary")
            }
        default:
            logError("Sync Set object of '\(command.object)' is not recognized")
        }
    }
        
    func sync() {
        
        guard workspace.syncLeftURL != nil else {
            logError("Sync left URL has not been set")
            return
        }
        
        guard workspace.syncRightURL != nil else {
            logError("Sync right URL has not been set")
            return
        }
        
        let syncEngine = CollectionSync()
        
        workspace.syncTotals = SyncTotals()
        
        let syncOK = syncEngine.sync(leftURL: workspace.syncLeftURL!,
                                               rightURL: workspace.syncRightURL!,
                                               syncTotals: workspace.syncTotals,
                                               direction: workspace.syncDirection,
                                               syncActions: workspace.syncActions,
                                               respectBlanks: workspace.respectBlanks)
        if syncOK {
            workspace.writeLineToLog("Sync completed successfully")
            workspace.writeLineToLog(workspace.syncTotals.totalsMsg)
        } else {
            workspace.scriptLog.append("Sync failed")
        }
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "SyncModule",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "SyncModule",
                          level: .error,
                          message: msg)
        workspace.writeErrorToLog(msg)
    }

}
