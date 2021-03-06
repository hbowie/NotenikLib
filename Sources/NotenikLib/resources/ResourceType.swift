//
//  ResourceType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/27/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Identifies the various types of resources available within a particular Notenik Collection.
public enum ResourceType {
    case alias
    case attachment
    case attachments
    case collection
    case collectionParms
    case info
    case license
    case mirror
    case noise
    case note 
    case notes
    case notesSubfolder
    case parent
    case readme
    case reports
    case report
    case script
    case template
    case unknown
}
