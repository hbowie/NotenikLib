//
//  CustomURLFormatter.swift
//  Notenik
//
//  Created by Herb Bowie on 4/16/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Format a Notenik Custom URL. 
public class CustomURLFormatter {
    
    var link = ""
    
    public init() {
        
    }
    
    public func expandTag(collection: NoteCollection, tag: TagValue) -> String {
        
        initWithScheme()
        addExpandCommand()
        identifyCollection(collection: collection)
        link.append("&tag=\(tag.description)")
        percentEncode()
        return link
    }
    
    public func open(collection: NoteCollection) -> String {
        initWithScheme()
        addOpenCommand()
        identifyCollection(collection: collection)
        percentEncode()
        return link
    }
    
    public func openWithUniqueID(collection: NoteCollection) -> String {
        initWithScheme()
        addOpenCommand()
        identifyCollection(collection: collection)
        link.append("&id==$\(NotenikConstants.uniqueIdCommon)&i$=")
        percentEncode()
        return link
    }
    
    func initWithScheme() {
        link = "notenik://"
    }
    
    func addExpandCommand() {
        link.append("expand?")
    }
    
    func addOpenCommand() {
        link.append("open?")
    }
    
    func identifyCollection(collection: NoteCollection) {
        if collection.shortcut.count > 0 {
            link.append("shortcut=\(collection.shortcut)")
        } else {
            link.append("path=\(collection.fullPath)")
        }
    }
                    
    func percentEncode() {
        if let encoded = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            link = encoded
        }
    }
}
