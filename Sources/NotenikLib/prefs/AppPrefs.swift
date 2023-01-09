//
//  AppPrefs.swift
//  Notenik
//
//  Created by Herb Bowie on 5/25/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
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
    let startupTipsKey  = "tips-at-startup"
    let mediumTokenKey  = "medium-token"
    let microBlogUserKey = "micro-blog-user"
    let microBlogTokenKey = "micro-blog-token"
    let mastodonUserNameKey = "mastodon-user-name"
    let mastodonDomainKey   = "mastodon-domain"
    let tagsSelectKey   = "tags-to-select"
    let tagsSuppressKey = "tags-to-suppress"
    let parentRealmParentKey = "parent-realm-parent"
    let useCountKey     = "use-count"
    let lastVersionPromptedForReviewKey = "last-version-prompted-for-review"
    let lastVersionNewsReportedForKey = "last-version-news-reported-for"
    
    let appAppearanceKey = "app-appearance"
    
    let indentSpacingKey = "indent-spacing"
    
    let favoritesColumnsKey = "favorites-columns"
    let favoritesRowsKey = "favorites-rows"
    let favoritesColumnWidthKey = "favorites-column-width"
    
    let markdownParserKey = "markdown-parser"
    
    let essentialURLKey = "essential-collection"
    var _essentialURL: URL?
    
    let lastURLKey = "last-collection"
    var _lastURL: URL?
    
    let shortcutsKey = "shortcuts"
    var _shortcuts = ""
    
    let lastShortcutKey = "last-shortcut"
    var _lastShortcut = ""
    
    let noteActionKey = "note-action"
    var _noteAction = ""
    
    let dateContentKey = "date-content"
    var _dateContent = ""
    
    let dateFormatKey = "date-format"
    var _dateFormat = ""
    
    let customDateFormatKey = "custom-date-format"
    var _customDateFormat = ""
    
    let tipsWindowKey = "tips-window"
    var _tipsWindow = ""
    
    let mastHandleKey = "mastodon-handle"
    var _mastHandle = ""
    
    let mastDomainKey = "mastodon-domain"
    var _mastDomain = ""
    
    let idFolderLevelsKey = "id-folder-levels"
    var _idFolderLevels = 2
    
    let idFolderSepKey = "id-folder-sep"
    var _idFolderSep = " / "
    
    let kbWindowKey = "nkb-window"
    var _kbWindow = ""
    
    let mcWindowKey = "master-class-window"
    var _mcWindow = ""
    
    let grantAccessKey = "grant-access"
    var _grantAccessOpt = 1
    
    let queryOutKey = "query-output-window-numbers"
    var _queryOut = ""
    
    var _appLaunching = false
    
    var _qd: Bool = false
    
    var _appearance = "system"
    
    var _indentSpacing = 1
    
    var _startupTips = true
    
    var _mediumToken = ""
    
    var _mastodonUserName = ""
    var _mastodonDomain = ""
    
    var _microBlogUser = ""
    var _microBlogToken = ""
    
    var _prp = ""
    public var parentRealmPath = ""
    
    public var pickLists = ValuePickLists()
    
    var _tsel = ""
    var _tsup = ""
    
    var _uc = 0
    
    var _lvpfr = ""
    var _lvnews = ""
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
        if #available(OSX 10.14, iOS 12.0, *) {
            initNetworkMonitor()
        }
    }
    
    func resetDefaults() {
        confirmDeletes = true
        tipsAtStartup = true
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
        
        _startupTips = defaults.bool(forKey: startupTipsKey)
        
        let mediumTokenDefault = defaults.string(forKey: mediumTokenKey)
        if mediumTokenDefault != nil {
            _mediumToken = mediumTokenDefault!
        }
        
        let mastodonDomainDefault = defaults.string(forKey: mastodonDomainKey)
        if mastodonDomainDefault != nil {
            _mastodonDomain = mastodonDomainDefault!
        }
        
        let mastodonUserNameDefault = defaults.string(forKey: mastodonUserNameKey)
        if mastodonUserNameDefault != nil {
            _mastodonUserName = mastodonUserNameDefault!
        }
        
        let microBlogUserDefault = defaults.string(forKey: microBlogUserKey)
        if microBlogUserDefault != nil {
            _microBlogUser = microBlogUserDefault!
        }
        
        let microBlogTokenDefault = defaults.string(forKey: microBlogTokenKey)
        if microBlogTokenDefault != nil {
            _microBlogToken = microBlogTokenDefault!
        }
        
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
        
        let scuts = defaults.string(forKey: shortcutsKey)
        if scuts != nil {
            _shortcuts = scuts!
        }
        
        let lcut = defaults.string(forKey: lastShortcutKey)
        if lcut != nil {
            _lastShortcut = lcut!
        }
        
        let ntact = defaults.string(forKey: noteActionKey)
        if ntact != nil {
            _noteAction = ntact!
        }
        
        let dtcon = defaults.string(forKey: dateContentKey)
        if dtcon != nil && !dtcon!.isEmpty {
            _dateContent = dtcon!
        }
        
        let dtfor = defaults.string(forKey: dateFormatKey)
        if dtfor != nil && !dtfor!.isEmpty {
            _dateFormat = dtfor!
        }
        
        let dtcus = defaults.string(forKey: customDateFormatKey)
        if dtcus != nil && !dtcus!.isEmpty {
            _customDateFormat = dtcus!
        }
        
        let tipsw = defaults.string(forKey: tipsWindowKey)
        if tipsw != nil {
            _tipsWindow = tipsw!
        }
        
        let nkbw = defaults.string(forKey: kbWindowKey)
        if nkbw != nil {
            _kbWindow = nkbw!
        }
        
        let nmcw = defaults.string(forKey: mcWindowKey)
        if nmcw != nil {
            _mcWindow = nmcw!
        }
        
        let aa = defaults.string(forKey: appAppearanceKey)
        if aa != nil {
            _appearance = aa!
        }
        
        let mh = defaults.string(forKey: mastHandleKey)
        if mh != nil {
            _mastHandle = purifyHandle(handle: mh!)
        }
        
        let md = defaults.string(forKey: mastDomainKey)
        if md != nil {
            _mastDomain = purifyDomain(domain: md!)
        }
        
        let isp = defaults.integer(forKey: indentSpacingKey)
        if isp > 9 {
            _indentSpacing = 0
        } else if isp == 0 {
            _indentSpacing = 1
        } else {
            _indentSpacing = isp
        }
        
        let gao = defaults.integer(forKey: grantAccessKey)
        if gao > 0 && gao <= 2 {
            _grantAccessOpt = gao
        } else if gao == 3 {
            _grantAccessOpt = 2
        }
        
        let idf = defaults.integer(forKey: idFolderLevelsKey)
        if idf > 0 {
            _idFolderLevels = idf
        } else {
            _idFolderLevels = 2
        }
        
        _idFolderSep = " / "
        if let ids = defaults.string(forKey: idFolderSepKey) {
            if !ids.isEmpty {
                _idFolderSep = ids
            }
        } 
        
        if let qout = defaults.string(forKey: queryOutKey) {
            _queryOut = qout
        }
        
        _uc = defaults.integer(forKey: useCountKey)
        
        // Get the Last Version Prompted for Review.
        let lvpfr = defaults.string(forKey: lastVersionPromptedForReviewKey)
        if lvpfr != nil {
            _lvpfr = lvpfr!
        }
        
        // Get the Last Version News Was Reported For.
        let lvnews = defaults.string(forKey: lastVersionNewsReportedForKey)
        if lvnews != nil {
            _lvnews = lvnews!
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
    
    public var appAppearance: String {
        get {
            return _appearance
        }
        set {
            _appearance = newValue
            defaults.set(_appearance, forKey: appAppearanceKey)
        }
    }
    
    public var mastodonHandle: String {
        get {
            return _mastHandle
        }
        set {
            _mastHandle = purifyHandle(handle: newValue)
            defaults.set(_mastHandle, forKey: mastHandleKey)
        }
    }
    
    public func purifyHandle(handle: String) -> String {
        if handle.starts(with: "@") {
            return String(handle.dropFirst(1))
        } else {
            return handle
        }
    }
    
    public var mastodonDomain: String {
        get {
            return _mastDomain
        }
        set {
            _mastDomain = purifyDomain(domain: newValue)
            defaults.set(_mastDomain, forKey: mastDomainKey)
        }
    }
    
    public func purifyDomain(domain: String) -> String {
        if domain.starts(with: "https://") {
            return String(domain.dropFirst(8))
        } else {
            return domain
        }
    }
    
    public var indentSpacing: Int {
        get {
            return _indentSpacing
        }
        set {
            _indentSpacing = newValue
            if _indentSpacing == 0 {
                defaults.set(10, forKey: indentSpacingKey)
            } else {
                defaults.set(_indentSpacing, forKey: indentSpacingKey)
            }
        }
    }
    
    public func indentSpaces(level: Int) -> String {
        return String(repeating: " ", count: level * _indentSpacing)
    }
    
    public var grantAccessOption: Int {
        get {
            return _grantAccessOpt
        }
        set {
            _grantAccessOpt = newValue
            defaults.set(_grantAccessOpt, forKey: grantAccessKey)
        }
    }
    
    public var queryOutputWindowNumbers: String {
        get {
            return _queryOut
        }
        set {
            _queryOut = newValue
            defaults.set(_queryOut, forKey: queryOutKey)
        }
    }
    
    public var tipsAtStartup: Bool {
        get {
            return _startupTips
        }
        set {
            _startupTips = newValue
            defaults.set(_startupTips, forKey: startupTipsKey)
        }
    }
    
    public var mediumToken: String {
        get {
            return _mediumToken
        }
        set {
            _mediumToken = newValue
            defaults.set(_mediumToken, forKey: mediumTokenKey)
        }
    }
    
    public var mastodonUserName: String {
        get {
            return _mastodonUserName
        }
        set {
            _mastodonUserName = newValue
            defaults.set(_mastodonUserName, forKey: mastodonUserNameKey)
        }
    }
    
    public var microBlogUser: String {
        get {
            return _microBlogUser
        }
        set {
            _microBlogUser = newValue
            defaults.set(_microBlogUser, forKey: microBlogUserKey)
        }
    }
    
    public var microBlogToken: String {
        get {
            return _microBlogToken
        }
        set {
            _microBlogToken = newValue
            defaults.set(_microBlogToken, forKey: microBlogTokenKey)
        }
    }
    
    /// The number of folders to be included in the user-facing identification of a Collection.
    public var idFolderLevels: Int {
        get {
            return _idFolderLevels
        }
        set {
            _idFolderLevels = newValue
            defaults.set(_idFolderLevels, forKey: idFolderLevelsKey)
        }
    }
    
    public var idFolderSep: String {
        get {
            return _idFolderSep
        }
        set {
            _idFolderSep = newValue
            defaults.set(_idFolderSep, forKey: idFolderSepKey)
        }
    }
    
    public func idFolderFrom(url: URL, below: URL? = nil) -> String {
        let folders = url.pathComponents
        var folderIndex = folders.count - idFolderLevels
        if let parentURL = below {
            if folderIndex < parentURL.pathComponents.count {
                folderIndex = parentURL.pathComponents.count
            }
        }
        var workingID = ""
        while folderIndex < folders.count {
            let folder = folders[folderIndex]
            switch folder {
            case "Library", "Documents", "Mobile Documents", "iCloud~com~powersurgepub~notenik~shared", "com~apple~CloudDocs":
                folderIndex += 1
            case "Users":
                folderIndex += 2
            default:
                if folderIndex > 0 && folders[folderIndex - 1] != "Users" {
                    if !workingID.isEmpty {
                        workingID.append(idFolderSep)
                    }
                    workingID.append(folder)
                }
                folderIndex += 1
            }
        }
        return workingID
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
    
    public var shortcuts: String {
        get {
            return _shortcuts
        }
        set {
            _shortcuts = newValue
            defaults.set(_shortcuts, forKey: shortcutsKey)
        }
    }
    
    public var lastShortcut: String {
        get {
            return _lastShortcut
        }
        set {
            _lastShortcut = newValue
            defaults.set(_lastShortcut, forKey: lastShortcutKey)
        }
    }
    
    public var noteAction: String {
        get {
            return _noteAction
        }
        set {
            _noteAction = newValue
            defaults.set(_noteAction, forKey: noteActionKey)
        }
    }
    
    public var dateContent: String {
        get {
            return _dateContent
        }
        set {
            _dateContent = newValue
            defaults.set(_dateContent, forKey: dateContentKey)
        }
    }
    
    public var dateFormat: String {
        get {
            return _dateFormat
        }
        set {
            _dateFormat = newValue
            defaults.set(_dateFormat, forKey: dateFormatKey)
        }
    }
    
    public var customDateFormat: String {
        get {
            return _customDateFormat
        }
        set {
            _customDateFormat = newValue
            defaults.set(_customDateFormat, forKey: customDateFormatKey)
        }
    }
    
    public var tipsWindow: String {
        get {
            return _tipsWindow
        }
        set {
            _tipsWindow = newValue
            defaults.set(_tipsWindow, forKey: tipsWindowKey)
        }
    }
    
    public var kbWindow: String {
        get {
            return _kbWindow
        }
        set {
            _kbWindow = newValue
            defaults.set(_kbWindow, forKey: kbWindowKey)
        }
    }
    
    public var mcWindow: String {
        get {
            return _mcWindow
        }
        set {
            _mcWindow = newValue
            defaults.set(_mcWindow, forKey: mcWindowKey)
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
    
    public func userShownNews() {
        lastVersionShownNews = currentVersion
    }
    
    public var newVersionForNews: Bool {
        return currentVersion > lastVersionShownNews
    }
    
    var lastVersionShownNews: String {
        get {
            return _lvnews
        }
        set {
            _lvnews = newValue
            defaults.set(_lvnews, forKey: lastVersionNewsReportedForKey)
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
    
    public var parseUsingNotenik: Bool {
        return (_mdParser == "notenik")
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
    
    @available(iOS 12.0, *)
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
