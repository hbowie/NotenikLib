//
//  NotenikConstants.swift
//  Notenik
//
//  Created by Herb Bowie on 12/11/18.
//  Copyright © 2018 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Various constants used throughout Notenik.
public struct NotenikConstants {
    
    //-------------------------------------------------------------
    //
    // Field Labels
    //
    //-------------------------------------------------------------
    public static let address           = "Address"
    public static let addressCommon     = "address"
    public static let aka               = "AKA"
    public static let akaCommon         = "aka"
    public static let artist            = "Artist"
    public static let artistCommon      = "artist"
    public static let attachments       = "Attachments"
    public static let attachmentsCommon = "attachments"
    public static let attribution       = "Attribution"
    public static let attribCommon      = "attribution"
    public static let author            = "Author"
    public static let authorCommon      = "author"
    public static let authorLinkCommon  = "authorlink"
    public static let backlinks         = "Backlinks"
    public static let backlinksCommon   = "backlinks"
    public static let body              = "Body"
    public static let bodyCommon        = "body"
    static let bodyLabelDisplay         = "Display Body Label"
    static let bodyLabelDisplayCommon   = "displaybodylabel"
    public static let code              = "Code"
    public static let codeCommon        = "code"
    public static let date              = "Date"
    public static let dateCommon        = "date"
    public static let dateAdded         = "Date Added"
    public static let dateAddedCommon   = "dateadded"
    public static let dateModified      = "Date Modified"
    public static let dateModifiedCommon = "datemodified"
    public static let directions        = "Directions"
    public static let directionsCommon  = "directions"
    public static let directionsRequested = "directions-requested"
    static let doubleBracketParsing     = "Double Bracket Parsing"
    static let doubleBracketParsingCommon = "doublebracketparsing"
    public static let duration          = "Duration"
    public static let durationCommon    = "duration"
    public static let email             = "Email"
    public static let emailCommon       = "email"
    public static let folder            = "Folder"
    public static let folderCommon      = "folder"
    public static let imageAlt          = "Image Alt"
    public static let imageAltCommon    = "imagealt"
    public static let imageCaption      = "Image Caption"
    public static let imageCaptionCommon = "imagecaption"
    public static let imageCredit       = "Image Credit"
    public static let imageCreditCommon = "imagecredit"
    public static let imageCreditLink   = "Image Credit Link"
    public static let imageCreditLinkCommon = "imagecreditlink"
    public static let imageName         = "Image Name"
    public static let imageNameCommon   = "imagename"
    public static let includeChildren   = "Include Children"
    public static let includeChildrenCommon = "includechildren"
    public static let index             = "Index"
    public static let indexCommon       = "index"
    public static let klass             = "Class"
    public static let klassCommon       = "class"
    public static let level             = "Level"
    public static let levelCommon       = "level"
    public static let link              = "Link"
    public static let linkCommon        = "link"
    public static let minutesToRead     = "Minutes to Read"
    public static let minutesToReadCommon = "minutestoread"
    public static let mirrorAutoIndex   = "Mirror Auto Index"
    public static let mirrorAutoIndexCommon = "mirrorautoindex"
    public static let otherFields       = "Other Fields Allowed"
    public static let otherFieldsCommon = "otherfieldsallowed"
    public static let pageStyle         = "Page Style"
    public static let pageStyleCommon   = "pagestyle"
    public static let person            = "Person"
    public static let personCommon      = "person"
    public static let phone             = "Phone"
    public static let phoneCommon = "phone"
    static let publisher        = "Publisher"
    static let publisherCommon  = "publisher"
    static let pubCity          = "Publisher City"
    static let pubCityCommon    = "publishercity"
    public static let rank          = "Rank"
    public static let rankCommon    = "rank"
    public static let rating        = "Rating"
    public static let ratingCommon  = "rating"
    public static let recurs        = "Recurs"
    public static let recursCommon  = "recurs"
    public static let seq           = "Seq"
    public static let seqCommon     = "seq"
    public static let displaySeq    = "Display Seq"
    public static let displaySeqCommon = "displayseq"
    public static let shortId       = "Short ID"
    public static let shortIdCommon = "shortid"
    public static let sortBlankDatesLast = "Sort Blank Dates Last"
    public static let sortBlankDatesLastCommon = "sortblankdateslast"
    static let sortParm             = "Sort Parm"
    static let sortParmCommon       = "sortparm"
    static let sortDescending       = "Sort Descending"
    static let sortDescendingCommon = "sortdescending"
    static let lastStartupDate  = "Last Startup Date"
    static let lastStartupDateCommon = "laststartupdate"
    public static let status    = "Status"
    public static let statusCommon = "status"
    static let tag              = "Tag"
    static let tagCommon        = "tag"
    public static let tags          = "Tags"
    public static let tagsCommon    = "tags"
    public static let teaser        = "Teaser"
    public static let teaserCommon  = "teaser"
    public static let textFormat       = "Text Format"
    public static let textFormatCommon = "textformat"
    public static let timestamp        = "Timestamp"
    public static let timestampCommon  = "timestamp"
    public static let title         = "Title"
    public static let titleCommon   = "title"
    public static let type          = "Type"
    public static let typeCommon    = "type"
    public static let url           = "URL"
    public static let urlCommon     = "url"
    public static let wikilinks     = "Wiki Links"
    public static let wikilinksCommon = "wikilinks"
    public static let workDateCommon = "workdate"
    static let workID           = "Work ID"
    static let workIDcommon     = "workid"
    public static let workLink         = "Work Link"
    public static let workLinkCommon   = "worklink"
    static let workPages        = "Work Pages"
    static let workPagesCommon  = "workpages"
    static let workRights       = "Work Rights"
    static let workRightsCommon = "workrights"
    static let workRightsHolder = "Work Rights Holder"
    static let workRightsHolderCommon = "workrightsholder"
    public static let workTitle        = "Work Title"
    public static let workTitleCommon  = "worktitle"
    public static let workLargerTitle  = "Work Larger Title"
    public static let workLargerTitleCommon = "worklargertitle"
    public static let workType         = "Work Type"
    public static let workTypeCommon   = "worktype"
    
