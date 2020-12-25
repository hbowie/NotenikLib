//
//  LabelConstants.swift
//  Notenik
//
//  Created by Herb Bowie on 12/11/18.
//  Copyright © 2018 - 2020 Herb Bowie (https://powersurgepub.com)
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
    static let artist           = "Artist"
    static let artistCommon     = "artist"
    static let author           = "Author"
    static let authorCommon     = "author"
    static let body             = "Body"
    static let bodyCommon       = "body"
    static let bodyLabelDisplay = "Display Body Label"
    static let bodyLabelDisplayCommon = "displaybodylabel"
    static let code             = "Code"
    static let codeCommon       = "code"
    static let date             = "Date"
    public static let dateCommon       = "date"
    static let dateAdded        = "Date Added"
    static let dateAddedCommon  = "dateadded"
    static let dateModified     = "Date Modified"
    static let dateModifiedCommon = "datemodified"
    static let doubleBracketParsing = "Double Bracket Parsing"
    static let doubleBracketParsingCommon = "doublebracketparsing"
    static let h1TitlesDisplay  = "Display H1 Titles"
    static let h1TitlesDisplayCommon = "displayh1titles"
    static let index            = "Index"
    static let indexCommon      = "index"
    public static let link             = "Link"
    public static let linkCommon       = "link"
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
    static let rating           = "Rating"
    static let ratingCommon     = "rating"
    static let recurs           = "Recurs"
    public static let recursCommon     = "recurs"
    static let seq              = "Seq"
    static let seqCommon        = "seq"
    static let sortParm         = "Sort Parm"
    static let sortParmCommon   = "sortparm"
    static let sortDescending   = "Sort Descending"
    static let sortDescendingCommon = "sortdescending"
    static let lastStartupDate  = "Last Startup Date"
    static let lastStartupDateCommon = "laststartupdate"
    public static let status           = "Status"
    public static let statusCommon     = "status"
    static let tag              = "Tag"
    static let tagCommon        = "tag"
    static let tags             = "Tags"
    static let tagsCommon       = "tags"
    static let teaser           = "Teaser"
    static let teaserCommon     = "teaser"
    static let timestamp        = "Timestamp"
    static let timestampCommon  = "timestamp"
    static let title            = "Title"
    public static let titleCommon      = "title"
    static let type             = "Type"
    static let typeCommon       = "type"
    static let workID           = "Work ID"
    static let workIDcommon     = "workid"
    static let workLink         = "Work Link"
    static let workLinkCommon   = "worklink"
    static let workPages        = "Work Pages"
    static let workPagesCommon  = "workpages"
    static let workRights       = "Work Rights"
    static let workRightsCommon = "workrights"
    static let workRightsHolder = "Work Rights Holder"
    static let workRightsHolderCommon = "workrightsholder"
    static let workTitle        = "Work Title"
    static let workTitleCommon  = "worktitle"
    static let workType         = "Work Type"
    static let workTypeCommon   = "worktype"
    
    static let dateType         = "date"
    
    //-------------------------------------------------------------
    //
    // Default configuration values
    //
    //-------------------------------------------------------------
    
    static let defaultWebStatusConfig = "1 - Idea; 4 - In Work; 8 - Canceled; 9 - Published"
    
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
}
