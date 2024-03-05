//
//  NotesToText.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/2/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// This is how we convert one or more notes to an output textual representation. 
public protocol NotesToText {
    
    /// Provide the usual file extension for this sort of text output. 
    var usualFileExtension: String { get }
    
    /// Provide the line writer to be used for output.
    /// - Parameter writer: The line writer to be used for output.
    init(writer: LineWriter)
    
    /// Write any starting matter to the output.
    func start()
    
    /// Write one note to text.
    /// - Parameter note: The note to be written.
    /// - Returns: +1 if note was written, -1 if a failure, zero if not written due to user wishes. 
    func oneNoteToText(note: Note) -> Int
    
    /// Finish up the output. 
    func finish()
    
}
