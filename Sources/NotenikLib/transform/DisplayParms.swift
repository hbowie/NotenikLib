//
//  DisplayParms.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/7/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// All of the parameters used to control the way a Note is converted to HTML. 
public class DisplayParms {
    
    public var cssString = ""
    public var cssLinkToFile = false
    public var displayTemplate = ""
    public var format: MarkedupFormat = .htmlDoc
    public var sortParm: NoteSortParm = .seqPlusTitle
    public var streamlined = false
    public var wikiLinkFormat: WikiLinkFormat = .common
    public var wikiLinkPrefix = "https://ntnk.app/"
    public var wikiLinkSuffix = ""
    
    public init() {
        
    }
    
    
    public var formatIsHTML: Bool {
        switch format {
        case .htmlDoc, .htmlFragment:
            return true
        default:
            return false
        }
    }
    
    public var fullDisplay: Bool {
        return !streamlined
    }
    
    public func setCSS(useFirst: String, useSecond: String?) {
        if useFirst.count > 0 {
            cssString = useFirst
        } else if useSecond != nil {
            cssString = useSecond!
        } else {
            cssString = ""
        }
    }
    
    /// Create a wiki link, based on the wiki parms.
    func assembleWikiLink(title: String) -> String {
        return wikiLinkPrefix + formatWikiLink(title) + wikiLinkSuffix
    }
    
    /// Convert a title to something that can be used in a link.
    func formatWikiLink(_ title: String) -> String {
        switch wikiLinkFormat {
        case .common:
            return StringUtils.toCommon(title)
        case .fileName:
            return StringUtils.toCommonFileName(title)
        }
    }
    
    public func display(by: String) {
        print ("DisplayParms.display requested by \(by)")
        print("  - css string = \(cssString)")
        print("  - display template = \(displayTemplate)")
        print("  - marked up format = \(format)")
        print("  - sort parm = \(sortParm)")
        print("  - streamlined? \(streamlined)")
        print("  - wiki link format = \(wikiLinkFormat)")
        print("  - wiki link prefix = \(wikiLinkPrefix)")
        print("  - wiki link suffix = \(wikiLinkSuffix)")
    }
}