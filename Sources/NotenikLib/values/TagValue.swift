//
//  TagValue.swift
//  Notenik
//
//  Created by Herb Bowie on 7/10/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Class representing one Tag (with possibly multiple levels)
public class TagValue: StringValue {
    
    public var levels: [TagLevel] = []
    
    /// The number of levels in the tag
    public override var count: Int {
        return levels.count
    }
    
    func addLevel(_ level: TagLevel) {
        levels.append(level)
        if value.count > 0 { value.append(".") }
        value.append(level.forDisplay)
    }
    
    /// Add another level to this tag.
    func addLevel(_ level: String) {
        let tagLevel = TagLevel(level)
        levels.append(tagLevel)
        if value.count > 0 { value.append(".") }
        value.append(level)
    }
    
    func getTag(delim: Character) -> String {
        var tag = ""
        for level in levels {
            if !tag.isEmpty {
                tag.append(delim)
            }
            tag.append(level.text)
        }
        return tag
    }
    
    /// See if this tag is equal to another one.
    static func == (lhs: TagValue, rhs: TagValue) -> Bool {
        return lhs.description == rhs.description
    }
    
    /// See if this tag is less than another one.
    static func < (lhs: TagValue, rhs: TagValue) -> Bool {
        return lhs.description < rhs.description
    }
    
    /// Create HTML Anchor links for the tags. Assume that periods separating multiple
    /// tags will be replaced by hyphens, when creating the href value.
    ///
    /// - Parameters:
    ///   - parent: The parent path to the folder containing the tags pages.
    ///   - ext: The file extension to be used for the pages. "html" is
    ///          the default, but may be overridden.
    /// - Returns: The starting anchor tag, including the href, the tags
    ///            to be linked, and the ending anchor tag.
    func getLinkedTag(parent: String, htmlClass: String, ext: String = "html") -> String {
        var linkExt = ""
        if ext.count > 0 {
            if ext.hasPrefix(".") {
                linkExt = ext
            } else {
                linkExt = "." + ext
            }
        }
        var str = ""
        var link = ""
        for level in levels {
            if str.count > 0 {
                str.append(".")
                link.append("-")
            }
            str.append(level.forDisplay)
            link.append(StringUtils.toCommonFileName(level.forDisplay))
        }
        var klass = ""
        if htmlClass.count > 0 {
            klass = " class='" + htmlClass + "'"
        }
        return "<a\(klass) href='" + parent + link + linkExt + "' rel='tag'>" + str + "</a>"
    }
    
}
