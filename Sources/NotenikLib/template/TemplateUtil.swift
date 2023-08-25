//
//  TemplateUtil.swift
//  Notenik
//
//  Created by Herb Bowie on 6/3/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils
import NotenikMkdown
import NotenikTextile

/// Persistent data along with utility methods.
public class TemplateUtil {
    
    let fileManager = FileManager.default
    
    var notesList = NotesList()
    var notesIndex = -1
    var note: Note?
    
    var templateURL: URL?
    var templateFileName = FileName()
    
    var dataFileName = FileName()
    
    var webRootURL: URL?
    var webRootFileName = FileName()
    
    var typeCatalog = AllTypes()
    
    var workspace: ScriptWorkspace?
    
    public var textOutURL: URL?
    var textOutFileName = FileName()
    var outputLines = ""
    var linesToOutput = ""
    var outputOpen = false
    var outputLineCount = 0
    var outputOnlyIfNew = false
    var outputFilesWritten = 0
    
    /// A relative path from the location of the output file to the
    /// root of the enclosing website.
    var relativePathToRoot: String?
    
    var lineReader:  LineReader = BigStringReader("")
    var templateOK = false
    var lineCount  = 0
    
    var startCommand = "<<"
    var endCommand   = ">>"
    var startVar     = "<<"
    var endVar       = ">>"
    var startMods    = "&"
    
    var globals: Note
    
    var outputStage = OutputStage.front
    
    var skippingData = false
    var endingGroup = false
    var ifBypassDepth = 0
    
    var minorGroup = -1
    var groupValue: [String] = []
    var endGroup:   [Bool]   = []
    var newGroup:   [Bool]   = []
    var endList:    [Bool]   = []
    var newList:    [Bool]   = []
    
    var lastSeparator: Character = " "
    var separatorPending = false
    
    let xmlConverter = StringConverter()
    let emailSingleQuoteConverter = StringConverter()
    let noBreakConverter = StringConverter()
    let markedup = Markedup(format: .htmlFragment)
    
    var parms = DisplayParms()
    var mkdownOptions = MkdownOptions()
    
    var noteFieldsToHTML: NoteFieldsToHTML
    
    var io: NotenikIO?
    
    var bodyHTML: String?
    var minutesToRead: MinutesToReadValue?
    
    var wikiStyle: Character = "0"
    
    var lastCopyToURL: URL?
    
    /// Initialize things.
    public init() {
        let globalsCollection = NoteCollection()
        globals = Note(collection: globalsCollection)
        xmlConverter.addXML()
        emailSingleQuoteConverter.addEmailQuotes()
        noBreakConverter.addNoBreaks()
        parms = DisplayParms()
        if DisplayPrefs.shared.displayCSS == nil {
            parms.cssString = ""
        } else {
            parms.cssString = DisplayPrefs.shared.displayCSS!
        }
        noteFieldsToHTML = NoteFieldsToHTML()
        resetGroupValues()
        resetGroupBreaks()
    }
    
    func setWebRoot(filePath: String) {
        if filePath.count > 0 {
            webRootURL = URL(fileURLWithPath: filePath)
            webRootFileName = FileName(filePath)
        }
    }
    
    func setWorkspace(_ workspace: ScriptWorkspace) {
        self.workspace = workspace
        self.typeCatalog = workspace.typeCatalog
    }
    
    func setCommandCharsGen2() {
        startCommand = "<?"
        endCommand   = "?>"
        startVar     = "=$"
        endVar       = "$="
        startMods    = "&"
    }
    
    /// Open a new template file.
    ///
    /// - Parameter templateURL: The location of the template file.
    /// - Returns: True if opened ok, false if errors. 
    func openTemplate(templateURL: URL) -> Bool {
        
        resetGroupValues()
        resetGroupBreaks()
        
        self.templateURL = templateURL
        templateFileName = FileName(templateURL)
        
        lineCount = 0
        do {
            let templateContents = try String(contentsOf: templateURL, encoding: .utf8)
            lineReader = BigStringReader(templateContents)
            lineReader.open()
            templateOK = true
        } catch {
            logError("Error reading Template from \(templateURL)")
            logError("Template Read Error: \(error)")
            templateOK = false
        }
        return templateOK
    }
    
    /// Open a template supplied as a string.
    /// - Parameter templateContents: The contents of a previously-read template file.
    func openTemplate(templateContents: String) {
        resetGroupValues()
        resetGroupBreaks()
        
        templateURL = nil
        templateFileName = FileName()
        lineCount = 0
        lineReader = BigStringReader(templateContents)
        lineReader.open()
        templateOK = true
    }
    
    /// Return the next template line, if there are any left.
    ///
    /// - Returns: The next template line, or nil at end.
    func nextTemplateLine() -> TemplateLine? {
        let nextLine = lineReader.readLine()
        if nextLine == nil {
            return nil
        } else {
            lineCount += 1
            return TemplateLine(text: nextLine!, util: self)
        }
    }
    
    /// Close the template. 
    func closeTemplate() {
        lineReader.close()
        logInfo("\(lineCount) lines read from template file")
    }
    
    /// Open an output file, as requested from an open command.
    ///
    /// - Parameter filePath: The complete path to the desired output file.
    func openOutput(filePath: String, operand2: String = "") {
        closeOutput()

        let absFilePath = templateFileName.resolveRelative(path: filePath)
        textOutURL = URL(fileURLWithPath: absFilePath)
        textOutFileName = FileName(absFilePath)
    
        // If we have a web root, then figure out the relative path up to it
        // for possible later use.
        relativePathToRoot = ""
        if workspace != nil && workspace!.webRootPath.count > 0 {
            webRootURL = URL(fileURLWithPath: workspace!.webRootPath)
            webRootFileName = FileName(workspace!.webRootPath)
        }
        if webRootURL != nil && textOutFileName.isBeneath(webRootFileName) {
            var folderCount = textOutFileName.folders.count
            while folderCount > webRootFileName.folders.count {
                relativePathToRoot!.append("../")
                folderCount -= 1
            }
        } else {
            relativePathToRoot = nil
        }

        outputOpen = true
        
        outputOnlyIfNew = (StringUtils.toCommon(operand2) == "ifnew")
    }
    
