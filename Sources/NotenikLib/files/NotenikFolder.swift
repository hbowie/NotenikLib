//
//  NotenikFolder.swift
//
//  Created by Herb Bowie on 8/26/20.
//
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A folder that is usable by Notenik either as a Collection or a Parent Realm. 
public class NotenikFolder: Comparable, CustomStringConvertible, Identifiable {
    
    public var type: NotenikFolderType = .undetermined
    public var location: NotenikFolderLocation = .undetermined
    public var path = ""
    public var url = URL(fileURLWithPath: "/")
    
    public var folderName: String { return url.lastPathComponent }
    
    public init(url: URL) {
        self.url = url
        path = url.path
    }
    
    public init(url: URL, isCollection: Bool) {
        self.url = url
        path = url.path
        if isCollection {
            type = .collection
        }
    }
    
    public init(url: URL, type: NotenikFolderType, location: NotenikFolderLocation) {
        self.url = url
        path = url.path
        self.type = type
        self.location = location
    }
    
    /// This method and the next provide conformance to the Comparable protocol.
    public static func < (lhs: NotenikFolder, rhs: NotenikFolder) -> Bool {
        return lhs.path < rhs.path
    }
    
    /// This method and the previous one provide conformance to the Comparable protocol.
    public static func == (lhs: NotenikFolder, rhs: NotenikFolder) -> Bool {
        return lhs.path == rhs.path
    }
    
    /// Provide a unique ID for every folder.
    public var id: String {
        return path
    }
    
    /// Provide a description of the object to conform to CustomStringConvertible protocol.
    public var description: String {
        return ("Notenik Folder type is \(type), location is \(location), path is \(path)")
    }
}
