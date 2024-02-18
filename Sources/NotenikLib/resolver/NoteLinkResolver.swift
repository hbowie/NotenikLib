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
import NotenikUtils

public class NoteLinkResolver {
    
    /// Investigate an apparent link to another note, replacing it, if necessary, with
    /// a current and valid link.
    /// - Parameter title: A wiki link target that is possibly a timestamp instead of a title.
    /// - Returns: The corresponding title, if the lookup was successful, otherwise the title
    ///            that was passed as input.
    public static func resolve(resolution: NoteLinkResolution) {
        
        (resolution.linkPath, resolution.linkItem) = StringUtils.splitPath(resolution.linkText)
        resolution.linkID = StringUtils.toCommon(resolution.linkItem)
        
        resolution.result = .badInput
        guard let io = resolution.fromIO else { return }
        guard io.collection != nil else { return }
        guard io.collectionOpen else { return }
        
        resolution.result = .unresolved
        
        // See if we have a secondary folder specified.
        let multi = MultiFileIO.shared
        var targetIO = io
        if !resolution.linkPath.isEmpty {
            let (targetCollection, tgIO) = multi.provision(shortcut: resolution.linkPath, inspector: nil, readOnly: false)
            if targetCollection != nil {
                resolution.resolvedPath = resolution.linkPath
                targetIO = tgIO
            }
        }
        
        // Check for first possible case: title within the wiki link
        // points directly to another note having that same title.
        var linkedNote = targetIO.getNote(forID: resolution.linkID)
        if linkedNote != nil {
            targetIO.aliasList.add(titleID: resolution.linkID, timestamp: linkedNote!.timestampAsString)
            resolution.result = .resolved
            resolution.resolvedIO = targetIO
            resolution.resolvedItem = linkedNote!.noteID.getBasis()
            resolution.resolvedID = linkedNote!.noteID.commonID
            resolution.resolvedNote = linkedNote
            return
        }
        
        // Check for second possible case: a simple difference of singular
        // vs. plural forms.
        if resolution.linkID.hasSuffix("s") {
            linkedNote = targetIO.getNote(forID: String(resolution.linkID.dropLast(1)))
        } else {
            linkedNote = targetIO.getNote(forID: resolution.linkID + "s")
        }
        if linkedNote != nil {
            resolution.result = .resolved
            resolution.resolvedIO = targetIO
            resolution.resolvedItem = linkedNote!.noteID.getBasis()
            resolution.resolvedID = linkedNote!.noteID.commonID
            resolution.resolvedNote = linkedNote
            return
        }
        
        // Check for third possible case: title within the wiki link
        // refers to an alias by which a Note is also known.
        if targetIO.collection!.akaFieldDef != nil {
            linkedNote = targetIO.getNote(alsoKnownAs: resolution.linkID)
            if linkedNote != nil {
                resolution.result = .resolved
                resolution.resolvedIO = targetIO
                resolution.resolvedItem = linkedNote!.noteID.getBasis()
                resolution.resolvedID = linkedNote!.noteID.commonID
                resolution.resolvedNote = linkedNote
                return
            }
        }
    
        // Check for fourth possible case: search for an alias
        // with an 's' added.
        if targetIO.collection!.akaFieldDef != nil {
            linkedNote = targetIO.getNote(alsoKnownAs: resolution.linkID + "s")
            if linkedNote != nil {
                resolution.result = .resolved
                resolution.resolvedIO = targetIO
                resolution.resolvedItem = linkedNote!.noteID.getBasis()
                resolution.resolvedID = linkedNote!.noteID.commonID
                resolution.resolvedNote = linkedNote
                return
            }
        }
        
        guard targetIO.collection!.hasTimestamp else { return }
        
        // Check for fifth possible case: title within the wiki link
        // used to point directly to another note having that same title,
        // but the target note's title has since been modified.
        let timestamp = targetIO.aliasList.get(titleID: resolution.linkID)
        if timestamp != nil {
            linkedNote = targetIO.getNote(forTimestamp: timestamp!)
            if linkedNote != nil {
                resolution.result = .resolved
                resolution.resolvedIO = targetIO
                resolution.resolvedItem = linkedNote!.noteID.getBasis()
                resolution.resolvedID = linkedNote!.noteID.commonID
                resolution.resolvedNote = linkedNote
                return
            }
        }
        
        // Check for sixth possible case: string within the wiki link
        // is already a timestamp pointing to another note.
        guard resolution.linkItem.count < 15 && resolution.linkItem.count > 11 else { return }
        linkedNote = targetIO.getNote(forTimestamp: resolution.linkItem)
        if linkedNote != nil {
            resolution.result = .resolved
            resolution.resolvedIO = targetIO
            resolution.resolvedItem = linkedNote!.noteID.getBasis()
            resolution.resolvedID = linkedNote!.noteID.commonID
            resolution.resolvedNote = linkedNote
            return
        }
        
        // Nothing worked, so mark as unresolved. 
        resolution.result = .unresolved
        return
    }
}
