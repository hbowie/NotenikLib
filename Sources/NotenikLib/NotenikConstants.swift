//
//  LabelConstants.swift
//  Notenik
//
//  Created by Herb Bowie on 12/11/18.
//  Copyright © 2018 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Various constants used throughout Notenik.
public struct NotenikConstants {
    
    //-------------------------------------------------------------
    //
    // Field Labels
    //
    //-------------------------------------------------------------
    public static let artist        = "Artist"
    public static let artistCommon  = "artist"
    public static let author        = "Author"
    public static let authorCommon  = "author"
    public static let body          = "Body"
    public static let bodyCommon    = "body"
    static let bodyLabelDisplay     = "Display Body Label"
    static let bodyLabelDisplayCommon = "displaybodylabel"
    public static let code          = "Code"
    public static let codeCommon    = "code"
    public static let date          = "Date"
    public static let dateCommon = "date"
    public static let dateAdded = "Date Added"
    public static let dateAddedCommon  = "dateadded"
    public static let dateModified = "Date Modified"
    static let dateModifiedCommon = "datemodified"
    static let doubleBracketParsing = "Double Bracket Parsing"
    static let doubleBracketParsingCommon = "doublebracketparsing"
    static let h1TitlesDisplay  = "Display H1 Titles"
    static let h1TitlesDisplayCommon = "displayh1titles"
    public static let index     = "Index"
    public static let indexCommon = "index"
    public static let link      = "Link"
    public static let linkCommon = "link"
    static let mirrorAutoIndex  = "Mirror Auto Index"
    static let mirrorAutoIndexCommon = "mirrorautoindex"
    static let noteFileFormat   = "Note File Format"
    static let noteFileFormatCommon = "notefileformat"
    static let otherFields      = "Other Fields Allowed"
    static let otherFieldsCommon = "otherfieldsallowed"
    static let publisher        = "Publisher"
    static let publisherCommon  = "publisher"
    static let pubCity          = "Publisher City"
    static let pubCityCommon    = "publishercity"
    public static let rating        = "Rating"
    public static let ratingCommon  = "rating"
    public static let recurs        = "Recurs"
    public static let recursCommon  = "recurs"
    public static let seq       = "Seq"
    public static let seqCommon = "seq"
    static let sortParm         = "Sort Parm"
    static let sortParmCommon   = "sortparm"
    static let sortDescending   = "Sort Descending"
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
    public static let timestamp     = "Timestamp"
    public static let timestampCommon = "timestamp"
    public static let title         = "Title"
    public static let titleCommon   = "title"
    public static let type          = "Type"
    public static let typeCommon    = "type"
    public static let url           = "URL"
    public static let urlCommon     = "url"
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
    public static let workType         = "Work Type"
    public static let workTypeCommon   = "worktype"
    
    //-------------------------------------------------------------
    //
    // Field Type strings (if different from label)
    //
    //-------------------------------------------------------------
    
    public static let dateType          = "date"
    public static let longTextType      = "longtext"
    public static let stringType        = "string"
    public static let pickFromType      = "pickfrom"
    
    //-------------------------------------------------------------
    //
    // Other constants
    //
    //-------------------------------------------------------------
    
    public static let idFieldIdentifier = "id"
    
    //-------------------------------------------------------------
    //
    // Default configuration values
    //
    //-------------------------------------------------------------
    
    static let defaultWebStatusConfig = "1 - Idea; 4 - In Work; 8 - Canceled; 9 - Published"
    
    //-------------------------------------------------------------
    //
    // Labels used for Info file.
    //
    //-------------------------------------------------------------
    
    static let lastIndexSelected = "Last Index Selected"
    
    //-------------------------------------------------------------
    //
    // Files and folders
    //
    //-------------------------------------------------------------
    
    public static let aliasFileName     = "alias.txt"
    public static let infoFileName      = "- INFO.nnk"
    public static let readmeFileName    = "- README.txt"
    public static let templateFileName  = "template"
    public static let notesFolderName   = "notes"
    public static let filesFolderName   = "files"
    public static let mirrorFolderName  = "mirror"
    public static let reportsFolderName = "reports"
    public static let scriptExt         = ".tcz"
    public static let indexFileName     = "index.html"
    
    public static let oldSourceParms    = "pspub_source_parms.xml"
    
    public static let urlNavPrefix      = "https://ntnk.app/"
    
    //-------------------------------------------------------------
    //
    // Paths and Labels for Collections of Help Notes
    //
    //-------------------------------------------------------------
    
    public static let macIntroPath        = "intro"
    public static let macIntroDesc        = "Introduction to Notenik"
    
    public static let macUserGuidePath    = "notenik-swift-intro"
    public static let macUserGuideDesc    = "User Guide"
    
    public static let fieldNotesPath      = "fields"
    public static let fieldNotesDesc      = "Field Labels and Types"
    
    public static let markdownSpecPath    = "markdown-spec"
    public static let markdownSpecDesc    = "Markdown Spec"
    
    public static let iosIntroPath        = "intro-ios"
    public static let iosIntroDesc        = "Introduction to Notenik"
}
