//
//  IndexPageRef.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class IndexPageRef {
    
    var term       = IndexTerm()
    var page       = ""
    var pageType   = ""
    var pageStatus = ""
    var anchor     = ""
    
    init(term: IndexTerm, page: String, pageType: String, pageStatus: String, anchor: String) {
        self.term = term
        self.page = page
        self.pageType = pageType
        self.pageStatus = pageStatus
        self.anchor = anchor
    }
    
    /// A string that can be used to sort a list of references to a term. 
    var key: String {
        return page.lowercased() + "#" + anchor.lowercased()
    }
}
