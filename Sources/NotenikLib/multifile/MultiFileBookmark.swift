//
//  MultiFileBookmark.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/27/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A place to store bookmark data. 
class MultiFileBookmark {
    
    var path: String
    var url: URL
    var data: Data?
    var source: BookmarkSource = .fromSession
    
    init(url: URL, source: BookmarkSource) {
        path = url.path
        self.url = url
        self.source = source
    }
    
    enum BookmarkSource {
        case fromSession
        case fromStash
    }
}
