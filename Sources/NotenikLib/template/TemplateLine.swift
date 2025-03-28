//
//  TemplateLine.swift
//  Notenik
//
//  Created by Herb Bowie on 6/4/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// One line of a template, along with metadata.
class TemplateLine {
    
    var util: TemplateUtil
    
    let delimiters = "\" =,;\t\r\n";
    
    var lineNumber = 0
    var text = ""
    var commandString: Substring = ""
    var command: TemplateCommand?
    var tokens = [Substring]()
    
    
    /// Initialize with required parameters
    ///
    /// - Parameters:
    ///   - text: The text making up the line.
    ///   - util: The instance of TemplateUtil that we are sharing.
    init(text: String, util: TemplateUtil) {
        // self.text = StringUtils.trim(text)
        self.text = text
        self.util = util
        lineNumber = util.lineCount
        analyzeLine()
    }
    
    /// Let's see what kind of line we have
    func analyzeLine() {
        if text.count > 2 && lineNumber == 1 {
            setCommandCharsFromFirstLine()
        }
        
        if text.hasPrefix(util.startCommand) && text.hasSuffix(util.endCommand) {
            analyzeApparentCommandLine()
        }
    }
    
    /// Found the right delimiters -- now let's look for a command
    func analyzeApparentCommandLine() {
        tokens = []
        let start = text.index(text.startIndex, offsetBy: util.startCommand.count)
        let end   = text.index(text.endIndex, offsetBy: (0 - util.endCommand.count))
        var index = start
        var tokenStart = text.startIndex
        var quoteChar: Character = "'"
        var withinQuotes = false
        while index < end {
            let char = text[index]
            if withinQuotes {
                if char == quoteChar {
                    addToken(start: tokenStart, end: index)
                    withinQuotes = false
                    tokenStart = text.startIndex
                }
            } else if char == "'" || char == "\"" {
                addToken(start: tokenStart, end: index)
                withinQuotes = true
                quoteChar = char
                tokenStart = text.index(index, offsetBy: 1)
            } else if char.isWhitespace || char == "," || char == ";" || char == ":" {
                addToken(start: tokenStart, end: index)
                tokenStart = text.startIndex
            } else if tokenStart == text.startIndex {
                tokenStart = index
            }
            index = text.index(index, offsetBy: 1)
        }
        addToken(start: tokenStart, end: index)
        command = TemplateCommand(rawValue: String(tokens[0]).lowercased())
        if command != nil {
            switch command! {
            case .loop:
                util.outputStage = .postLoop
            case .nextrec:
                util.outputStage = .loop
            case .outer:
                util.outputStage = .outer
            default:
                break
            }
        }
    }
    
    
    /// Add another token to the list
    ///
    /// - Parameters:
    ///   - start: Index pointing to the start of the token.
    ///   - end: Index pointing to the end of the token.
    func addToken(start: String.Index, end: String.Index) {
        if start > text.startIndex && start <= end {
            let range = start..<end
            let token = text[range]
            tokens.append(token)
        }
    }
    
    /// Check the beginning of the first line and determine default command
    /// characters to use for this template.
    func setCommandCharsFromFirstLine() {
        if text.starts(with: "<?") {
            util.setCommandCharsGen2()
        }
    }
    
    /// Generate output for this template line, given the fields passed in the Note.
    ///
    /// - Parameter note: The current Note being processed.
    func generateOutput(note: Note, position: Int) {
        if command == nil {
            if !util.skippingData {
                let lineWithBreak = util.replaceVariables(str: text, note: note, position: position)
                util.writeOutput(lineWithBreak: lineWithBreak)
            }
        } else {
            processCommand(note: note, position: position)
        }
    }
    
    /// Process a Template Command Line
    func processCommand(note: Note, position: Int) {
        switch command! {
        case .allFields:
            processAllFieldsCommand(note: note)
        case .clearGlobals:
            processClearGlobalsCommand()
        case .copyaddins:
            processCopyAddinsCommand(note: note)
        case .copycss:
            processCopyCssCommand()
        case .copyfile:
            processCopyFileCommand(note: note)
        case .copyimages:
            processCopyImagesCommand()
        case .delims:
            processDelimsCommand()
        case .debug:
            processDebug()
        case .definegroup:
            processDefineGroupCommand(note: note)
        case .elseCmd:
            util.anElse()
        case .endif:
            util.anotherEndIf()
        case .ifCmd:
            processIfCommand(note: note)
        case .ifendgroup:
            processIfEndGroupCommand()
        case .ifendlist:
            processIfEndListCommand()
        case .ifnewgroup:
            processIfNewGroupCommand()
        case .ifnewlist:
            processIfNewListCommand()
        case .include:
            processIncludeCommand(note: note)
        case .loop:
            break
        case .nextrec:
            break
        case .outer:
            break
        case .output:
            processOutputCommand(note: note)
        case .set:
            processSetCommand(note: note)
        case .trailing:
            processTrailingCommand()
        default:
            processDefault()
        }
    }
    
