//
//  KeyValueWriter.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/9/24.
//
//  Copyright © 2024 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class KeyValueWriter {
    
    var writer: BigStringWriter = BigStringWriter()
    
    public init() {
        
    }
    
    public convenience init(title: String) {
        self.init()
        writer.open()
        appendTitle(title)
    }
    
    public func open() {
        writer.open()
    }
    
    public func appendTitle(_ title: String) {
        append(label: NotenikConstants.title, value: title)
    }
    
    public func appendLink(_ link: String) {
        append(label: NotenikConstants.link, value: link)
    }
    
    public func append(label: String, value: String) {
        writer.writeLine("\(label): \(value)")
        writer.endLine()
    }
    
    public func appendLong(label: String, value: String) {
        writer.writeLine("\(label): ")
        writer.endLine()
        writer.writeLine(value)
        writer.endLine()
    }
    
    public func close() {
        writer.close()
    }
    
    public var str: String {
        return writer.bigString
    }
    
    func write(toFile filePath: String) -> Bool {
        do {
            try str.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "KeyValueWriter",
                              level: .error,
                              message: "Problem writing file \(filePath) to disk!")
            return false
        }
        return true
    }
}
