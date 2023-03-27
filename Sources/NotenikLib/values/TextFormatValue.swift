//
//  TextFormatValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/26/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class TextFormatValue: StringValue {
    
    public override init() {
        super.init()
        value = NotenikConstants.textFormatMD
    }
    
    public init(_ value: String) {
        super.init()
        self.value = value
    }
    
    public override func valueToDisplay() -> String {
        switch value {
        case NotenikConstants.textFormatTxt:
            return NotenikConstants.textFormatPlainText
        case NotenikConstants.textFormatPlainText:
            return NotenikConstants.textFormatPlainText
        case NotenikConstants.textFormatPlainTextCommon:
            return NotenikConstants.textFormatPlainText
        default:
            return NotenikConstants.textFormatMarkdown
        }
    }
    
    public var isText: Bool {
        return value == "txt"
    }
    
}