    func processAllFieldsCommand(note: Note) {
        util.allFieldsToHTML(note: note)
    }
    
    func processClearGlobalsCommand() {
        util.globals = Note(collection: util.globalsCollection)
    }
    
    func processCopyCssCommand() {
        guard !util.skippingData else { return }
        
        var copyToRelPath = "css/styles.css"
        if tokens.count > 1 {
            copyToRelPath = String(tokens[1])
        }
        
        util.copyCSS(to: copyToRelPath)
    }
    
    func processCopyAddinsCommand(note: Note) {
        guard !util.skippingData else { return }
        var copyToFolderName = NotenikConstants.addinsFolderName
        if tokens.count > 1  {
            let copyToLine = util.replaceVariables(str: String(tokens[1]), note: note)
            guard copyToLine.missingVariables == 0 else { return }
            copyToFolderName = copyToLine.line
        }
        guard !util.webRootFileName.isEmpty else { return }
        let copyToFolder = FileUtils.joinPaths(path1: util.webRootFileName.fileNameStr,
                                               path2: copyToFolderName)
        let errorMsg = util.copyAddIns(toPath: copyToFolder)
        if errorMsg != nil && !errorMsg!.isEmpty {
            util.logError("CopyAddIns error: \(errorMsg!)")
        }
    }
    
    /// Process a command to copy a file.
    func processCopyFileCommand(note: Note) {
        guard !util.skippingData else { return }
        guard tokens.count > 2 else { return }
        let copyFromLine = util.replaceVariables(str: String(tokens[1]), note: note)
        let copyToLine = util.replaceVariables(str: String(tokens[2]), note: note)
        guard copyFromLine.missingVariables == 0 && copyToLine.missingVariables == 0 else { return }
        let copyFromPath = copyFromLine.line
        let copyToPath   = copyToLine.line
        util.copyFile(fromPath: copyFromPath, toPath: copyToPath)
    }
    
    func processCopyImagesCommand() {
        guard !util.skippingData else { return }
        guard let context = util.workspace?.mkdownContext else { return }
        guard !context.localImages.isEmpty else { return }
        guard !util.dataFileName.isEmpty else { return }
        guard !util.webRootFileName.isEmpty else { return }
        for linkPair in context.localImages {
            let copyFromPath = FileUtils.joinPaths(path1: util.dataFileName.fileNameStr,
                                                   path2: linkPair.original)
            let copyToPath = FileUtils.joinPaths(path1: util.webRootFileName.fileNameStr,
                                                 path2: linkPair.modified)
            util.copyFile(fromPath: copyFromPath, toPath: copyToPath)
        }
    }
    