    /// Copy a file from one location to another. 
    func copyFile(fromPath: String, toPath: String) {
        let absFromPath = templateFileName.resolveRelative(path: fromPath)
        let fromResource = ResourceFileSys(folderPath: absFromPath, fileName: "", type: .attachment)
        guard fromResource.isAvailable else {
            logError("Could not find a file to copy at: \(fromResource.normalPath)")
            return
        }
        
        let absToPath = templateFileName.resolveRelative(path: toPath)
        
        let toURL = URL(fileURLWithPath: absToPath)
        let toFolder = toURL.deletingLastPathComponent()
        let toFolderResource = ResourceFileSys(folderPath: toFolder.path, fileName: "")
        _ = toFolderResource.ensureExistence()
        
        let toResource = ResourceFileSys(folderPath: absToPath, fileName: "", type: .attachment)
        if toResource.exists {
            _ = toResource.remove()
        }
        let ok = fromResource.copyTo(to: toResource)
        if !ok {
            logError("Could not complete copyfile command")
        }
        lastCopyToURL = toURL
    }
    
    func allFieldsToHTML(note: Note) {
        
        let originalFormat = parms.format
        parms.format = .htmlFragment
        parms.wikiLinks.resetToDefaults()
        let fields = noteFieldsToHTML.fieldsToHTML(note,
                                             io: io,
                                             parms: parms,
                                             topOfPage: "",
                                             imageWithinPage: "",
                                             bodyHTML: bodyHTML,
                                             minutesToRead: minutesToRead)
        parms.format = originalFormat
        outputLines.append(fields)
    }
    
    /// Include another file into this one.
    ///
    /// - Parameter filePath: The complete path to the file to be included.
    func includeFile(filePath: String, copyParm: String, note: Note) {
        
        let absFilePath = templateFileName.resolveRelative(path: filePath)
        
        guard fileManager.fileExists(atPath: absFilePath) else {
            logError("Could not find an include file at \(absFilePath)")
            return
        }
        
        guard fileManager.isReadableFile(atPath: absFilePath) else {
            logError("Could not read the include file at \(absFilePath)")
            return
        }
        
        let includeURL = URL(fileURLWithPath: absFilePath)
        var includeContents = ""
        
        do {
            includeContents = try String(contentsOf: includeURL, encoding: .utf8)
        } catch {
            logError("Error reading Include file from \(includeURL)")
            return
        }
        
        // logInfo("Including file \(absFilePath)")
        
        let inFileName = FileName(absFilePath)
        let inType = idealizeExt(inFileName.ext)
        let outType = idealizeExt(textOutFileName.ext)
        
        if inType == outType || copyParm == "copy" {
            copyInclude(includeContents: includeContents, note: note)
        } else if inType == "markdown" && outType == "html" {
            copyMarkdownToHTML(includeContents: includeContents, note: note)
        } else if inType == "textile" && outType == "html" {
            copyTextileToHTML(includeContents: includeContents, note: note)
        } else {
            copyInclude(includeContents: includeContents, note: note)
        }
    }
    
    func copyInclude(includeContents: String, note: Note) {
        let includeReader = BigStringReader(includeContents)
        includeReader.open()
        var includeLine = includeReader.readLine()
        while includeLine != nil {
            let includeLineWithBreak = replaceVariables(str: includeLine!, note: note)
            writeOutput(lineWithBreak: includeLineWithBreak)
            includeLine = includeReader.readLine()
        }
        includeReader.close()
    }
    
    func copyMarkdownToHTML(includeContents: String, note: Note) {
        let html = convertMarkdownToHTML(includeContents)
        let reader = BigStringReader(html)
        reader.open()
        var line = reader.readLine()
        while line != nil {
            let lineWithBreak = replaceVariables(str: line!, note: note)
            writeOutput(lineWithBreak: lineWithBreak)
            line = reader.readLine()
        }
    }
    
    func copyTextileToHTML(includeContents: String, note: Note) {
        let html = convertTextileToHTML(includeContents)
        let reader = BigStringReader(html)
        reader.open()
        var line = reader.readLine()
        while line != nil {
            let lineWithBreak = replaceVariables(str: line!, note: note)
            writeOutput(lineWithBreak: lineWithBreak)
            line = reader.readLine()
        }
    }
    
    func idealizeExt(_ extAny: String) -> String {
        let ext = extAny.lowercased()
        if ext == "md" || ext == "mkdown" || ext == "markdown" || ext == "txt" {
            return "markdown"
        } else if ext == "html" || ext == "htm" {
            return "html"
        } else if ext == "textile" {
            return "textile"
        } else {
            return ext
        }
    }
    
    /// Write one output line, with an optional trailing line break.
    func writeOutput(lineWithBreak: LineWithBreak) {
        outputLines.append(lineWithBreak.line)
        if lineWithBreak.lineBreak {
            outputLines.append("\n")
            outputLineCount += 1
        }
    }
    
    /// Replace a trailing character with another character, or with nothing at all.
    /// - Parameters:
    ///   - char: The character to be replaced, if found at end of output lines.
    ///   - with: The character to use as a replacement. If nil or blank, then the character
    ///           we'r'e looking for, if found in a trailing position, will simply be removed. 
    func replaceTrailing(char: Character, with: Character? = nil) {
        var index = outputLines.endIndex
        var done = (index <= outputLines.startIndex)
        while !done {
            index = outputLines.index(before: index)
            if index <= outputLines.startIndex {
                done = true
            } else {
                let c = outputLines[index]
                if c.isNewline || c.isWhitespace {
                    // Ignore and keep going
                } else if c == char {
                    done = true
                    _ = outputLines.remove(at: index)
                    if with != nil && !with!.isWhitespace {
                        outputLines.insert(with!, at: index)
                    }
                } else {
                    done = true
                }
            } // end if we  have another char to inspect
        } // end while looking for trailing char
    } // end func
    
    /// Close the output file, sending it to the appropriate output. 
    func closeOutput() {
        if let consumer = workspace?.templateOutputConsumer {
            consumer.consumeTemplateOutput(outputLines)
        } else if outputOpen && textOutURL != nil {
            var skipWrite = false
            if outputOnlyIfNew {
                if FileManager.default.fileExists(atPath: textOutURL!.path) {
                    skipWrite = true
                }
            }
            if !skipWrite {
                let written = FileUtils.saveToDisk(strToWrite: outputLines,
                                     outputURL: textOutURL!,
                                     createDirectories: true,
                                     checkForChanges: true)
                if written {
                    outputFilesWritten += 1
                }
            }
        } else {
            linesToOutput = outputLines
        }
        outputLines = ""
        outputLineCount = 0
        outputOpen = false
    }
    