    //-------------------------------------------------------------
    //
    // Derived fields that can be used in merge templates.
    //
    //-------------------------------------------------------------
    
    public static let authorWorkSlugCommon = "authorworkslug"
    public static let imageSlugCommon      = "imageslug"
    public static let imageNameShortCommon = "imagenameshort"
    public static let theWorkTypeSlugCommon = "theworktypeslug"
    public static let majorWorkCommon      = "majorwork"
    public static let workRightsSlugCommon = "workrightsslug"
    public static let knownWorkTitleCommon = "knownworktitle"
    public static let parentSlugCommon     = "parentslug"
    public static let nextSlugCommon       = "nextslug"
    public static let childrenSlugCommon   = "childrenslug"
    public static let titleDisplaySlugCommon = "titledisplayslug"
    public static let uniqueIdCommon       = "uniqueidfornote"
    
    
    //-------------------------------------------------------------
    //
    // Field Type strings (if different from label)
    //
    //-------------------------------------------------------------
    
    public static let booleanType       = "boolean"
    public static let comboType         = "combo"
    public static let dateType          = "date"
    public static let labelType         = "label"
    public static let longTextType      = "longtext"
    public static let lookupType        = "lookup"
    public static let lookBackType      = "lookback"
    public static let stringType        = "string"
    public static let pickFromType      = "pickfrom"
    
    //-------------------------------------------------------------
    //
    // Constant field values
    //
    //-------------------------------------------------------------
    
    public static let textFormatMarkdown  = "Markdown"
    public static let textFormatMarkdownCommon = "markdown"
    public static let textFormatPlainText = "Plain Text"
    public static let textFormatPlainTextCommon = "plaintext"
    public static let textFormatMD        = "md"
    public static let textFormatTxt       = "txt"
    
    //-------------------------------------------------------------
    //
    // Standard Klass Values
    //
    //-------------------------------------------------------------
    
    public static let authorKlass       = "author"
    public static let backKlass         = "back"
    public static let biblioKlass       = "biblio"
    public static let excludeKlass      = "exclude"
    public static let frontKlass        = "front"
    public static let introKlass        = "intro"
    public static let prefaceKlass      = "preface"
    public static let quoteKlass        = "quote"
    public static let quotationKlass    = "quotation"
    public static let titleKlass        = "title-page"
    public static let tocKlass          = "toc"
    public static let workKlass         = "work"
    public static let defaultsKlass     = "defaults"
    public static let imageKlass        = "notenik-image"
    
    //-------------------------------------------------------------
    //
    // Parser Identifiers
    //
    //-------------------------------------------------------------
    
    public static let downParser    = "down"
    public static let inkParser     = "ink"
    public static let notenikParser = "notenik"
    
    //-------------------------------------------------------------
    //
    // Other constants
    //
    //-------------------------------------------------------------
    
    public static let idFieldIdentifier = "id"
    public static let checkBoxMessageHandlerName = "ckBoxHandler"
    
    //-------------------------------------------------------------
    //
    // Default configuration values
    //
    //-------------------------------------------------------------
    
    static let defaultWebStatusConfig = "1 - Idea; 4 - In Work; 8 - Canceled; 9 - Published"
    
    //-------------------------------------------------------------
    //
    // Labels used for storage of Collection Parms in Info file.
    //
    //-------------------------------------------------------------
    