    /// Process a Delims (delimiters) Command
    func processDelimsCommand() {
        var i = 0
        for token in tokens {
            switch i {
            case 1:
                util.startCommand = String(token)
            case 2:
                util.endCommand = String(token)
            case 3:
                util.startVar = String(token)
            case 4:
                util.endVar = String(token)
            case 5:
                util.startMods = String(token)
            default:
                break
            }
            i += 1
        }
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "TemplateLine",
                          level: .info,
                          message: "DELIM Command Results: " + util.startCommand
                                    + " " + util.endCommand
                                    + " " + util.startVar
                                    + " " + util.endVar
                                    + " " + util.startMods)
    }
    
    /// Process a Debug Command
    func processDebug() {
        // util.debug = true
    }
    
    /// Process a Define Group Command
    func processDefineGroupCommand(note: Note) {
        util.clearIfs()
        guard tokens.count > 2 else { return }
        guard let groupNumber = validGroupNumber() else { return }
        let groupValue = util.replaceVariables(str: String(tokens[2]), note: note).line
        util.setGroup(groupNumber: groupNumber, nextValue: groupValue)
    }
    
    func processIfEndGroupCommand() {
        util.clearIfs()
        guard let groupNumber = validGroupNumber() else { return }
        util.setIfEndGroup(groupNumber)
        util.endingGroup = true
    }
    
    func processIfNewGroupCommand() {
        util.clearIfs()
        guard let groupNumber = validGroupNumber() else { return }
        util.setIfNewGroup(groupNumber)
    }
    
    func processIfEndListCommand() {
        util.clearIfs()
        guard let groupNumber = validGroupNumber() else { return }
        util.setIfEndList(groupNumber)
    }
    
    func processIfNewListCommand() {
        util.clearIfs()
        guard let groupNumber = validGroupNumber() else { return }
        util.setIfNewList(groupNumber)
    }
    
    /// Convert the second token to a valid group number or a nil value.
    func validGroupNumber() -> Int? {
        guard tokens.count > 1 else { return nil }
        let possibleGroupNumber = Int(String(tokens[1]))
        guard let groupNumber = possibleGroupNumber else { return nil }
        guard groupNumber >= 1 && groupNumber <= 10 else { return nil }
        return groupNumber - 1
    }
    
    /// Process an If Command
    func processIfCommand(note: Note) {
        
        if util.skippingData {
            util.anotherIf()
            return
        }
        
        if tokens.count < 2 {
            // If we have an if command with nothing following, then the result is false.
            util.skippingData = true
            return
        }
        
        // We have two or more operands
        let operand1 = util.replaceVariables(str: String(tokens[1]), note: note).line
        
        if tokens.count < 3 {
            // We're just testing for the presence of a variable
            if operand1 == "" || operand1 == "false" {
                util.skippingData = true
            }
            return
        }
        
        // We have three or more operands
        var value1 = ""
        var value2 = ""
        var value2Index = 2
        let operand2 = util.replaceVariables(str: String(tokens[2]), note: note).line
        var compOp = FieldComparisonOperator(operand1)
        if compOp.op == .undefined {
            compOp = FieldComparisonOperator(operand2)
            value1 = operand1
            value2Index = 3
        }
        if compOp.op == .undefined {
            Logger.shared.log(subsystem: "template", category: "TemplateLine", level: .error,
                              message: "\(operand2) is not a valid comparison operator")
            return
        }
        
        if tokens.count > 3 {
            value2 = util.replaceVariables(str: String(tokens[value2Index]), note: note).line
        }
        
        let compareResult = compOp.compare(value1, value2)
        util.skippingData = !compareResult
    }
    
    func processIncludeCommand(note: Note) {
        guard !util.skippingData else { return }
        guard tokens.count > 1 else { return }
        let includeFilePath = util.replaceVariables(str: String(tokens[1]), note: note).line
        var copyParm = ""
        if tokens.count > 2 {
            copyParm = String(tokens[2]).lowercased()
        }
        util.includeFile(filePath: includeFilePath, copyParm: copyParm, note: note)
    }
    
    /// Process an Output Command
    func processOutputCommand(note: Note) {
        guard !util.skippingData else { return }
        guard tokens.count >= 2 else { return }
        var op2 = ""
        if tokens.count >= 3 {
            op2 = String(tokens[2])
        }
        util.openOutput(filePath: util.replaceVariables(str: String(tokens[1]), note: note).line,
                        operand2: op2)
    }
    
    /// Process a Set Command
    func processSetCommand(note: Note) {
        guard !util.skippingData else { return }
        guard tokens.count >= 3 else { return }
        let globalName = util.replaceVariables(str: String(tokens[1]), note: note).line
        let opcode = String(tokens[2])
        
        var operand1 = ""
        if tokens.count >= 4 {
            operand1 = util.replaceVariables(str: String(tokens[3]), note: note).line
        }
        
        var globalField = util.globals.getField(label: globalName)
        if globalField == nil {
            let def = FieldDefinition(typeCatalog: util.typeCatalog, label: globalName)
            let val = def.fieldType.createValue(operand1)
            globalField = NoteField(def: def, value: val)
            _ = util.globals.setField(globalField!)
        }
        
        globalField!.value.operate(opcode: opcode, operand1: operand1)
        
    }
    
    /// Remove or replace the last character written out (ignoring newlines and whitespace). 
    func processTrailingCommand() {
        guard !util.skippingData else { return }
        guard tokens.count > 1 else { return }
        let trailingCharStr = String(tokens[1])
        var trailingChar: Character = " "
        if trailingCharStr.lowercased() == "comma" {
            trailingChar = ","
        } else {
            trailingChar = trailingCharStr[trailingCharStr.startIndex]
        }
        var replacement: Character? = nil
        if tokens.count > 2 {
            let replacementStr = String(tokens[2])
            replacement = replacementStr[replacementStr.startIndex]
        }
        util.replaceTrailing(char: trailingChar, with: replacement)
    }
    
    /// Process an unrecognized command.
    func processDefault() {
     
    }
    
    func display() {
        if command != nil {
            print("Cmd = \(command!)")
        }
        print("line = \(text)")
    }
}
