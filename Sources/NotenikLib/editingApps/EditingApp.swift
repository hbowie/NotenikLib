//
//  EditingApp.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/21/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class EditingApp: Comparable {
    
    public var url: URL!
    public var path = ""
    public var name = ""
    public var nameLowered = ""
    
    public init(path: String) {
        let url = URL(fileURLWithPath: path)
        self.url = url
        deriveFromURL()
    }
    
    public init(url: URL) {
        self.url = url
        deriveFromURL()
    }
    
    func deriveFromURL() {
        path = pathWithoutSlash(url: url)
        name = url.deletingPathExtension().lastPathComponent
        nameLowered = name.lowercased()
    }
    
    func pathWithoutSlash(url: URL) -> String {
        var path = url.absoluteString
        if path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }
    
    public var isKnownEditor: Bool {
        switch nameLowered {
        case "bbedit":
            return true
        case "coteditor":
            return true
        case "ia writer":
            return true
        case "iwriter pro":
            return true
        case "macdown 3000":
            return true
        case "marked 2":
            return true
        case "markedit":
            return true
        case "multimarkdown composer":
            return true
        case "nova":
            return true
        case "textedit":
            return true
        case "typora":
            return true
        default:
            return false
        }
    }
    
    public static func < (lhs: EditingApp, rhs: EditingApp) -> Bool {
        return lhs.nameLowered < rhs.nameLowered
    }
    
    public static func == (lhs: EditingApp, rhs: EditingApp) -> Bool {
        return lhs.nameLowered == rhs.nameLowered
    }
    
}
