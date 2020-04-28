//
//  KnownFolder.swift
//
//  Created by Herb Bowie on 4/27/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class KnownFolder: CustomStringConvertible {
    public var url:           URL
    public var isCollection = false
    public var fromBookmark = false
    public var inUse        = false
    
    public init(url: URL) {
        self.url = url
    }
    
    public init(url: URL, isCollection: Bool, fromBookmark: Bool) {
        self.url = url
        self.isCollection = isCollection
        self.fromBookmark = fromBookmark
    }
    
    public var description: String {
        return ("path: \(path), collection? \(isCollection), from bookmark? \(fromBookmark)")
    }
    
    public var path: String {
        return url.path
    }
}