    static let lastIndexSelected        = "Last Index Selected"
    static let shortcut                 = "Shortcut"
    static let h1TitlesDisplay          = "Display H1 Titles"
    static let h1TitlesDisplayCommon    = "displayh1titles"
    static let titleDisplayOpt          = "Title Display Option"
    static let titleDisplayOptCommon    = "titledisplayoption"
    static let webBookFolder            = "Web Book Folder"
    static let webBookFolderCommon      = "webbookfolder"
    static let webBookEPUB              = "Web Book EPUB"
    static let webBookEPUBCommon        = "webbookepub"
    static let mathJax                  = "MathJax"
    static let mathJaxCommon            = "mathjax"
    static let imgLocal                 = "Local Images"
    static let imgLocalCommon           = "localimages"
    static let missingTargets           = "Missing Targets"
    static let missingTargetsCommon     = "missingtargets"
    static let curlyAposts              = "Curly Apostrophes"
    static let curlyApostsCommon        = "curlyapostrophes"
    static let extLinksNewWindows       = "Ext Links Open in New Windows"
    static let extLinksNewWindowsCommon = "extlinksopeninnewwindows"
    static let scrollingSync            = "Scrolling Sync"
    static let scrollingSyncCommon      = "scrollingsync"
    static let windowNumbers            = "Window Numbers"
    static let windowNumbersCommon      = "windownumbers"
    static let columnWidths             = "Column Widths"
    static let columnWidthsCommon       = "columnwidths"
    static let noteFileFormat           = "Note File Format"
    static let noteFileFormatCommon     = "notefileformat"
    static let hashTags                 = "Hash Tags"
    static let hashTagsCommon           = "hashtags"
    static let titleSetByUser           = "Title Set by User"
    static let titleSetByUserCommon     = "titlesetbyuser"
    static let highestTitleNumber       = "Highest Title Number"
    static let highestTitleNumberCommon = "highesttitlenumber"
    static let displayMode              = "Display Mode"
    static let displayModeCommon        = "displaymode"
    static let overrideCustomDisplay    = "Override Custom Display"
    static let overrideCustomDisplayCommon = "overridecustomdisplay"
    static let noteIdAux                = "Note ID Aux Field"
    static let noteIdAuxCommon          = "noteidauxfield"
    static let noteIdRule               = "Note ID Rule"
    static let noteIdRuleCommon         = "noteidrule"
    static let textIdRule               = "Text ID Rule"
    static let textIdRuleCommon         = "textidrule"
    static let textIdSep                = "Text ID Separator"
    static let textIdSepCommon          = "textidseparator"
    static let minBodyEditViewHeight    = "Minimum Body Edit View Height"
    static let minBodyEditViewHeightCommon = "minimumbodyeditviewheight"
    static let lastImportParent         = "Last Import Parent"
    static let lastImportParentCommon   = "lastimportparent"
    static let outlineTab               = "Outline Tab"
    static let outlineTabCommon         = "outlinetab"
    
    public static let listDisplayFont   = "list-display-font"
    public static let listDisplaySize   = "list-display-size"
    
    //-------------------------------------------------------------
    //
    // Files and folders
    //
    //-------------------------------------------------------------
    
    public static let aliasFileName     = "alias.txt"
    
    public static let displayCSSFileName = "display.css"
    
    public static let displayHTMLFileName = "display.html"
    
    public static let exportFolderName  = "export"
    
    public static let klassFolderName   = "class"
    
    public static let notenikFiles      = "- notenik_files"
    
    public static let indexFileName     = "index.html"
    
    public static let urlNavPrefix      = "https://ntnk.app/"
    
    public static let mirrorFolderName  = "mirror"
    
    public static let notenikURLScheme  = "notenik"
    
    public static let notesFolderName   = "notes"
    
    public static let readmeFileName    = "- README.txt"
    
    public static let reportsFolderName = "reports"
    
    public static let scriptsFolderName = "scripts"
    
    public static let scriptExt         = FileExtension("tcz")
    public static let scriptExtAlt      = FileExtension("tsv")
    
    public static let BBEditProjectExt  = FileExtension(".bbprojectd")
    public static let webLocExt         = FileExtension(".webloc")
    
    public static let templateFileName  = "template"
    
    public static let tempDisplayBase   = "temp_display"
    
    public static let tempDisplayExt    = "html"
    
    public static let filesFolderName   = "files"
    
    public static let infoFileExt       = "nnk"
    
    public static let infoFileName      = "- INFO.nnk"
    
    public static let infoParentFileName = "- INFO-parent-realm.nnk"
    
    public static let infoProjectFileName = "- project-INFO.nnk"
    
    //-------------------------------------------------------------
    //
    // Paths and Labels for Collections of Help Notes
    //
    //-------------------------------------------------------------
    
    public static let iosIntroPath        = "intro-ios"
    public static let iosIntroDesc        = "Introduction to Notenik"
    
    public static let kbPath              = "NotenikDocs/knowledge-base"
    public static let kbDesc              = "Notenik Knowledge Base"
    
    public static let tipsPath            = "NotenikDocs/tips"
    public static let tipsDesc            = "Notenik Tips"
    
    public static let mcPath              = "NotenikDocs/master-class"
    public static let mcDesc              = "Notenik Master Class"
    
    //-------------------------------------------------------------
    //
    // Web locations
    //
    //-------------------------------------------------------------
    
    public static let webNotenik          = "https://notenik.app"
    public static let webDonate           = "https://ko-fi.com/hbowie"
    public static let webForum            = "https://discourse.notenik.app"
    public static let webIntro            = "https://notenik.app/intro/welcome-to-notenik.html"
    public static let webVid101           = "https://youtu.be/JR0kpAUXM5E"
    public static let webMacAppStoreRate  = "https://itunes.apple.com/app/id1465997984?action=write-review"

}
