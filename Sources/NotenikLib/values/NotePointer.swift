//
//  NotePointer.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/2/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class NotePointer: Comparable, CustomStringConvertible, Equatable, Identifiable  {

    public var title = ""
    public var common = ""
    public var matched = false
    
    public var description: String {
        return title
    }
    
    public var id: String {
        return common
    }
    
    public init(title: String) {
        self.title = title
        self.common = StringUtils.toCommon(title)
    }
    
    public func display(indentLevels: Int = 0) {
        
        StringUtils.display("title = \(title), common = \(common), matched? \(matched)",
                            label: nil,
                            blankBefore: false,
                            header: "NotePointer",
                            sepLine: false, indentLevels: indentLevels)
    }
    
    public static func < (lhs: NotePointer, rhs: NotePointer) -> Bool {
        return lhs.common < rhs.common
    }
    
    public static func == (lhs: NotePointer, rhs: NotePointer) -> Bool {
        return lhs.common == rhs.common
    }
}
