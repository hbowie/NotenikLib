//
//  IncludeChildrenList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/10/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class IncludeChildrenList {
    
    public static let shared = IncludeChildrenList()
    
    public static let defList = "dl"
    public static let orderedList = "ol"
    public static let unorderedList = "ul"
    public static let details = "details"
    public static let no = ""
    public static let quotes = "quotes"
    
    public var values: [String] = []
    
    private init() {
        values.append(IncludeChildrenList.no)
        values.append(IncludeChildrenList.details)
        values.append("h1")
        values.append("h2")
        values.append("h3")
        values.append("h4")
        values.append("h5")
        values.append("h6")
        // values.append(IncludeChildrenList.quotes)
        values.append(IncludeChildrenList.defList)
        values.append(IncludeChildrenList.orderedList)
        values.append(IncludeChildrenList.unorderedList)
    }
    
}