    /// Clear all pending conditionals. This method should be called for
    /// commands that should never be found within the scope of a
    /// conditional block.
    func clearIfs() {
        ifBypassDepth = 0
        skippingData = false
    }
    
    func anotherIf() {
        ifBypassDepth += 1
    }
    
    func anElse() {
        if skippingData && ifBypassDepth > 0 {
            // If we bypassed the If, then bypass the Else as well,
            // But we're still looking for an EndIf
        } else {
            let skippingBeforeElse = skippingData
            skippingData = !skippingBeforeElse
        }
    }
    
    func anotherEndIf() {
        if ifBypassDepth > 0 {
            ifBypassDepth -= 1
        } else {
            skippingData = false
        }
    }
    
    /// Blank out all ten possible group values.
    func resetGroupValues() {
        var index = 0
        while index < 10 {
            if index < groupValue.count {
                groupValue[index] = ""
            } else {
                groupValue.append("")
            }
            index += 1
        }
    }
    
    /// Reset all the group breaks.
    func resetGroupBreaks() {
        var index = 0
        while index < 10 {
            if index < endGroup.count {
                endGroup[index] = false
                newGroup[index] = false
                endList[index] = false
                newList[index] = false
            } else {
                endGroup.append(false)
                newGroup.append(false)
                endList.append(false)
                newList.append(false)
            }
            index += 1
        }
    }
    
    /// We have another value for a defined group we're watching.
    func setGroup(groupNumber: Int, nextValue: String) {
        
        if groupNumber > minorGroup {
            minorGroup = groupNumber
        }
        guard nextValue != groupValue[groupNumber] else { return }
        
        setEndGroupsTrue(majorGroup: groupNumber)
        
        if nextValue.count > 0 {
            newGroup[groupNumber] = true
            if groupValue[groupNumber].count == 0 {
                newList[groupNumber] = true
            }
        } else {
            endList[groupNumber] = true
        }
        
        var index = groupNumber + 1
        while index <= minorGroup {
            if groupValue[index].count > 0 {
                endList[index] = true
                groupValue[index] = ""
            }
            index += 1
        }
        
        groupValue[groupNumber] = nextValue
    }
    
    /// End all groups after last Note has been processed. 
    func endAllGroups() {
        setEndGroupsTrue(majorGroup: 0)
    }
    
    /// Indicate the end of a group (and its sub-groups)
    func setEndGroupsTrue(majorGroup: Int) {
        var index = majorGroup
        while index <= minorGroup {
            if groupValue[index].count > 0 {
                endGroup[index] = true
            }
            index += 1
        }
    }
    
    /// Has the group ended?
    func setIfEndGroup(_ groupNumber: Int) {
        skippingData = !endGroup[groupNumber]
    }
    
    /// Has a new group started?
    func setIfNewGroup(_ groupNumber: Int) {
        skippingData = !newGroup[groupNumber]
    }
    
    /// Has the list ended?
    func setIfEndList(_ groupNumber: Int) {
        skippingData = !endList[groupNumber]
    }
    
