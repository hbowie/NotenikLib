//
//  KeyValueWriter.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/9/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class KeyValueWriter {
    
    var writer: BigStringWriter = BigStringWriter()
    
    public func open() {
        writer.open()
    }
    
    func append(label: String, value: String) {
        writer.writeLine("\(label): \(value)")
        writer.endLine()
    }
    
    public func close() {
        writer.close()
    }
    
    public var str: String {
        return writer.bigString
    }
    
}
