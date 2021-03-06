//
//  MediumInfo.swift
//
//  Created by Herb Bowie on 12/29/20.
//
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class MediumInfo {
    
    public init() {
        
    }
    
    public var status: MediumStatus = .tokenNeeded
    public var msg = ""
    
    public var authToken = ""
    
    public var userid = ""
    public var username = ""
    public var name = ""
    public var url = ""
    public var imageURL = ""
    
    public var note: Note?
    
    public var postURL = ""
    
}