    /// Is a new list starting?
    func setIfNewList(_ groupNumber: Int) {
        skippingData = !newList[groupNumber]
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Replace and Format Variables.
    //
    // -----------------------------------------------------------
    
    /// Replace any variables in the passed string with their current Note values.
    ///
    /// - Parameters:
    ///   - str: The string possibly containing variables.
    ///   - note: A Note containing data fields.
    /// - Returns: A line with variables replaced, with or without an ending line break.
    func replaceVariables(str: String, note: Note, position: Int = -1) -> LineWithBreak {
        
        //
        // Look for variable name and any variable modifiers,
        // appending appropriate values to out line as we go.
        //
        let out = LineWithBreak()
        
        var lookingForStartVar = true
        var lookingForStartMods = false
        var lookingForEndVar = false
        
        var startPastDelim = str.startIndex
        var endPastDelim = str.startIndex
        var varName = ""
        var mods = ""
        var i = str.startIndex
        while i < str.endIndex {
            let char = str[i]
            if lookingForStartVar && str.indexedEquals(index: i, str2: startVar) {
                startPastDelim = str.index(i, offsetBy: startVar.count)
                i = startPastDelim
                lookingForStartVar = false
                lookingForStartMods = true
                lookingForEndVar = true
                varName = ""
                mods = ""
            } else if lookingForStartMods && str.indexedEquals(index: i, str2: startMods) {
                mods = ""
                i = str.index(i, offsetBy: startMods.count)
                lookingForStartMods = false
            } else if lookingForEndVar {
                if str.indexedEquals(index: i, str2: endVar) {
                    endPastDelim = str.index(i, offsetBy: endVar.count)
                    // Append variable and modifiers, after replacement and formatting.
                    appendVar(toLine: out, varName: varName, mods: mods, note: note, position: position)
                    i = endPastDelim
                    lookingForEndVar = false
                    lookingForStartMods = false
                    lookingForStartVar = true
                } else if lookingForStartMods {
                    varName.append(char)
                    i = str.index(i, offsetBy: 1)
                } else {
                    mods.append(char)
                    i = str.index(i, offsetBy: 1)
                }
            } else {
                out.line.append(char)
                i = str.index(i, offsetBy: 1)
            }
        }
        return out
    }
    
    /// Given a variable name, and possibly some modifiers, look for a corresponding value
    /// and then append it, with any requested modifications, to the output line being built.
    ///
    /// - Parameters:
    ///   - toLine: The output line we're working on.
    ///   - varName: The name of the variable we're looking for.
    ///   - mods: Any modifier characters supplied by the user.
    ///   - note: A set of fields supplying values to be used.
    func appendVar(toLine: LineWithBreak, varName: String, mods: String, note: Note, position: Int = -1) {
        
        let varNameCommon = StringUtils.toCommon(varName)
        var replacementValue: String?
        replacementValue = replaceVarWithValue(inLine: toLine, varName: varNameCommon, note: note, position: position)
        
        if replacementValue != nil {
            replacementValue = applyModifiers(varNameCommon: varNameCommon,
                                              note: note,
                                              replacementValue: replacementValue!,
                                              mods: mods)
            toLine.line.append(replacementValue!)
        }
        
    }
    
    /// Apply the modifers to the string.
    ///
    /// - Parameters:
    ///   - replacementValue: The value to be modified.
    ///   - mods: A string containing zero or more modifiers.
    /// - Returns: The modified value.
    func applyModifiers(varNameCommon: String,
                        note: Note,
                        replacementValue: String,
                        mods: String) -> String {
        
        var modifiedValue = replacementValue
        
        var number = 0
        var keepCharsOnRight = false
        
        var wordCaseMods = ["u", "u", "l"]
        var wordCaseIndex = 0
        var wordDelimiter = ""
        var wordDemarcationPending = false
        
        var varyStage = 0
        var varyDelim: Character = " "
        var varyFrom = ""
        var varyTo = ""
        
        var linkedTags = false
        var linkedTagsPath = ""
        var linkedTagsPathDone = false
        var linkedTagsClass = ""
        
        var zStage = 0
        var zPrefix = ""
        var zSuffix = ""
        var zClass = ""
        
        var formatFileName = false
        var readableFileName = false
        
        var summarizePending = false
        
        var formatString = ""
        
        wikiStyle = "0"
        
        // See what modifiers we have
        var i = mods.startIndex
        
        while i < mods.endIndex {
            let char = mods[i]
            let charLower = char.lowercased()
            let nextChar = mods.charAtOffset(index: i, offsetBy: 1)
            let nextCharLower = nextChar.lowercased()
            var separator: Character = " "
            
            var inc = 1
            if formatString.count > 0 {
                formatString.append(char)
            } else if varyStage > 0 && varyStage < 4 {
                if varyStage == 1 {
                    varyDelim = char
                    varyStage = 2
                } else if varyStage == 2 && char != varyDelim {
                    varyFrom.append(char)
                } else if varyStage == 2 && char == varyDelim {
                    varyStage = 3
                } else if varyStage == 3 && char != varyDelim {
                    varyTo.append(char)
                } else if varyStage == 3 && char == varyDelim {
                    varyStage = 4
                }
            } else if linkedTags {
                if char == ";" {
                    linkedTagsPathDone = true
                } else if linkedTagsPathDone {
                    linkedTagsClass.append(char)
                } else {
                    linkedTagsPath.append(char)
                }
            } else if zStage > 0 && zStage < 4 {
                if char == ";" {
                    zStage += 1
                } else if zStage == 1 {
                    zPrefix.append(char)
                } else if zStage == 2 {
                    zSuffix.append(char)
                } else if zStage == 3 {
                    zClass.append(char)
                }
            } else if wordDemarcationPending {
                if charLower == "u" || charLower == "l" || charLower == "a" {
                    if wordCaseIndex < 3 {
                        wordCaseMods[wordCaseIndex] = charLower
                        wordCaseIndex += 1
                    }
                } else {
                    wordDelimiter.append(char)
                }
            } else if char == "_" {
                modifiedValue = StringUtils.underscoresForSpaces(modifiedValue)
            } else if char == ">" {
                let (_, label) = StringUtils.splitNumberAndLabel(str: modifiedValue)
                modifiedValue = label
            } else if char == "/" {
                let website = StringUtils.websiteFromLink(str: modifiedValue)
                modifiedValue = website
            } else if char == "a" && (nextChar == "1" || nextChar == "2" || nextChar == "3") {
                let authorValue = AuthorValue(modifiedValue)
                switch nextChar {
                case "1":
                    modifiedValue = authorValue.lastName
                case "2":
                    modifiedValue = authorValue.lastNameFirst
                case "3":
                    modifiedValue = authorValue.firstNameFirst
                default:
                    break
                }
                inc = 2
            } else if charLower == "a" {
                formatString.append(char)
            } else if charLower == "b" {
                let fileName = FileName(modifiedValue)
                modifiedValue = fileName.base
            } else if charLower == "c" {
                wordDemarcationPending = true
            } else if char == "d" {
                formatString.append(char)
            } else if char == "E" {
                formatString.append(char)
            } else if charLower == "f" {
                formatFileName = true
            } else if charLower == "g" {
                linkedTags = true
            } else if charLower == "h" {
                let markedUp = Markedup(format: .htmlFragment)
                markedUp.parse(text: modifiedValue, startingLastCharWasWhiteSpace: true)
                modifiedValue = String(describing: markedUp)
            } else if charLower == "i" {
                modifiedValue = StringUtils.toCommon(modifiedValue)
            } else if char == "k" {
                formatString.append("h")
            } else if char == "K" {
                formatString.append("H")
            } else if charLower == "l" && nextCharLower != "i" {
                modifiedValue = modifiedValue.lowercased()
            } else if charLower == "j" {
                modifiedValue = StringUtils.convertLinks(modifiedValue)
            } else if charLower == "l" && nextCharLower == "i" {
                modifiedValue = StringUtils.toLowerFirstChar(modifiedValue)
                inc = 2
            } else if charLower == "m" {
                formatString.append(char)
            } else if charLower == "n" {
                modifiedValue = noBreakConverter.convert(from: modifiedValue)
            } else if charLower == "o" {
                if varNameCommon == NotenikConstants.bodyCommon && bodyHTML != nil {
                    modifiedValue = bodyHTML!
                } else if varNameCommon == NotenikConstants.wikilinksCommon {
                    modifiedValue = convertWikilinksToHTML(modifiedValue, backLinks: false)
                } else if varNameCommon == NotenikConstants.backlinksCommon {
                    modifiedValue = convertWikilinksToHTML(modifiedValue, backLinks: true)
                } else {
                    modifiedValue = convertMarkdownToHTML(modifiedValue)
                }
                if nextChar == "-" {
                    modifiedValue = removeParagraphTags(modifiedValue)
                    inc = 2
                }
            } else if charLower == "p" {
                modifiedValue = StringUtils.purifyPunctuation(modifiedValue)
            } else if charLower == "q" {
                modifiedValue = StringUtils.encaseInQuotesAsNeeded(modifiedValue)
            } else if charLower == "r" {
                if formatFileName {
                    readableFileName = true
                } else {
                    keepCharsOnRight = true
                }
            } else if charLower == "s" {
                if nextChar.isWholeNumber {
                    summarizePending = true
                } else {
                    modifiedValue = StringUtils.summarize(modifiedValue)
                }
            } else if charLower == "t" {
                let htmlConverter = HTMLtoMarkdown(html: modifiedValue)
                modifiedValue = htmlConverter.toMarkdown()
            } else if charLower == "u" && nextCharLower != "i" {
                modifiedValue = modifiedValue.uppercased()
            } else if charLower == "u" && nextCharLower == "i" {
                modifiedValue = StringUtils.toUpperFirstChar(modifiedValue)
                inc = 2
            } else if charLower == "v" {
                varyStage = 1
            } else if charLower == "w" {
                wikiStyle = nextChar
                inc = 2
            } else if charLower == "x" {
                modifiedValue = xmlConverter.convert(from: modifiedValue)
            } else if char == "y" {
                formatString.append(char)
            } else if char == "z" {
                zStage = 1
            } else if charLower == "'" {
                modifiedValue = emailSingleQuoteConverter.convert(from: modifiedValue)
            } else if char == "\\" {
                modifiedValue = StringUtils.prepHTMLforJSON(modifiedValue)
            } else if char.isWholeNumber {
                number = (number * 10) + char.wholeNumberValue!
                if !nextChar.isWholeNumber {
                    if summarizePending {
                        modifiedValue = StringUtils.summarize(modifiedValue, max: number)
                        summarizePending = false
                    } else {
                        modifiedValue = StringUtils.truncateOrPad(modifiedValue, toLength: number, keepOnRight: keepCharsOnRight)
                    }
                }
            } else if char.isPunctuation {
                separator = char
                modifiedValue = separateVariables(from: modifiedValue, separator: char)
            }
            
            if wordDemarcationPending {
                modifiedValue = StringUtils.wordDemarcation(modifiedValue, caseMods: wordCaseMods, delimiter: wordDelimiter)
            }
            
            if separator == " " {
                lastSeparator = " "
                separatorPending = false
            }
            
            i = mods.index(i, offsetBy: inc)
        }
        
        if readableFileName {
            modifiedValue = StringUtils.toReadableFilename(modifiedValue)
        } else if formatFileName {
            modifiedValue = StringUtils.toCommonFileName(modifiedValue)
        }
        
        if varyStage > 0 && varyFrom.count > 0 {
            modifiedValue = modifiedValue.replacingOccurrences(of: varyFrom, with: varyTo)
        }
        
        if linkedTags {
            var relative = ""
            if relativePathToRoot != nil {
                relative = relativePathToRoot!
            }
            let tags = TagsValue(modifiedValue)
            if (linkedTagsPath.count > 0
                && !linkedTagsPath.hasSuffix("/")
                && !linkedTagsPath.hasSuffix(endVar)) {
                linkedTagsPath.append("/")
            }
            modifiedValue = tags.getLinkedTags(parent: relative + linkedTagsPath, htmlClass: linkedTagsClass)
        }
        
        if zStage > 0 {
            modifiedValue = zTags(tagsString: modifiedValue, prefix: zPrefix, suffix: zSuffix, htmlClass: zClass)
        }
        
        if formatString.count > 0 {
            if varNameCommon == "today" && (formatString.count > 10 || formatString.contains("T")) {
                let today = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                modifiedValue = formatter.string(from: today)
            } else {
                let date = DateValue(modifiedValue)
                modifiedValue = date.format(with: formatString)
            }
        }
        
        return modifiedValue
    }
    
    func zTags(tagsString: String, prefix: String, suffix: String, htmlClass: String)-> String {
        var html = ""
        let tags = TagsValue(tagsString)
        for tag in tags.tags {
            if html.count > 0 { // }&& htmlClass.count == 0 {
                html.append(", ")
            }
            var str = ""
            var link = ""
            for level in tag.levels {
                if str.count > 0 {
                    str.append(".")
                    link.append("-")
                }
                str.append(level.forDisplay)
                link.append(StringUtils.toCommonFileName(level.forDisplay))
            }
            var klass = ""
            if htmlClass.count > 0 {
                klass = " class='" + htmlClass + "'"
            }
            html.append("<a\(klass) href='" + prefix + link + suffix + "' rel='tag'>" + str + "</a>")
        }
        return html
    }
    
    func separateVariables(from: String, separator: Character) -> String {
        guard from.count > 0 else { return from }
        var out = ""
        if separatorPending && separator == lastSeparator {
            out.append(separator)
            if separator != "/" && separator != "\\" {
                out.append(" ")
            }
        }
        out.append(from)
        separatorPending = true
        lastSeparator = separator
        return out
    }
    
    /// Convert Markdown to HTML
    func convertMarkdownToHTML(_ markdown: String) -> String {
        switch wikiStyle {
        case "1":
            if workspace != nil {
                if workspace!.mkdownContext != nil {
                    workspace!.mkdownContext!.displayParms.wikiLinks.prefix = ""
                    workspace!.mkdownContext!.displayParms.wikiLinks.format = .fileName
                    workspace!.mkdownContext!.displayParms.wikiLinks.suffix = ".html"
                }
                mkdownOptions.shortID = workspace!.collection.shortID
                mkdownOptions.extLinksOpenInNewWindows = workspace!.collection.extLinksOpenInNewWindows
            }
            let mkdown = MkdownParser(markdown, options: mkdownOptions)
            mkdown.setWikiLinkFormatting(prefix: "", format: .fileName, suffix: ".html", context: workspace?.mkdownContext)
            mkdown.parse()
            return mkdown.html
        case "2":
            if workspace != nil {
                mkdownOptions.shortID = workspace!.collection.shortID
                mkdownOptions.extLinksOpenInNewWindows = workspace!.collection.extLinksOpenInNewWindows
            }
            let mkdown = MkdownParser(markdown, options: mkdownOptions)
            mkdown.setWikiLinkFormatting(prefix: "#", format: .fileName, suffix: "", context: workspace?.mkdownContext)
            mkdown.parse()
            return mkdown.html
        default:
            if workspace != nil {
                mkdownOptions.shortID = workspace!.collection.shortID
                mkdownOptions.extLinksOpenInNewWindows = workspace!.collection.extLinksOpenInNewWindows
            }
            let mkdown = Markdown()
            return mkdown.parse(markdown: markdown, options: mkdownOptions, context: workspace?.mkdownContext)
        }
    }
    
    func convertWikilinksToHTML(_ linkStr: String, backLinks: Bool = false) -> String {
        
        var pointers = WikiLinkTargetList()
        var title = ""
        if backLinks {
            let links = BacklinkValue(linkStr)
            pointers = links.notePointers
            title = "Back Links"
        } else {
            let links = WikilinkValue(linkStr)
            pointers = links.notePointers
            title = "Wiki Links"
        }
        guard pointers.count > 0 else { return linkStr }
        
        switch wikiStyle {
        case "1":
            parms.wikiLinks.prefix = ""
            parms.wikiLinks.format = .fileName
            parms.wikiLinks.suffix = ".html"
        case "2":
            parms.wikiLinks.prefix = "#"
            parms.wikiLinks.format = .fileName
            parms.wikiLinks.suffix = ""
        default:
            parms.wikiLinks.format = .common
            parms.wikiLinks.prefix = "https://ntnk.app/"
            parms.wikiLinks.suffix = ""
        }
        
        let linksHTML = Markedup(format: .htmlFragment)
        linksHTML.startDetails(summary: title)
        linksHTML.startUnorderedList(klass: nil)
        for pointer in pointers {
            linksHTML.startListItem()
            linksHTML.link(text: pointer.pathSlashItem, path: parms.wikiLinks.assembleWikiLink(target: pointer))
            linksHTML.finishListItem()
        }
        linksHTML.finishUnorderedList()
        linksHTML.finishDetails()
        return linksHTML.code
    }
    
    /// Convert Textile to HTML
    func convertTextileToHTML(_ textile: String) -> String {
        let textiler = Textiler()
        return textiler.toHTML(textile: textile)
    }
    
    /// Remove leading and trailing paragraph tags.
    func removeParagraphTags(_ html: String) -> String {
        guard html.count > 0 else { return html }
        var start = html.startIndex
        var end = html.endIndex
        if html.hasPrefix("<p>") || html.hasPrefix("<P>") {
            start = html.index(html.startIndex, offsetBy: 3)
        }
        var j = html.index(before: html.endIndex)
        while (j > start &&
            (StringUtils.charAt(index: j, str: html).isWhitespace ||
                StringUtils.charAt(index: j, str: html).isNewline)) {
                    j = html.index(before: j)
        }
        let i = html.index(j, offsetBy: -3)
        if i >= start {
            let possibleEndPara = html[i...j]
            if possibleEndPara == "</p>" || possibleEndPara == "</P>" {
                end = i
            }
        }
        if html.hasSuffix("</p>") || html.hasSuffix("</P>") {
            end = html.index(html.endIndex, offsetBy: -4)
        }
        return String(html[start..<end])
    }
    
    /// Replace a variable name with the corresponding value.
    /// - Parameters:
    ///   - inLine: The output line as it exists so far.
    ///   - varName: The name of the variable.
    ///   - note: The Note supplying the values.
    /// - Returns: The output line being built, with the variable name replaced.
    func replaceVarWithValue(inLine: LineWithBreak, varName: String, note: Note, position: Int = -1) -> String? {

        var value: String?
        
        value = replaceSpecialVarWithValue(inLine: inLine, varNameCommon: varName)
        
        if value == nil {
            value = replaceVarWithValue(varName: varName, fromNote: globals)
        }
        
        if value == nil {
            value = replaceExtendedVarWithValue(varName: varName, fromNote: note, position: position)
        }
        
        if value == nil && varName != "relative" {
            logError("Template Variable named \(varName) could not be found")
        }
        
        return value
    }
    
    func replaceSpecialVarWithValue(inLine: LineWithBreak, varNameCommon: String) -> String? {
        switch varNameCommon {
        case "nobr":
            inLine.lineBreak = false
            return ""
        case "templatefilename":
            return templateFileName.fileName
        case "templateparent":
            return templateFileName.path
        case "datafilename":
            return dataFileName.fileName
        case "datafilebasename":
            return dataFileName.base
        case "dateparent":
            return dataFileName.path
        case "exportpath":
            if workspace == nil {
                return ""
            } else {
                return workspace!.exportPath
            }
        case "parentfolder":
            return dataFileName.folder
        case "today":
            return DateUtils.shared.ymdToday
        case NotenikConstants.minutesToReadCommon:
            if minutesToRead != nil {
                return String(describing: minutesToRead)
            } else {
                return nil
            }
        case "relative":
            if relativePathToRoot == nil {
                return nil
            } else {
                return relativePathToRoot
            }
        case "displaycss":
            return displayCSS
        default:
            return nil
        }
    }
    
    var displayCSS: String {
        let parms = DisplayParms()
        guard let collection = workspace?.collection else { return "" }
        parms.setCSS(useFirst: collection.displayCSS,
                     useSecond: DisplayPrefs.shared.displayCSS)
        var defaultCSS = parms.cssString
        defaultCSS.append("\nimg { max-width: 100%; border: 4px solid gray; }")
        defaultCSS.append("\nbody { max-width: 33em; margin: 0 auto; float: none; }")
        return defaultCSS
    }
    
    /// Look for a replacement value for the passed field label.
    ///
    /// - Parameters:
    ///   - varName: The desire field label (aka variable name)
    ///   - fromNote: The Note instance containing the field values to be used.
    /// - Returns: The replacement value, if the variable name was found, otherwise nil.
    func replaceExtendedVarWithValue(varName: String, fromNote: Note, position: Int = -1) -> String? {
        
        // First check for various derived values
        
        switch varName {
            
        case NotenikConstants.imageSlugCommon:
            let slug = genImageSlug(fromNote: fromNote)
            if !slug.isEmpty { return slug }
            
        case NotenikConstants.imageNameShortCommon:
            let name = genImageNameShort(fromNote: fromNote)
            if !name.isEmpty { return name }
            
        case NotenikConstants.workRightsSlugCommon:
            let slug = genWorkRightsSlug(fromNote: fromNote)
            if !slug.isEmpty { return slug }
            
        case NotenikConstants.authorWorkSlugCommon:
            let slug = genAuthorWorkSlug(fromNote: fromNote)
            if !slug.isEmpty { return slug }
            
        case NotenikConstants.theWorkTypeSlugCommon:
            if let workTypeField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTypeCommon) {
                if let workType = workTypeField.value as? WorkTypeValue {
                    return workType.theType
                }
            }
            return ""
            
        case NotenikConstants.majorWorkCommon:
            var isMajor = true
            if let workTypeField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTypeCommon) {
                if let workType = workTypeField.value as? WorkTypeValue {
                    isMajor = workType.isMajor
                }
            }
            if isMajor {
                return "true"
            } else {
                return "false"
            }
            
        case NotenikConstants.knownWorkTitleCommon:
            if let workTitleField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTitleCommon) {
                let workTitle = workTitleField.value.value
                if workTitle == "unknown" {
                    return ""
                } else {
                    return workTitle
                }
            }
            
