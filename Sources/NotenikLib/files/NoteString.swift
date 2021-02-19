//
//  NoteString.swift
//  NotenikLib
//
//  Created by Herb Bowie on 2/18/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A String that can have Notenik fields appended to it, and that can be written to disk. 
class NoteString {
    
    var str = ""
    
    init() {
        
    }
    
    convenience init(title: String) {
        self.init()
        appendTitle(title)
    }
    
    func appendTitle(_ title: String) {
        append(label: NotenikConstants.title, value: title)
    }
    
    func appendLink(_ link: String) {
        append(label: NotenikConstants.link, value: link)
    }
    
    func append(label: String, value: String) {
        str.append("\(label): \(value)\n\n")
    }
    
    func write(toFile filePath: String) -> Bool {
        do {
            try str.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "NoteString",
                              level: .error,
                              message: "Problem writing file \(filePath) to disk!")
            return false
        }
        return true
    }
}
