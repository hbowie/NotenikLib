//
//  FontSpecs.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/3/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class FontSpecs {
    
    let defaults = UserDefaults.standard
    
    public var fontsFor: FontsFor = .body
    
    let displayFontKey = "display-font"
    var completeFontKey = ""
    let defaultFont = "Verdana"
    var _displayFont: String?
    var startingFont = ""
    var latestFont = ""
    
    let displaySizeKey = "display-size"
    var completeSizeKey = ""
    let bodyDefaultSize = "12"
    let headingDefaultSize = "2.0"
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
        startingFont = _displayFont!
        latestFont = _displayFont!
        
        _displaySize = defaults.string(forKey: completeSizeKey)
        if _displaySize == nil || _displaySize!.count == 0 {
            _ = setDefaultSize()
        }
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
    
    public func buildFontCSS(indent: Int) -> String {
        if size == nil {
            _ = setDefaultSize()
        }
        return buildCSS(f: font, s: size!, indent: indent)
    }
    
    public func buildLatestCSS(indent: Int) -> String {
        return buildCSS(f: latestFont, s: latestSize, indent: indent)
    }
    
    public func buildCSS(f: String, s: String, indent: Int) -> String {
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
        tempCSS += s
        tempCSS += "pt;\n"
        return tempCSS
    }
    
    public func setDefaultFont() -> String {
        font = defaultFont
        return font
    }
    
    public func setDefaultSize() -> String {
        switch fontsFor {
        case .body:
            size = bodyDefaultSize
        case .headings:
            size = headingDefaultSize
        }
        return size!
    }
    
    public var font: String {
        get {
            return _displayFont!
        }
        set {
            _displayFont = newValue
            defaults.set(_displayFont, forKey: completeFontKey)
        }
    }
    
    var sizePlusUnit: String? {
        if _displaySize == nil {
            return nil
        } else if fontsFor == .body {
            return _displaySize! + "pt"
        } else if fontsFor == .headings {
            return _displaySize! + "em"
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
            defaults.set(_displaySize, forKey: completeSizeKey)
        }
    }
    
}
