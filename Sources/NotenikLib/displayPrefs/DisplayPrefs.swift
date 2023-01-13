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

/// A Singleton Class for sharing and updating appearance preferences for the Display tab.
/// This is also the source of default CSS used for the display.
public class DisplayPrefs {
    
    // Provide a single standard shared singleton instance
    public static let shared = DisplayPrefs()
    
    let defaults = UserDefaults.standard
    
    let appPrefs = AppPrefs.shared
    
    let longFontListKey = "long-font-list"
    var _longFontList = false
    let defaultLongFontList = false
    
    let displayFontKey = "display-font"
    var _displayFont: String?
    let defaultFont = "Verdana"
    
    let displaySizeKey = "display-size"
    var _displaySize: String?
    let defaultSize = "12"
    
    let fontCSSKey = "display-css"
    var _fontCSS: String?
    
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
        
        _fontCSS = defaults.string(forKey: fontCSSKey)
        if _fontCSS == nil || _fontCSS!.count == 0 {
            buildFontCSS()
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
    
    public var fontCSS: String? {
        get {
            return _fontCSS
        }
        set {
            _fontCSS = newValue
            defaults.set(_fontCSS, forKey: fontCSSKey)
        }
    }
    
    public func buildFontCSS() {
        var tempCSS = ""
        tempCSS += "font-family: "
        tempCSS += "\"" + font + "\""
        tempCSS += ", \"Helvetica Neue\", Helvetica, Arial, sans-serif;\n"
        tempCSS += "font-size: "
        if size == nil {
            setDefaultSize()
        }
        tempCSS += sizePlusUnit!
        fontCSS = tempCSS
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
    
    /// Supply the complete CSS to be used for displaying a Note.
    public var displayCSS: String? {
        var tempCSS = darkModeAdjustments()
        tempCSS.append("""
        body {
          tab-size: 4;
          margin: 1em;
          background-color: var(--background-color);
          color: var(--text-color);

        """)
        if fontCSS != nil {
            tempCSS.append(fontCSS!)
        }
        tempCSS.append("""
        }
        blockquote {
          border-left: 0.4em solid #999;
          margin-left: 0;
          padding-left: 1em;
        }
        figure {
          margin-left: 0.2em;
          padding-left: 0.2em;
        }
        table, th, td {
          border: 2px solid gray;
        }
        table {
          border-collapse: collapse;
        }
        th, td {
          padding: 6px;
        }
        img {
          max-width: 100%;
          height: auto;
        }
        h1 { font-size: 2.0em; margin-top: 0.7em; margin-bottom: 0.0em; font-weight: 600; font-style: normal;  }
        h2 { font-size: 1.8em; margin-top: 0.7em; margin-bottom: 0.0em; font-weight: 600; font-style: normal;  }
        h3 { font-size: 1.6em; margin-top: 0.7em; margin-bottom: 0.0em; font-weight: 600; font-style: normal;  }
        h4 { font-size: 1.4em; margin-top: 0.7em; margin-bottom: 0.0em; font-weight: 600; font-style: normal;  }
        h5 { font-size: 1.2em; margin-top: 0.7em; margin-bottom: 0.0em; font-weight: 600; font-style: normal;  }
        h6 { font-size: 1.0em; margin-top: 0.7em; margin-bottom: 0.0em; font-weight: 600; font-style: normal;  }
        ul.checklist { list-style-type: none; }
        ul.tags-list { list-style-type: none; }
        ul.tags-cloud {
          list-style: none;
          padding-left: 0;
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          justify-content: center;
          line-height: 2.5rem;
        }
        ul.tags-cloud a {
          display: block;
          font-size: 1.1rem;
          font-weight: 600;
          text-decoration: none;
          position: relative;
          border-radius: 15px;
          background-color: var(--highlight-color);
          padding: 2px 12px 2px 12px;
          margin: 10px 10px 10px 10px;
          min-width: 40px;
          text-align: center;
        }
        figure.notenik-quote-attrib {
            margin-left: 2em;
            margin-right: 2em;
            margin-bottom: 2em;
        }
        figure.notenik-quote-attrib blockquote {
          border-left: none;
          margin-left: 0;
          padding-left: 0;
        }
        figure.notenik-quote-attrib figcaption {
            text-align: right;
        }
        .notenik-aka {
            font-style: italic;
            text-align: center;
            margin-top: 0;
        }
        ul.notenik-toc {
          list-style-type: none; /* Remove bullets */
          padding: 0; /* Remove padding */
          margin: 0; /* Remove margins */
        }
        
        """)
        
        // tempCSS.append("\ncode { overflow: auto }")
        return tempCSS
    }
    
    /// Apply the given CSS to the entire body.
    public func buildBodyCSS(_ css: String) -> String {
        var tempCSS = darkModeAdjustments()
        tempCSS.append("body { ")
        tempCSS.append(css)
        tempCSS.append(" }")
        // tempCSS.append("\ncode { overflow: auto }")
        return tempCSS
    }
    
    public func darkModeAdjustments() -> String {
        var tempCSS = ""
        
        if appPrefs.appAppearance == "system" || appPrefs.appAppearance == "light" {
            tempCSS.append("""
        :root {
            color-scheme: light dark;
            --background-color: #FFFFFF;
            --text-color: #000000;
            --link-color: Blue;
            --highlight-color: Gainsboro
        }
        
        """)
        }
        
        if appPrefs.appAppearance == "system" {
            tempCSS.append("@media screen and (prefers-color-scheme: dark) { \n")
        }
        
        if appPrefs.appAppearance == "system" || appPrefs.appAppearance == "dark" {
            tempCSS.append("""
          :root {
            --background-color: #000000;
            --text-color: #F0F0F0;
            --link-color: #93d5ff;
            --highlight-color: DimGray
          }
        
        """)
        }
            
        if appPrefs.appAppearance == "system" {
            tempCSS.append("""
        }
        
        """)
        }
        tempCSS.append("""
        a {
            color: var(--link-color);
        }
        .search-results {
            background-color: var(--highlight-color);
        }
        
        """)
        return tempCSS
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
