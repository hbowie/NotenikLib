//
//  FontSpecs.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/3/23.
//
//  Copyright © 2023 - 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class FontSpecs {
    
    let defaults = UserDefaults.standard
    
    public var fontsFor: FontsFor = .body
    public var storeType: DisplayPrefsStoreType = .appSettings
    
    let displayFontKey = "display-font"
    var completeFontKey = ""
    let webDefaultFont = "Verdana"
    let macDefaultFont = "- System Font -"
    var _displayFont: String?
    var startingFont = ""
    var latestFont = ""
    
    let displaySizeKey = "display-size"
    var completeSizeKey = ""
    let bodyDefaultSize = "12"
    let headingDefaultSize = "2.0"
    let listDefaultSize = "13"
    var _displaySize: String?
    var startingSize = ""
    var latestSize = ""
    
    public init(fontsFor: FontsFor) {
        self.fontsFor = fontsFor
        switch fontsFor {
        case .body:
            completeFontKey = displayFontKey
            completeSizeKey = displaySizeKey
        default:
            completeFontKey = fontsFor.rawValue + "-" + displayFontKey
            completeSizeKey = fontsFor.rawValue + "-" + displaySizeKey
        }
    }
    
    public func loadDefaults() {
        
        _displayFont = defaults.string(forKey: completeFontKey)
        if _displayFont == nil || _displayFont!.count == 0 {
            _ = setDefaultFont()
        }
        
        _displaySize = defaults.string(forKey: completeSizeKey)
        if _displaySize == nil || _displaySize!.count == 0 {
            _ = setDefaultSize()
        }

        initStartingAndLatest()
    }
    
    public func loadCollectionDefaults(infoNote: Note) {
        
        let fontField = infoNote.getField(label: completeFontKey)
        if fontField == nil || fontField!.value.isEmpty {
            _ = setDefaultFont()
        } else {
            _displayFont = fontField!.value.value
        }
        
        let sizeField = infoNote.getField(label: completeSizeKey)
        if sizeField == nil || sizeField!.value.isEmpty {
            _ = setDefaultSize()
        } else {
            _displaySize = sizeField!.value.value
        }
        
        initStartingAndLatest()
    }
    
    public func saveCollectionDefaults(writer: KeyValueWriter) {
        writer.append(label: completeFontKey, value: font)
        if size != nil {
            writer.append(label: completeSizeKey, value: size!)
        }
    }
    
    public func copy(storeType: DisplayPrefsStoreType = .collectionSettings) -> FontSpecs {
        let copy = FontSpecs(fontsFor: fontsFor)
        copy.storeType = storeType
        copy.font = font
        copy.size = size
        copy.initStartingAndLatest()
        return copy
    }
    
    func initStartingAndLatest() {
        startingFont = _displayFont!
        latestFont = _displayFont!
        startingSize = _displaySize!
        latestSize = _displaySize!
    }
    
    public func setLatestFont(userSpec: String) {
        latestFont = userSpec
    }
    
    public func getLatestFont() -> String {
        return latestFont
    }
    
    public func setLatestSize(userSpec: String) {
        latestSize = userSpec
    }
    
    public func getLatestSize() -> String {
        return latestSize
    }
    
    public var latestSpecsChanged: Bool {
        return latestFontChanged || latestSizeChanged
    }
    
    public var latestFontChanged: Bool {
        return latestFont != startingFont
    }
    
    public var latestSizeChanged: Bool {
        return latestSize != startingSize
    }
    
    public func saveLatest() {
        font = latestFont
        size = latestSize
    }
    
    public func buildFontCSS(boostFactor: Float = 1.0, indent: Int) -> String {
        if size == nil {
            _ = setDefaultSize()
        }
        return buildCSS(f: font, s: size!, boostFactor: boostFactor, indent: indent)
    }
    
    public func buildLatestCSS(indent: Int) -> String {
        return buildCSS(f: latestFont, s: latestSize, indent: indent)
    }
    
    public func buildCSS(f: String, s: String, boostFactor: Float = 1.0, indent: Int) -> String {
        var indentStr = ""
        while indentStr.count < indent {
            indentStr += " "
        }
        var tempCSS = ""
        tempCSS += indentStr
        tempCSS += "font-family: "
        tempCSS += "\"" + f + "\""
        tempCSS += ", \"Helvetica Neue\", Helvetica, Arial, sans-serif;\n"
        tempCSS += indentStr
        tempCSS += "font-size: "
        
        var boosted = false
        if boostFactor != 1.0 {
            if let fontSize = Float(s) {
                let newSizeFloat = fontSize * boostFactor
                let newSizeRounded = newSizeFloat.rounded(.toNearestOrAwayFromZero)
                let newSizeInt = Int(newSizeRounded)
                let newSizeStr = String(newSizeInt)
                tempCSS += newSizeStr
                boosted = true
            }
        }
        
        if !boosted {
            tempCSS += s
        }
        tempCSS += "pt;\n"
        return tempCSS
    }
    
    public func setDefaultFont() -> String {
        switch fontsFor {
        case .body:
            font = webDefaultFont
        case .headings:
            font = webDefaultFont
        case .list:
            font = macDefaultFont
        }
        return font
    }
    
    public func setDefaultSize() -> String {
        switch fontsFor {
        case .body:
            size = bodyDefaultSize
        case .headings:
            size = headingDefaultSize
        case .list:
            size = listDefaultSize
        }
        return size!
    }
    
    public var font: String {
        get {
            if _displayFont == nil {
                _ = setDefaultFont()
            }
            return _displayFont!
        }
        set {
            _displayFont = newValue
            if storeType == .appSettings {
                defaults.set(_displayFont, forKey: completeFontKey)
            }
        }
    }
    
    var sizePlusUnit: String? {
        if _displaySize == nil {
            return nil
        } else if fontsFor == .body {
            return _displaySize! + "pt"
        } else if fontsFor == .headings {
            return _displaySize! + "em"
        } else if fontsFor == .list {
            return _displaySize! + "pt"
        } else {
            return _displaySize!
        }
    }
    
    public var size: String? {
        get {
            return _displaySize
        }
        set {
            _displaySize = newValue
            if storeType == .appSettings {
                defaults.set(_displaySize, forKey: completeSizeKey)
            }
        }
    }
    
    public func display() {
        print("  - Font Specs for \(fontsFor.rawValue)")
        print("    - font: \(font)")
        if size != nil {
            print("    - size: \(size!)")
        } else {
            print("    - size: nil!")
        }
    }
    
}