        case NotenikConstants.parentSlugCommon:
            return genParentSlug(fromNote: fromNote, position: position)
            
        case NotenikConstants.nextSlugCommon:
            return genNextSlug(fromNote: fromNote, position: position)
            
        case NotenikConstants.childrenSlugCommon:
            return genChildrenSlug(fromNote: fromNote, position: position)
            
        case NotenikConstants.titleDisplaySlugCommon:
            return genTitleDisplaySlug(fromNote: fromNote)
            
        default:
            break
        }
        
        return replaceVarWithValue(varName: varName, fromNote: fromNote)
    }
    
    /// Look for a replacement value for the passed field label.
    ///
    /// - Parameters:
    ///   - varName: The desire field label (aka variable name)
    ///   - fromNote: The Note instance containing the field values to be used.
    /// - Returns: The replacement value, if the variable name was found, otherwise nil.
    func replaceVarWithValue(varName: String, fromNote: Note) -> String? {
        
        // If not one of the derived values, then just look for a Note field with the
        // supplied variable name.
        let field = FieldGrabber.getField(note: fromNote, label: varName)
        if field == nil {
            return nil
        } else {
            if varName == NotenikConstants.imageNameCommon {
                print("Trying to replace image name with file name")
                print("  - Note titled \(fromNote.title.value)")
                print("  - Note has \(fromNote.attachments.count) attachments")
                print("  - Image Name value is '\(field!.value.value)'")
                for attachment in fromNote.attachments {
                    attachment.display()
                    if attachment.suffix.lowercased() == field!.value.value.lowercased() {
                        return attachment.fullName
                    }
                }
                print("  - Image Name Not Found!!")
            }
            return field!.value.value
        }
    }
    
    func genTitleDisplaySlug(fromNote: Note) -> String {
        
        let markedUp = Markedup(format: .htmlFragment)
        
        var lineDisplayOpt: LineDisplayOption = .pBold
        var depth = 1
        if let collection = workspace?.collection {
            lineDisplayOpt = collection.titleDisplayOption
            if collection.levelFieldDef != nil {
                let levelValue = fromNote.level
                depth = levelValue.level
            }
        }
        
        var titleToDisplay = fromNote.title.value
        if !parms.included.asList {
            if fromNote.hasSeq() || fromNote.hasDisplaySeq() {
                titleToDisplay = fromNote.formattedSeqForDisplay + " " + fromNote.title.value
            }
        }
        
        markedUp.displayLine(opt: lineDisplayOpt,
                             text: titleToDisplay,
                             depth: depth,
                             addID: true,
                             idText: fromNote.title.value)
        return markedUp.code
    }
    
    func genNextSlug(fromNote: Note, position: Int) -> String {
        
        var label = "Next: "
        var index = position + 1
        while index < notesList.count && notesList[index].excludeFromBook(epub: false) {
            index += 1
        }
        if index >= notesList.count {
            label = "Back to Top: "
            index = 0
        }
        guard index < notesList.count else { return "" }
        let note = notesList[index]
        let title = note.title.value
        let nextHTML = Markedup()
        nextHTML.startParagraph()
        nextHTML.append(label)
        nextHTML.link(text: title, path: parms.wikiLinks.assembleWikiLink(title: title), klass: Markedup.htmlClassNavLink)
        nextHTML.finishParagraph()
        return nextHTML.code
    }
    
    func genParentSlug(fromNote: Note, position: Int) -> String {
        
        guard fromNote.hasSeq() || fromNote.hasLevel() else {
            return ""
        }
        guard position > 0 else { return "" }
        
        let depth = fromNote.depth
        var aboveIndex = position - 1
        var aboveDepth = depth
        while aboveIndex >= 0 && aboveDepth >= depth {
            let aboveNote = notesList[aboveIndex]
            aboveDepth = aboveNote.depth
            if aboveDepth >= depth {
                aboveIndex -= 1
            }
        }
        
        guard aboveIndex >= 0 && aboveDepth < depth else {
            return ""
        }
        
        let parent = notesList[aboveIndex]
        let parentTitle = parent.title.value
        let parentSeq = parent.seq
        let parentHTML = Markedup()
        parentHTML.startParagraph()
        if parentSeq.count > 0 {
            if !parent.klass.frontOrBack {
                parentHTML.append("\(parentSeq) ")
            }
        }
        parentHTML.link(text: parentTitle, path: parms.wikiLinks.assembleWikiLink(title: parentTitle), klass: Markedup.htmlClassNavLink)
        parentHTML.append("&nbsp;")
        parentHTML.append("&#8593;")
        parentHTML.finishParagraph()
        return parentHTML.code
        
    }
    
    func genChildrenSlug(fromNote: Note, position: Int) -> String {
        
        guard fromNote.hasSeq() || fromNote.hasLevel() else { return "" }
        let parentDepth = fromNote.depth
        
        var nextPosition = position + 1
        guard position >= 0 && nextPosition < notesList.count else { return "" }
        
        var nextNote = notesList[nextPosition]
        var nextDepth = nextNote.depth
        let childDepth = nextDepth
        guard childDepth > parentDepth else { return "" }
        
        let childrenHTML = Markedup()
        childrenHTML.heading(level: 4, text: "Contents")
        childrenHTML.startUnorderedList(klass: "notenik-toc")
        while nextPosition < notesList.count && nextDepth > parentDepth {
            if nextDepth == childDepth {
                let tocTitle = nextNote.title.value
                childrenHTML.startListItem()
                if !nextNote.klass.frontOrBack {
                    childrenHTML.append("\(nextNote.formattedSeqForDisplay) ")
                }
                childrenHTML.link(text: tocTitle, path: parms.wikiLinks.assembleWikiLink(title: tocTitle), klass: Markedup.htmlClassNavLink)
                childrenHTML.finishListItem()
            }
            nextPosition += 1
            if nextPosition < notesList.count {
                nextNote = notesList[nextPosition]
                nextDepth = nextNote.depth
            }
        }
        
        childrenHTML.finishUnorderedList()
        childrenHTML.horizontalRule()

        return childrenHTML.code
    }
    
    func genWorkRightsSlug(fromNote: Note) -> String {
        var slug = ""
        let rights = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workRightsCommon)
        let holder = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workRightsHolderCommon)
        if rights != nil || holder != nil {
            let date = FieldGrabber.getField(note: fromNote, label: NotenikConstants.dateCommon)
            let author = FieldGrabber.getField(note: fromNote, label: NotenikConstants.authorCommon)
            if rights == nil || rights!.value.value.lowercased() == "copyright"{
                slug.append("&copy;")
            } else {
                slug.append(rights!.value.value)
            }
            slug.append(" ")
            if date != nil && !date!.value.value.isEmpty {
                slug.append(date!.value.value)
                slug.append(" ")
            }
            if holder != nil && !holder!.value.value.isEmpty {
                slug.append(holder!.value.value)
            } else if author != nil && !author!.value.value.isEmpty {
                slug.append(author!.value.value)
            }
        }
        return slug
    }
    
    func genAuthorWorkSlug(fromNote: Note) -> String {
        let markedUp = Markedup(format: .htmlFragment)
        
        if let authorField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.authorCommon) {
            if let authorValue = authorField.value as? AuthorValue {
                let authorLink = FieldGrabber.getField(note: fromNote, label: NotenikConstants.authorLinkCommon)
                if authorLink != nil {
                    markedUp.startLink(path: authorLink!.value.value, klass: Markedup.htmlClassExtLink, blankTarget: true)
                }
                markedUp.append(authorValue.firstNameFirst)
                if authorLink != nil {
                    markedUp.finishLink()
                }
            }
        }
        
        var workTitle = ""
        if fromNote.klass.value == NotenikConstants.workKlass {
            workTitle = fromNote.title.value
        } else if let wt = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTitleCommon) {
            workTitle = wt.value.value
        }
        
        if !workTitle.isEmpty && workTitle.lowercased() != "unknown" {
            if !markedUp.code.isEmpty {
                markedUp.append(", ")
            }
            var majorWork = true
            if let workTypeField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTypeCommon) {
                if let workType = workTypeField.value as? WorkTypeValue {
                    majorWork = workType.isMajor
                    let theType = workType.theType
                    if !theType.isEmpty {
                        markedUp.append("\(theType) ")
                    }
                }
            }
            if majorWork {
                markedUp.startCite()
            } else {
                markedUp.leftDoubleQuote()
            }
            
            var workLink = ""
            if let wl = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workLinkCommon) {
                workLink = wl.value.value
            } else if fromNote.klass.value == NotenikConstants.workKlass {
                workLink = fromNote.link.value
            }
            
            if !workLink.isEmpty {
                markedUp.startLink(path: workLink, klass: Markedup.htmlClassExtLink, blankTarget: true)
            }
            markedUp.append(workTitle)
            if !workLink.isEmpty {
                markedUp.finishLink()
            }
            if majorWork {
                markedUp.finishCite()
            } else {
                markedUp.rightDoubleQuote()
            }
        }
        
        if !markedUp.code.isEmpty {
            var slugDate = ""
            let workDate = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workDateCommon)
            if workDate != nil {
                slugDate = workDate!.value.value
            } else {
                let date = FieldGrabber.getField(note: fromNote, label: NotenikConstants.dateCommon)
                if date != nil {
                    slugDate = date!.value.value
                }
            }
            if !slugDate.isEmpty {
                markedUp.append(", \(slugDate)")
            }
        }
        return markedUp.code
    }
    
    func genImageSlug(fromNote: Note) -> String {
        
        guard let imageAttachment = fromNote.getImageAttachment() else { return "" }
        
        guard workspace != nil && !workspace!.webRootPath.isEmpty else { return "" }
        
        let markedUp = Markedup(format: .htmlFragment)
        
        // See if we can come up with a URL for the image.
        var imageURL: URL?
        if lastCopyToURL != nil {
            imageURL = lastCopyToURL!
        } else {
            let imagePath = NotenikConstants.filesFolderName + "/" + imageAttachment.fullName
            imageURL = URL(fileURLWithPath: imagePath)
        }
        guard imageURL != nil else { return " "}
        let imageFileName = FileName(imageURL!)
        guard imageFileName.isBeneath(webRootFileName) else { return "" }
        
        guard textOutURL != nil else { return "" }
        let imagePath = textOutFileName.makeRelative(path: imageURL!.path)
        
        let imageAltField = fromNote.getField(label: NotenikConstants.imageAltCommon)
        var imageAlt = ""
        if imageAltField != nil {
            imageAlt = imageAltField!.value.value
        }
        
        let imageCaptionField = fromNote.getField(label: NotenikConstants.imageCaptionCommon)
        var imageCaption = ""
        if imageCaptionField != nil {
            imageCaption = imageCaptionField!.value.value
        }
        
        let imageCreditField = fromNote.getField(label: NotenikConstants.imageCreditCommon)
        var imageCredit = ""
        if imageCreditField != nil {
            imageCredit = imageCreditField!.value.value
        }
        
        let imageCreditLinkField = fromNote.getField(label: NotenikConstants.imageCreditLinkCommon)
        var imageCreditLink = ""
        if imageCreditLinkField != nil {
            imageCreditLink = imageCreditLinkField!.value.value
        }
        
        var useFigure = false
        if imageCaptionField != nil || imageCreditField != nil {
            markedUp.startFigure()
            useFigure = true
        }

        markedUp.image(alt: imageAlt, path: imagePath)
        
        if useFigure {
            markedUp.startFigureCaption()
            if imageCaption.isEmpty {
                markedUp.append("Image Credit: ")
                if !imageCreditLink.isEmpty {
                    markedUp.startLink(path: imageCreditLink)
                }
                markedUp.append(imageCredit)
                if !imageCreditLink.isEmpty {
                    markedUp.finishLink()
                }
            } else {
                markedUp.append(imageCaption)
            }
            markedUp.finishFigureCaption()
        }
        
        if useFigure {
            markedUp.finishFigure()
        }
        return markedUp.code
    }
    
    func genImageNameShort(fromNote: Note) -> String {
        guard let attachment = fromNote.getImageAttachment() else { return "" }
        return attachment.suffix
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "TemplateUtil",
                          level: .info,
                          message: msg)
        if workspace != nil {
            workspace!.writeLineToLog(msg)
        }
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "TemplateUtil",
                          level: .error,
                          message: msg)
        if workspace != nil {
            workspace!.writeErrorToLog(msg)
        }
    }
}

enum OutputStage {
    case front
    case outer
    case loop
    case postLoop
}
