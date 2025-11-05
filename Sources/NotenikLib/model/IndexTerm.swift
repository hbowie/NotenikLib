//
//  IndexTerm.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class IndexTerm: Comparable, Equatable {
    
    var term = ""
    var termSort = ""
    var startingArticle = ""
    var link = ""
    public var refs: [IndexPageRef] = []
    
    public init() {
        
    }
    
    public init(term: String) {
        self.term = term
        var termWork = term.lowercased()
        if termWork.hasPrefix("a ") {
            termWork.removeFirst(2)
            startingArticle = String(self.term.prefix(1))
            self.term.removeFirst(2)
        } else if termWork.hasPrefix(" an ") {
            termWork.removeFirst(3)
            startingArticle = String(self.term.prefix(2))
            self.term.removeFirst(3)
        } else if termWork.hasPrefix("the ") {
            termWork.removeFirst(4)
            startingArticle = String(self.term.prefix(3))
            self.term.removeFirst(4)
        }
        termSort = StringUtils.toCommon(termWork)
    }
    
    public var key: String {
        return termSort + term
    }
    
    func addRef(_ ref: IndexPageRef) {
        /* var i = 0
        var looking = true
        while i < refs.count && looking {
            let nextRef = refs[i]
            if ref.key <= nextRef.key {
                refs.insert(ref, at: i)
                looking = false
            } else {
                i += 1
            }
        }
        if looking { */
            refs.append(ref)
        // }
    }
    
    public static func == (lhs: IndexTerm, rhs: IndexTerm) -> Bool {
        return lhs.term == rhs.term
    }
    
    public static func < (lhs: IndexTerm, rhs: IndexTerm) -> Bool {
        return lhs.key < rhs.key
    }
}
