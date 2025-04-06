//
//  ResourceType.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/27/21.
//
//  Copyright © 2021-2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Identifies the various types of resources available within a particular Notenik Collection.
public enum ResourceType {
    case addinsFolder
    case alias
    case attachment
    case attachments
    case collection
    case collectionParms
    case cssFolder
    case display
    case displayCSS
    case exportFolder
    case exportScript
    case folder
    case info
    case infoConflicted
    case infoParent
    case infoStarterPack
    case klassFolder
    case license
    case mirror
    case noise
    case note
    case notenikFiles
    case notenikFilesSubfolder
    case notes
    case notesSubfolder
    case robots
    case parent
    case readme
    case reports
    case report
    case script
    case shareTemplatesFolder
    case tempDisplay
    case template
    case unknown
}
