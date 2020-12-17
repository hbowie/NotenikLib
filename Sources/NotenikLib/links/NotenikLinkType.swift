//
//  NotenikLinkType.swift
//
//  Created by Herb Bowie on 12/14/20.

//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public enum NotenikLinkType {
    
    case unknown                // type is yet to be determined
    
    case weblink                // some sort of web link using http or https
    
    case filelink               // some sort of file link
    
    case folder                 // some sort of folder
    case mirrorFolder           // folder named 'mirror'
    case reportsFolder          // folder named 'reports'
    case emptyFolder            // An empty folder
    
    case ordinaryCollection     // an ordinary notenik collection
    case webCollection          // collection with notes stashed into a 'notes' subfolder
    case realm                  // a folder that might contain collections
    
    case file                   // some sort of file
    
    case aliasFile              // A Notenik alias.txt file
    case collectionParms        // A collection parms xml file -- no longer used
    case dotFile                // a file (other than dsstore) with a name beginning with a dot
    case dsstore                // a dot DS_Store file - pretend it's not there
    case infoFile               // A Notenik info file
    case licenseFile            // A file named 'LICENSE'
    case noteFile               // A file with a valid note extension
    case readmeFile             // A file that wants to be read
    case templateFile           // A file named template
    case xcodeDev               // link to some sort of xcode internals
    
    case script                 // a script file, with an extension of '.tcz'
    case mailto
    
    case wikiLink               // a pseudo-link to another note within notenik
    
    case notenikApp             // a webkit link to the notenik app itself
    
}


