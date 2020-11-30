//
//  CollectionFile.swift
//  
//
//  Created by Herb Bowie on 7/10/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class CollectionFile {
        
    var dir = ""
    var name = ""
    var path = ""
    var fileName: FileName
    
    var type = CollectionFileType.unknown
    
    init(dir: String, name: String) {
        self.dir = dir
        self.name = name
        path = FileUtils.joinPaths(path1: dir,
                                   path2: name)
        fileName = FileName(path)
        if FileUtils.isDir(path) {
            if name == NotenikConstants.reportsFolderName {
                type = .reportsFolder
            } else if name == NotenikConstants.mirrorFolderName {
                type = .mirrorFolder
            } else {
                type = .generalFolder
            }
        } else if fileName.readme {
            type = .readme
        } else if fileName.infofile {
            type = .infoFile
        } else if name == AliasList.aliasFileName {
            type = .aliasFile
        } else if fileName.dotfile {
            type = .dotFile
        } else if fileName.template {
            type = .templateFile
        } else if fileName.licenseFile {
            type = .licenseFile
        } else if fileName.collectionParms {
            type = .collectionParms
        } else if fileName.noteExt {
            type = .noteFile
        } else {
            type = .unknown
        }
    }
}
