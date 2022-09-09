//
//  NoteLinkResolution.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/7/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation
import NotenikMkdown

public class NoteLinkResolution {
    public var fromIO:   NotenikIO?
    public var linkText: String = ""
    public var linkPath: String = ""
    public var linkItem: String = ""
    public var linkID:   String = ""
    public var result:   ResolveResult = .badInput
    public var resolvedIO: NotenikIO?
    public var resolvedPath: String = ""
    public var resolvedItem: String = ""
    public var resolvedID:   String = ""
    public var resolvedNote: Note?
    
    public init() {
        
    }
    
    public convenience init(io: NotenikIO?, linkText: String) {
        self.init()
        self.fromIO = io
        self.linkText = linkText
    }
    
    public var pathSlashID: String {
        guard !resolvedPath.isEmpty else { return resolvedID }
        return "\(resolvedPath)/\(resolvedID)"
    }
    
    public func genWikiLinkTarget() -> WikiLinkTarget? {
        
        var target = WikiLinkTarget(linkText)
        guard result != .badInput else { return target }
        
        guard result == .resolved else { return nil }
        
        target = WikiLinkTarget(path: resolvedPath, item: resolvedItem)
        return target
    }
    
    public func display() {
        print("NotenikLinkResolution")
        if let fromIOpath = fromIO?.collection?.path {
            print("  from I/O path: \(fromIOpath)")
        } else {
            print("  - from i/o is nil!")
        }
        print("  - link text: \(linkText)")
        print("  - link path: \(linkPath)")
        print("  - link item: \(linkItem)")
        print("  - link ID:   \(linkID)")
        print("  - result:    \(result)")
        if let resolvedIOpath = resolvedIO?.collection?.path {
            print("  - resolved I/O path: \(resolvedIOpath)")
        } else {
            print("  - resolved I/O is nil!")
        }
        print("  - resolved path: \(resolvedPath)")
        print("  - resolved item: \(resolvedItem)")
        print("  - resolved ID:   \(resolvedID)")
        if resolvedNote == nil {
            print("  - resolved Note is nil!")
        } else {
            print("  - resolved Note title: \(resolvedNote!.title.value)")
        }
    }
}
