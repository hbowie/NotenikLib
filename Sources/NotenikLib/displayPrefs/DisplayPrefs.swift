//
//  DisplayPrefs.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

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
    
    public var bodySpecs = FontSpecs(fontsFor: .body)
    public var headingSpecs = FontSpecs(fontsFor: .headings)
    public var listSpecs = FontSpecs(fontsFor: .list)
    
    let fontCSSKey = "display-css"
    var _fontCSS: String?
    
    let headingCenterStartKey = "heading-center-start"
    var _headingCenterStart = 0
    let defaultHeadingCenterStart = 0
    
    let headingCenterFinishKey = "heading-center-finish"
    var _headingCenterFinish = 0
    let defaultHeadingCenterFinish = 0
    
    var displayMaster: NoteDisplayMaster?
    
    /// Private initializer to prevent creation of more than one instance
    private init() {
        
        _longFontList = defaults.bool(forKey: longFontListKey)
        
        bodySpecs.loadDefaults()
        headingSpecs.loadDefaults()
        listSpecs.loadDefaults()
        
        _fontCSS = defaults.string(forKey: fontCSSKey)
        if _fontCSS == nil || _fontCSS!.count == 0 {
            buildFontCSS()
        }
        
        _headingCenterStart = defaults.integer(forKey: headingCenterStartKey)
        _headingCenterFinish = defaults.integer(forKey: headingCenterFinishKey)
    }
    
    public func saveLatestFontSpecs() {
        bodySpecs.saveLatest()
        headingSpecs.saveLatest()
        listSpecs.saveLatest()
    }
    
    public func getSpecs(fontsFor: FontsFor) -> FontSpecs {
        switch fontsFor {
        case .body:
            return bodySpecs
        case .headings:
            return headingSpecs
        case .list:
            return listSpecs
        }
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
    
    public var fontCSS: String? {
        get {
            return _fontCSS
        }
        set {
            _fontCSS = newValue
            defaults.set(_fontCSS, forKey: fontCSSKey)
        }
    }
    
    public var headingCenterStart: Int {
        get {
            return _headingCenterStart
        }
        set {
            _headingCenterStart = newValue
            defaults.set(_headingCenterStart, forKey: headingCenterStartKey)
        }
    }
    
    public var headingCenterFinish: Int {
        get {
            return _headingCenterFinish
        }
        set {
            _headingCenterFinish = newValue
            defaults.set(_headingCenterFinish, forKey: headingCenterFinishKey)
        }
    }
    
    public func buildFontCSS() {
        fontCSS = bodySpecs.buildFontCSS(indent: 0)
    }
    
    public func buildCSS(f: String, s: String) -> String {
        return bodySpecs.buildCSS(f: f, s: s, indent: 2)
    }
    
    /// Supply the complete CSS to be used for displaying a Note.
    public var displayCSS: String? {
        var tempCSS = darkModeAdjustments()
        tempCSS.append("""
        /* The following CSS comes from the displayCSS method of the
           DisplayPrefs class within Notenik.                        */
        body {
          tab-size: 4;
          margin: 1em;
          background-color: var(--background-color);
          color: var(--text-color);
          line-height: 1.45;

        """)
        if fontCSS != nil {
            tempCSS.append("/* fontCSS insertion starts here */\n")
            tempCSS.append(fontCSS!)
            tempCSS.append("/* fontCSS insertion ends here   */\n")
        }
        tempCSS.append("""
        }
        p {
            margin-top: 0.2em;
            margin-bottom: 0.7em;
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
          margin-bottom: 0.7em;
        }
        th, td {
          padding: 6px;
        }
        img {
          max-width: 100%;
          height: auto;
        }
        
        li { margin-top: 0.2em; margin-bottom: 0.2em; }
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
        ol.notenik-biblio-list {
          list-style-type: none;
          margin-left: 0;
          padding-left: 0;
        }
        ol.notenik-biblio-list li {
          margin-left: 3em;
          text-indent: -3em;
          margin-bottom: 1em;
        }
        cite.notenik-cite-major {
          font-style: italic;
        }
        cite.notenik-cite-minor {
          font-style: normal;
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
        table.notenik-calendar {
          table-layout: fixed;
          width: 100%;
          margin-top: 1em;
          margin-bottom: 1em;
        }
        td.notenik-calendar-day-data {
          vertical-align: top;
        }
        p.notenik-calendar-day-of-month {
          margin-top: 0;
          margin-bottom: 0;
          text-align: right;
          font-size: 1.2em;
        }
        p.notenik-calendar-day-contents {
          margin-top: 0;
          margin-bottom: 0;
        }
        
        a:visited {
            color: var(--link-visited-color);
        }
        a:active {
            color: var(--link-active-color);
        }

        a.wiki-link {
            text-decoration: none;
            border-bottom: 1px dotted;
        }

        a.ext-link {
            text-decoration: none;
            border-bottom: 1px dotted;
        }

        a.nav-link:link {
            text-decoration: none;
            border-bottom: none;
        }
        
        header {
            text-align: center;
        }
        
        nav {
            float: right;
            font-style: italic;
        }
        
        nav ul {
            margin-top: 0;
        }
        
        nav ul li {
            display: inline;
        }
        
        nav ul li a {
            text-decoration: none;
            border-bottom: none;
        }
        
        nav ul li a.wiki-link {
            text-decoration: none;
            border-bottom: none;
        }
        
        footer {
            clear: both;
            border-top: 1px dashed var(--text-color);
            margin-top: 1em;
            font-size: 0.8em;
            font-weight: lighter;
            text-align: right;
        }
        
        footer p {
            padding-top: 0.5em;
        }
        
        .float-left {
            float: left;
        }
        
        .float-right {
            float: right;
        }
        
        .heading-1-details {
            margin-left: 2.2em;
        }
        .heading-2-details {
            margin-left: 2.2em;
        }
        .heading-3-details {
            margin-left: 2.2em;
        }
        .heading-4-details {
            margin-left: 2.2em;
        }
        .heading-5-details {
            margin-left: 2.2em;
        }
        .heading-6-details {
            margin-left: 2.2em;
        }
        
        .heading-1-summary {
            margin-left: -2.2em;
            margin-bottom: 0.5em;
        }
        .heading-2-summary {
            margin-left: -2.2em;
            margin-bottom: 0.5em;
        }
        .heading-3-summary {
            margin-left: -2.2em;
            margin-bottom: 0.5em;
        }
        .heading-4-summary {
            margin-left: -2.2em;
            margin-bottom: 0.5em;
        }
        .heading-5-summary {
            margin-left: -2.2em;
            margin-bottom: 0.5em;
        }
        .heading-6-summary {
            margin-left: -2.2em;
            margin-bottom: 0.5em;
        }
        
        ul.outline-ul {
            list-style-type: none;
        }
        ul.outline-ul-within-details {
            list-style-type: none;
            margin-left: 0;
            padding-left: 5px;
        }
        li.outline-li-bullet {
            list-style-type: disc;
            list-style-position: inside;
        }
        
        details {
            margin-left: 2.2em;
        }
        summary {
            margin-left: -2.2em;
            margin-bottom: 0.5em;
        }
        pre {
            overflow-x: auto;
        }
        
        """)
        tempCSS.append(buildHeadingsCSS())
        
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
    
    public func buildHeadingsCSS() -> String {
        return buildHeadingCSS(centerStart: headingCenterStart,
                               centerFinish: headingCenterFinish,
                               bodyFont: bodySpecs.font,
                               headingsFont: headingSpecs.font,
                               headingsSize: headingSpecs.size!)
    }
    
    public func buildHeadingCSS(centerStart: Int,
                                centerFinish: Int,
                                bodyFont: String,
                                headingsFont: String,
                                headingsSize: String) -> String {
        
        var hc = ""
        var fontWeight = "600"
        if bodyFont != headingsFont {
            fontWeight = "400"
        }
        hc.append("""
        /* Generated CSS for headings follows. */
        h1, h2, h3, h4, h5, h6 {
            font-family: \"\(headingsFont)\", Helvetica, Arial, sans-serif;
            font-weight: \(fontWeight);
            margin-top: 0.7em;
            margin-bottom: 0.2em;
            font-style: normal;
        }
        
        """
        )
        
        var fontSize: Float = 2.0
        if let fs = Float(headingsSize) {
            fontSize = fs
        }
        for i in 1...6 {
            var ta = "center"
            if centerStart < 1 || i < centerStart || i > centerFinish {
                ta = "left"
            }
            let emSize = String(format: "%.1f", fontSize)
            hc.append("""
            h\(i) {
                text-align: \(ta);
                font-size: \(emSize)em;
            }
            
            """
            )
            fontSize -= 0.2
        }
        return hc
    }
    
    public func darkModeAdjustments() -> String {
        var tempCSS = "/* The following CSS comes from the darkModeAdjustments \n"
        tempCSS.append("   method of the DisplayPrefs class within Notenik. */\n")
        
        if appPrefs.appAppearance == "system" || appPrefs.appAppearance == "light" {
            tempCSS.append("""
        :root {
            color-scheme: light dark;
            --background-color: #FFFFFF;
            --text-color: #000000;
            --link-color: Blue;
            --link-hover-color: Blue;
            --background-hover-color: #f0f0f0;
            --link-visited-color: Purple;
            --link-active-color: Red;
            --background-active-color: #e0e0e0;
            --highlight-color: Gainsboro
        }
        a.ext-link::after {
            content: "";
            width: 0.9em;
            height: 0.9em;
            margin-left: 0.2em;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' fill='currentColor' viewBox='0 0 16 16'%3E%3Cpath fill-rule='evenodd' d='M8.636 3.5a.5.5 0 0 0-.5-.5H1.5A1.5 1.5 0 0 0 0 4.5v10A1.5 1.5 0 0 0 1.5 16h10a1.5 1.5 0 0 0 1.5-1.5V7.864a.5.5 0 0 0-1 0V14.5a.5.5 0 0 1-.5.5h-10a.5.5 0 0 1-.5-.5v-10a.5.5 0 0 1 .5-.5h6.636a.5.5 0 0 0 .5-.5z'/%3E%3Cpath fill-rule='evenodd' d='M16 .5a.5.5 0 0 0-.5-.5h-5a.5.5 0 0 0 0 1h3.793L6.146 9.146a.5.5 0 1 0 .708.708L15 1.707V5.5a.5.5 0 0 0 1 0v-5z'/%3E%3C/svg%3E");
            background-position: center;
            background-repeat: no-repeat;
            background-size: contain;
            display: inline-block;
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
            --link-hover-color: #94d8ff;
            --background-hover-color: #282828;
            --link-visited-color: #cab7ff;
            --link-active-color: #94d8ff;
            --background-active-color: #363636;
            --highlight-color: DimGray
          }
            a.ext-link::after {
                content: "";
                width: 0.9em;
                height: 0.9em;
                margin-left: 0.2em;
                background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' fill='currentColor' stroke='%23F0F0F0' viewBox='0 0 16 16'%3E%3Cpath fill-rule='evenodd' d='M8.636 3.5a.5.5 0 0 0-.5-.5H1.5A1.5 1.5 0 0 0 0 4.5v10A1.5 1.5 0 0 0 1.5 16h10a1.5 1.5 0 0 0 1.5-1.5V7.864a.5.5 0 0 0-1 0V14.5a.5.5 0 0 1-.5.5h-10a.5.5 0 0 1-.5-.5v-10a.5.5 0 0 1 .5-.5h6.636a.5.5 0 0 0 .5-.5z'/%3E%3Cpath fill-rule='evenodd' d='M16 .5a.5.5 0 0 0-.5-.5h-5a.5.5 0 0 0 0 1h3.793L6.146 9.146a.5.5 0 1 0 .708.708L15 1.707V5.5a.5.5 0 0 0 1 0v-5z'/%3E%3C/svg%3E");
                background-position: center;
                background-repeat: no-repeat;
                background-size: contain;
                display: inline-block;
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
        a:focus {
            color: var(--link-hover-color);
            background: var(--background-hover-color);
        }
        a:hover {
            color: var(--link-hover-color);
            background: var(--background-hover-color);
        }
        a:active {
            color: var(--link-active-color);
            background: var(--background-active-color);
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
