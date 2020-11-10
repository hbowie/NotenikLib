//
//  AppPrefs.swift
//  Notenik
//
//  Created by Herb Bowie on 5/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation
import Network

import NotenikUtils

/// Act as an intermediary between various Application classes and the UserDefaults
public class AppPrefs {
    
    /// Provide a standard shared singleton instance
    public static let shared = AppPrefs()
    
    let fileManager = FileManager.default
    var tempDir: URL? = nil
    
    let defaults = UserDefaults.standard
    
    let launchingKey    = "app-launching"
    let quickDeletesKey = "quick-deletes"
    let tagsSelectKey   = "tags-to-select"
    let tagsSuppressKey = "tags-to-suppress"
    let parentRealmParentKey = "parent-realm-parent"
    let useCountKey     = "use-count"
    let lastVersionPromptedForReviewKey = "last-version-prompted-for-review"
    
    let favoritesColumnsKey = "favorites-columns"
    let favoritesRowsKey = "favorites-rows"
    let favoritesColumnWidthKey = "favorites-column-width"
    
    let markdownParserKey = "markdown-parser"
    
    let essentialURLKey = "essential-collection"
    var _essentialURL: URL?
    
    let lastURLKey = "last-collection"
    var _lastURL: URL?
    
    var _appLaunching = false
    
    var _qd: Bool = false
    
    var _prp = ""
    public var parentRealmPath = ""
    
    public var pickLists = ValuePickLists()
    
    var _tsel = ""
    var _tsup = ""
    
    var _uc = 0
    
    var _lvpfr = ""
    var currentVersion = ""
    
    var _favCols = 0
    var _favRows = 0
    var _favColWidth = "250px"
    
    var _mdParser = "notenik"
    
    var locale: Locale!
    var languageCode = "en"
    var localeID: String!
    public var americanEnglish = true
    
    var _tempFileCount =  1
    
    /// Private initializer to enforce usage of the singleton instance
    private init() {
        
        if #available(iOS 10.0, *) {
            tempDir = fileManager.temporaryDirectory
        }
        
        // Retrieve and log info about the current app.
        if let infoDictionary = Bundle.main.infoDictionary {
            let version = infoDictionary["CFBundleShortVersionString"] as? String
            let build   = infoDictionary[kCFBundleVersionKey as String] as? String
            let appName = infoDictionary[kCFBundleNameKey as String] as? String
            
            if appName != nil {
                logInfo("Launching \(appName!)")
            }
            
            if version != nil {
                currentVersion = version!
                logInfo("Version \(currentVersion)")
            }
            
            if build != nil {
                logInfo("Build # \(build!)")
            }
        }
        
