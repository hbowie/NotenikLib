//
//  SearchOptions.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/19/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class SearchOptions {

    var _searchText = ""
    public var searchText: String {
        get {
            return _searchText
        }
        set {
            hashTag = newValue.starts(with: "#")
            if hashTag {
                _searchText = String(newValue.dropFirst(1))
            } else {
                _searchText = newValue
            }
        }
    }
    
    public var titleField = true
    public var akaField = true
    public var linkField = true
    public var tagsField = true
    public var authorField = true
    public var bodyField = true
    
    public var caseSensitive = false
    
    public var scope: SearchScope {
        get {
            return _scope
        }
        set {
            _scope = newValue
            anchorSeq = ""
            anchorSortKey = ""
        }
    }
    var _scope: SearchScope = .all
    
    public var anchorSortKey = ""
    public var anchorSeq = ""
    
    public var hashTag = false
    
    public init() {
        
    }
    
    public enum SearchScope {
        case all
        case within
        case forward
    }
    
}
