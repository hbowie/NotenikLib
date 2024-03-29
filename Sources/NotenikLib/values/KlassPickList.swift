//
//  KlassPickList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/28/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class KlassPickList: PickList {
    
    public override init() {
        super.init()
        forceLowercase = true
    }
    
    public override init(values: String, forceLowercase: Bool = true, allowBlanks: Bool = true) {
        super.init(values: values, forceLowercase: forceLowercase, allowBlanks: allowBlanks)
    }
    
    /// If the user hasn't supplied any values, then use some defaults. 
    public func setDefaults() {
        guard count == 0 else { return }
        registerValue("")
        registerValue("biblio")
        registerValue("cover")
        registerValue("def")
        registerValue("text")
        registerValue("title")
    }
    
    public override func getTypeWithValues(type: String = "class") -> String {
        var str = "<\(type): "
        var valueIndex = 0
        for value in values {
            if valueIndex > 0 {
                str.append(", ")
            }
            str.append(String(describing: value))
            valueIndex += 1
        }
        str.append(" >")
        return str
    }
    
}
