//
//  DisplayPrefs.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
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
        :root {
            --mono-font: Consolas, Menlo, Monaco, "Andale Mono", "Ubuntu Mono", monospace;
            --standard-border-radius: 5px;
        }
        body {
          tab-size: 4;
          margin: 1em 1em 1em 1.1em;
          max-width: 50em; 
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
        img { max-width: 100%; border: 4px solid gray; }
        /* body { max-width: 33em; margin: 0 auto; float: none; } */
        p {
            margin-top: 0.2em;
            margin-bottom: 0.7em;
        }
        body > footer {
            margin-top: 4rem;
            text-align: center;
        }
        /* Consolidate box styling */
        aside, pre, progress {
          background-color: var(--accent-bg);
          border: 1px solid var(--border);
          border-radius: var(--standard-border-radius);
          margin-bottom: 1rem;
        }
        aside {
          font-size: 1rem;
          width: 30%;
          padding: 0 15px;
          margin-inline-start: 15px;
          float: right;
        }
        *[dir="rtl"] aside {
          float: left;
        }

        /* Make aside full-width on mobile */
        @media only screen and (max-width: 720px) {
          aside {
            width: 100%;
            float: none;
            margin-inline-start: 0;
          }
        }
        blockquote {
          border-left: 0.4em solid #999;
          margin-left: 0;
          padding-left: 1em;
        }
        .quote-from {
            margin-block-start: 0.1rem;
            margin-block-end: 0.5rem;
            margin: 0.1rem 0 0.5rem 0;
            padding: 0.25rem 2.6em;
            line-height: 1.45;
            position: relative;
        }
        .quote-from:before {
            display: block;
            padding-left: 1.4em;
            content: \"\\2014\";
            position: absolute;
            left: 0;
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

        /* --------------------------------------------------

          Lists

        * -------------------------------------------------- */

        li { margin-top: 0.2em; margin-bottom: 0.2em; }
        p.nnk-tags-repl-nav-up {
                font-style: italic;
        }
        p.nnk-tags {
                font-style: italic;
                width: 100%;
                text-align: right;
                clear: both;
        }
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
        ul.notenik-toc {
          list-style-type: none; /* Remove bullets */
          padding: 0; /* Remove padding */
          margin: 0; /* Remove margins */
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
        ul.outline-ul {
            list-style-type: none;
        }
        ul.outline-list {
            list-style-type: none;
        }
        ul.outline-ul-within-details {
            list-style-type: none;
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
            margin-bottom: 0;
        }
        details > summary:first-of-type {
            list-style-position: outside;
        }
        /* --------------------------------------------------

          Other stuff

        * -------------------------------------------------- */
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

        a.hashtag {
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

        nav ul li a.wiki-link {
            text-decoration: none;
            border-bottom: none;
        }
        
        .nnk-header a:link {
            text-decoration: none;
            border-bottom: none; 
        }

        footer.nnk-footer {
            clear: both;
            border-top: 1px dashed var(--text-color);
            margin-top: 1em;
            font-size: 0.8em;
            font-weight: lighter;
            text-align: right;
        }

        footer.nnk-footer p {
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
        pre {
            
        }
        code {
            font-family: var(--mono-font);
            color: var(--code-color);
        }
        pre {
          padding: 1rem 1.4rem;
          max-width: 100%;
          overflow-x: auto;
          color: var(--preformatted-color);
        }

        /* Fix embedded code within pre */
        pre code {
          color: var(--preformatted-color);
          background: none;
          margin: 0;
          padding: 0;
        }

        /* Classes for notices */
        .notice {
          background: var(--accent-bg);
          border: 2px solid var(--border);
          border-radius: var(--standard-border-radius);
          padding: 1.5rem;
          margin: 2rem 0;
        }

        article, fieldset, dialog {
          border: 1px solid var(--border);
          padding: 1rem;
          border-radius: var(--standard-border-radius);
          margin-bottom: 1rem;
        }

        article h2:first-child,
        section h2:first-child,
        article h3:first-child,
        section h3:first-child {
          margin-top: 1rem;
        }

        /* Make the header bg full width, but the content inline with body */
        body > header {
          background-color: var(--accent-bg);
          border-bottom: 1px solid var(--border);
          text-align: center;
          padding: 0 0.5rem 2rem 0.5rem;
          grid-column: 1 / -1;
        }

        body > header > *:only-child {
          margin-block-start: 2rem;
        }

        body > header h1 {
          max-width: 1200px;
          margin: 1rem auto;
        }

        body > header p {
          max-width: 40rem;
          margin: 1rem auto;
        }

        header.nnk-header {
            background-color: var(--background-color);
            text-align: center;
            border-bottom: none;
            max-width: none;
            padding: 0 0 0 0;
        }

        /* Format navigation */
        header > nav {
          font-size: 1rem;
          line-height: 2;
          padding: 1rem 0 0 0;
        }

        /* Use flexbox to allow items to wrap, as needed */
        header > nav ul,
        header > nav ol {
          align-content: space-around;
          align-items: center;
          display: flex;
          flex-direction: row;
          flex-wrap: wrap;
          justify-content: center;
          list-style-type: none;
          margin: 0;
          padding: 0;
        }

        /* List items are inline elements, make them behave more like blocks */
        header > nav ul li,
        header > nav ol li {
          display: inline-block;
        }

        header > nav a,
        header > nav a:visited {
          margin: 0 0.5rem 1rem 0.5rem;
          border: 1px solid var(--border);
          border-radius: var(--standard-border-radius);
          color: var(--text);
          display: inline-block;
          padding: 0.1rem 1rem;
          text-decoration: none;
        }

        header > nav a:hover,
        header > nav a.current,
        header > nav a[aria-current="page"],
        header > nav a[aria-current="true"] {
          border-color: var(--accent);
          color: var(--accent);
          cursor: pointer;
        }

        /* Reduce nav side on mobile */
        @media only screen and (max-width: 720px) {
          header > nav a {
            border: none;
            padding: 0;
            text-decoration: underline;
            line-height: 1;
          }
        }

        nav.nnk-nav {
            float: right;
            font-style: italic;
        }

        nav.nnk-nav ul {
            margin-top: 0;
        }

        nav.nnk-nav ul li {
            display: inline;
        }

        nav.nnk-nav ul li a {
            text-decoration: none;
            border-bottom: none;
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
            --code-color: #d81b60;
            --preformatted-color: #444;
            --accent-bg: #f5f7ff;
            --border: #898EA4;
            --highlight-color: Gainsboro;
            --bg: #fff;
            --accent-bg: #f5f7ff;
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
            --code-color: #f06292;
            --preformatted-color: #ccc;
            --accent-bg: #2b2b2b;
            --highlight-color: DimGray;
            --bg: #212121;
            --accent-bg: #2b2b2b;
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
        tempCSS.append("/* End of darkModeAdjustments code. */\n")
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
