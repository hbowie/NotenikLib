//
//  FilterModule.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class FilterModule {
    
    var workspace = ScriptWorkspace()
    var command = ScriptCommand()
    var openURL = URL(fileURLWithPath: "")
    
    init() {
    
    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .add:
            addFilter()
        case .clear:
            clear()
        case .set:
            if command.object == "params" {
                setParams()
            } else {
                workspace.writeErrorToLog("Object value of '\(command.object)' is not valid for filter set command")
            }
        default:
            break
        }
    }
    
    func addFilter() {
        let newRule = FilterRule(dict: workspace.collection.dict,
                                label: command.object,
                                   op: command.modifier,
                                   to: command.value)
        workspace.pendingRules.append(newRule)
        newRule.logRule()
    }
    
    func clear() {
        workspace.pendingRules = []
    }
    
    func setParams() {
        workspace.currentRules = workspace.pendingRules
        workspace.list = NotesList()
        var dataCount = 0
        for note in workspace.fullList {
            var counted = false
            var selected = true
            for rule in workspace.currentRules {
                var field: NoteField? = NoteField()
                var value = ""
                let label = rule.field!.fieldLabel.commonForm
                field = FieldGrabber.getField(note: note, label: label)
                if field == nil {
                    if label == "datacount" {
                        dataCount += 1
                        counted = true
                        value = "\(dataCount)"
                    }
                    field = NoteField(def: rule.field!, value: value,
                                      statusConfig: workspace.collection.statusConfig,
                                      levelConfig: workspace.collection.levelConfig)
                }
                var passed = false
                if field != nil {
                    passed = rule.op.compare(field!.value, rule.to)
                }
                if !passed {
                    selected = false
                }
            }
            if selected {
                workspace.list.append(note)
                if !counted {
                    dataCount += 1
                }
            }
        }
        logInfo("\(workspace.list.count) Notes passed the filter rules")
        logInfo("\(workspace.fullList.count - workspace.list.count) Notes were filtered out")
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FilterModule",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FilterModule",
                          level: .error,
                          message: msg)
        workspace.writeErrorToLog(msg)
    }
}
