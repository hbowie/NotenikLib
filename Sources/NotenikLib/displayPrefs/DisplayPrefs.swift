//
//  DisplayPrefs.swift
//  Notenik
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019-2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Singleton Class for sharing and updating appearance preferences for the Display tab
public class DisplayPrefs {
    
    // Provide a single standard shared singleton instance
    public static let shared = DisplayPrefs()
    
    let defaults = UserDefaults.standard
    
    let longFontListKey = "long-font-list"
    var _longFontList = false
    let defaultLongFontList = false
    
    let displayFontKey = "display-font"
    var _displayFont: String?
    let defaultFont = "Verdana"
    
    let displaySizeKey = "display-size"
    var _displaySize: String?
    let defaultSize = "12"
    
    let displayCSSKey = "display-css"
    var _displayCSS: String?
    
    var displayMaster: NoteDisplayMaster?
    
    /// Private initializer to prevent creation of more than one instance
    private init() {
        
        _longFontList = defaults.bool(forKey: longFontListKey)
        
        _displayFont = defaults.string(forKey: displayFontKey)
        if _displayFont == nil || _displayFont!.count == 0 {
            _ = setDefaultFont()
        }
        
        _displaySize = defaults.string(forKey: displaySizeKey)
        if _displaySize == nil || _displaySize!.count == 0 {
            setDefaultSize()
        }
        
        _displayCSS = defaults.string(forKey: displayCSSKey)
        if _displayCSS == nil || _displayCSS!.count == 0 {
            buildCSS()
        }
    }
    
    public func setDefaultFont() -> String {
        font = defaultFont
        return font
    }
    
    func setDefaultSize() {
        size = defaultSize
    }
    
    public var longFontList: Bool {
        get {
            return _longFontList
        }
        set {
            _longFontList = newValue
            defaults.set(newValue, forKey: longFontListKey)
        }
    }
    
    public var font: String {
        get {
            return _displayFont!
        }
        set {
            _displayFont = newValue
            defaults.set(_displayFont, forKey: displayFontKey)
        }
    }
    
    var sizePlusUnit: String? {
        if _displaySize == nil {
            return nil
        } else {
            return _displaySize! + "pt"
        }
    }
    
    public var size: String? {
        get {
            return _displaySize
        }
        set {
            _displaySize = newValue
            defaults.set(_displaySize, forKey: displaySizeKey)
        }
    }
    
    public func buildCSS() {
        var tempCSS = ""
        tempCSS += "font-family: "
        tempCSS += "\"" + font + "\""
        tempCSS += ", \"Helvetica Neue\", Helvetica, Arial, sans-serif;\n"
        tempCSS += "font-size: "
        if size == nil {
            setDefaultSize()
        }
        tempCSS += sizePlusUnit!
        css = tempCSS
    }
    
    public func buildCSS(f: String, s: String) -> String {
        var tempCSS = ""
        tempCSS += "font-family: "
        tempCSS += "\"" + f + "\""
        tempCSS += ", \"Helvetica Neue\", Helvetica, Arial, sans-serif;\n"
        tempCSS += "font-size: "
        tempCSS += s
        tempCSS += "pt"
        return tempCSS
    }
    
    /// Apply the CSS to the entire body. 
    public var bodyCSS: String? {
        var tempCSS = "body { "
        if css != nil {
            tempCSS.append(css!)
        }
        tempCSS.append(" }")
        // tempCSS.append("\ncode { overflow: auto }")
        return tempCSS
    }
    
    /// Apply the given CSS to the entire body.
    public func buildBodyCSS(_ css: String) -> String {
        var tempCSS = "body { "
        tempCSS.append(css)
        tempCSS.append(" }")
        // tempCSS.append("\ncode { overflow: auto }")
        return tempCSS
    }
    
    public var css: String? {
        get {
            return _displayCSS
        }
        set {
            _displayCSS = newValue
            defaults.set(_displayCSS, forKey: displayCSSKey)
        }
    }
    
    public func setMaster(master: NoteDisplayMaster) {
        self.displayMaster = master
    }
    
    public func displayRefresh() {
        if displayMaster != nil {
            displayMaster!.displayRefresh()
        }
    }
}