        /// Check a prefs flag to see if we successfully completed launching
        /// last time around; if not, then reset to initial defaults.
        _appLaunching = defaults.bool(forKey: launchingKey)
        if appLaunching {
            resetDefaults()
        } else {
            appLaunching = true
            loadDefaults()
        }
        if #available(OSX 10.14, *) {
            initNetworkMonitor()
        }
    }
    
    func resetDefaults() {
        confirmDeletes = true
        parentRealmParent = ""
        useCount = 0
        favoritesColumns = 4
        favoritesRows = 32
        favoritesColumnWidth = "250px"
        markdownParser = "notenik"
    }
    
    func loadDefaults() {
        
        _essentialURL = defaults.url(forKey: essentialURLKey)
        
        _lastURL = defaults.url(forKey: lastURLKey)
        
        _qd = defaults.bool(forKey: quickDeletesKey)
        
        let tsel = defaults.string(forKey: tagsSelectKey)
        if tsel != nil {
            _tsel = tsel!
        }
        let tsup = defaults.string(forKey: tagsSuppressKey)
        if tsup != nil {
            _tsup = tsup!
        }
        
        let defaultprp = defaults.string(forKey: parentRealmParentKey)
        if defaultprp != nil {
            _prp = defaultprp!
        }
        
        _uc = defaults.integer(forKey: useCountKey)
        
        // Get the Last Version Prompted for Review.
        let lvpfr = defaults.string(forKey: lastVersionPromptedForReviewKey)
        if lvpfr != nil {
            _lvpfr = lvpfr!
        }
        
        // Get Favorites Defaults
        _favCols = defaults.integer(forKey: favoritesColumnsKey)
        _favRows = defaults.integer(forKey: favoritesRowsKey)
        if _favCols == 0 {
            _favCols = 4
        }
        if _favRows == 0 {
            _favRows = 32
        }
        let favColWidth = defaults.string(forKey: favoritesColumnWidthKey)
        if favColWidth != nil {
            _favColWidth = favColWidth!
        }
        
        // Get Markdown Parser defaults
        let mdParserDefault = defaults.string(forKey: markdownParserKey)
        if mdParserDefault != nil {
            _mdParser = mdParserDefault!
        }
        
        // American English? (Or British?)
        locale = Locale.current
        localeID = locale.identifier
        if locale.languageCode != nil {
            languageCode = locale.languageCode!
        }
        if languageCode == "en" {
            americanEnglish = (localeID == "en_US" || localeID == "en_PH" || localeID == "en_UM" || localeID == "en_US_POSIX" || localeID == "en_AS" || localeID == "en_VI")
        }
        // if localeID != nil {
        //     logInfo("Locale identifier is \(localeID!)")
        // }
        if locale.regionCode != nil {
            logInfo("Region code is \(locale.regionCode!)")
        }
        logInfo("Language code is \(languageCode)")
        if americanEnglish {
            logInfo("Using American English")
        } else {
            logInfo("Using UK/British English")
        }
    }
    
    /// Has the app made it out of the launching phase successfully?
    public var appLaunching: Bool {
        get {
            return _appLaunching
        }
        set {
            _appLaunching = newValue
            defaults.set(newValue, forKey: launchingKey)
        }
    }
    
    public var essentialURL: URL? {
        get {
            return _essentialURL
        }
        set {
            _essentialURL = newValue
            defaults.set(_essentialURL, forKey: essentialURLKey)
        }
    }
    
    public var lastURL: URL? {
        get {
            return _lastURL
        }
        set {
            _lastURL = newValue
            defaults.set(_lastURL, forKey: lastURLKey)
        }
    }
    
    public var confirmDeletes: Bool {
        get {
            return !_qd
        }
        set {
            _qd = !newValue
            defaults.set(_qd, forKey: quickDeletesKey)
        }
    }
    
    var parentRealmParent: String {
        get {
            return _prp
        }
        set {
            _prp = newValue
            defaults.set(_prp, forKey: parentRealmParentKey)
        }
    }
    
    public var parentRealmParentURL: URL? {
        get {
            if _prp.count > 0 {
                return URL(fileURLWithPath: _prp)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                _prp = newValue!.path
                defaults.set(_prp, forKey: parentRealmParentKey)
            }
        }
    }
    
    public var tagsToSelect: String {
        get {
            return _tsel
        }
        set {
            _tsel = newValue
            defaults.set(_tsel, forKey: tagsSelectKey)
        }
    }
    
    public var tagsToSuppress: String {
        get {
            return _tsup
        }
        set {
            _tsup = newValue
            defaults.set(_tsup, forKey: tagsSuppressKey)
        }
    }
    
    /// Add one to the use counter.
    public func incrementUseCount() {
        let newUseCount = useCount + 1
        useCount = newUseCount
    }
    
    /// Get and set the number of times the user has used the app. 
    public var useCount: Int {
        get {
            return _uc
        }
        set {
            _uc = newValue
            defaults.set(_uc, forKey: useCountKey)
        }
    }
    
    public func userPromptedForReview() {
        lastVersionPromptedForReview = currentVersion
    }
    
    /// Now see if we have a new version for review.
    public var newVersionForReview: Bool {
        return currentVersion > lastVersionPromptedForReview
    }
    
    var lastVersionPromptedForReview: String {
        get {
            return _lvpfr
        }
        set {
            _lvpfr = newValue
            defaults.set(_lvpfr, forKey: lastVersionPromptedForReviewKey)
        }
    }
    
    public var favoritesColumns: Int {
        get { return _favCols }
        set {
            if newValue > 0 {
                _favCols = newValue
                defaults.set(_favCols, forKey: favoritesColumnsKey)
            }
        }
    }
    
    public var favoritesRows: Int {
        get { return _favRows }
        set {
            if newValue > 0 {
                _favRows = newValue
                defaults.set(_favRows, forKey: favoritesRowsKey)
            }
        }
    }
    
    public var favoritesColumnWidth: String {
        get { return _favColWidth }
        set {
            if newValue.count > 0 {
                _favColWidth = newValue
                defaults.set(_favColWidth, forKey: favoritesColumnWidthKey)
            }
        }
    }
    
    /// get or set the chosen Markdown parser.
    public var markdownParser: String {
        get { return _mdParser }
        set {
            switch newValue {
            case "down", "ink":
                _mdParser = newValue
                defaults.set(newValue, forKey: markdownParserKey)
            case "notenik", "mkdown":
                _mdParser = "notenik"
                defaults.set("notenik", forKey: markdownParserKey)
            default:
                break
            }
        }
    }
    
    /// Are we using the Notenik Parser?
    public var notenikParser: Bool {
        return _mdParser == "notenik"
    }
    
    /// Given a file extension, return the next temp file to be used by Notenik.
    func nextTempFile(ext: String) -> URL? {
        guard tempDir != nil else { return nil }
        var fnm = "notenik-temp-\(_tempFileCount)"
        _tempFileCount += 1
        if ext.count > 0 {
            fnm.append(".\(ext)")
        }
        let tempFile = tempDir!.appendingPathComponent(fnm)
        do {
            try fileManager.removeItem(at: tempFile)
        } catch {
            // Not a problem. 
        }
        return tempFile
    }
    
    var networkMonitor: Any?
    public var networkAvailable = true
    
    @available(OSX 10.14, *)
    func initNetworkMonitor() {
        networkMonitor = NWPathMonitor()
        guard let monitor = networkMonitor as? NWPathMonitor else { return }
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.networkAvailable = true
            } else {
                self.networkAvailable = false
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "AppPrefs",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "AppPrefs",
                          level: .error,
                          message: msg)
    }
    
}
