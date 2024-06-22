//
//  MkdownExpander.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/21/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown

import NotenikUtils

public class MkdownExpander {
    
    var expanded = ""
    
    let cmdLine = MkdownCommandLine()
    
    var note: Note!
    var io: NotenikIO = FileIO()
    var parms = DisplayParms()
    
    public init() {
        
    }
    
    public func expand(md: String, note: Note, io: NotenikIO, parms: DisplayParms) -> String {
        
        self.note = note
        self.io = io
        self.parms = parms
        
        expanded = ""
        let reader = BigStringReader(md)
        reader.open()
        var lineIn = reader.readLine()
        while lineIn != nil {
            let cmdInfo = cmdLine.checkLine(lineIn!)
            if cmdInfo.validCommand {
                processCommand(lineIn: lineIn!, info: cmdInfo)
            } else {
                appendExpandedLine(lineIn!)
            }
            lineIn = reader.readLine()
        }
        reader.close()
        return expanded
    }
    
    func processCommand(lineIn: String, info: MkdownCommandInfo) {
        switch info.lineType {
        case .tocForCollection:
            genCollectionToC(info: info)
        default:
            appendExpandedLine(lineIn)
        }
    }
    
    func genCollectionToC(info: MkdownCommandInfo) {
        let outliner = NoteOutliner(list: io.notesList,
                                    levelStart: info.tocLevelStartInt,
                                    levelEnd: info.tocLevelEndInt,
                                    skipID: note.id,
                                    displayParms: parms)
        expanded.append(outliner.genToC(details: false).code)
    }
    
    func appendExpandedLine(_ line: String) {
        expanded.append(line + "\n")
    }
}
