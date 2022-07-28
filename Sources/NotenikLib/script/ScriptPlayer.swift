//
//  ScriptPlayer.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/17/21.
//
//  Copyright © 2021-2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class ScriptPlayer {
    
    public var scripter = ScriptEngine()
    
    public init() {
        
    }
    
    public func playScript(fileName: String, exportPath: String = "", templateOutputConsumer: TemplateOutputConsumer? = nil) {
        
        scripter.templateOutputConsumer = templateOutputConsumer
        
        let openCommand = ScriptCommand(workspace: scripter.workspace)
        openCommand.module = .script
        openCommand.action = .open
        openCommand.modifier = "input"
        openCommand.value = fileName
        scripter.playCommand(openCommand)
        
        let playCommand = ScriptCommand(workspace: scripter.workspace)
        playCommand.module = .script
        playCommand.action = .play
        playCommand.value = exportPath
        scripter.playCommand(playCommand)
        
        scripter.close()
        
    }
}
