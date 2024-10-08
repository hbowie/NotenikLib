//
//  TagsValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// One or more tags, each consisting of one or more levels
public class TagsValue: StringValue, MultiValues {    
    
    public var tags: [TagValue] = []
    public var hashtagsOption: HashtagsOption = .notenikField
    
    /// Default initializer
    public override init() {
        super.init()
    }
    
    /// Convenience initializer with String value
    public convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    
    /// Set a new value for the tags.
    ///
    /// - Parameter value: The new value for the tags, with commas or semi-colons separating tags,
    ///                    and periods or slashes separating levels within a tag.
    public override func set(_ value: String) {
        
        super.set(value)
        
        var tag = TagValue()
        var level = ""
        
        /// Loop through new value
        for c in value {
            if c == "," || c == ";" || c == "." || c == "/" || c == "#" {
                if level.count > 0 {
                    tag.addLevel(level)
                    level = ""
                }
                if (c == "," || c == ";" || c == "#") && tag.count > 0 {
                    tags.append(tag)
                    tag = TagValue()
                }
                if c == "#" {
                    hashtagsOption = .fieldWithHashSymbols
                }
            } else if c == " " {
                if level.count > 0 {
                  level.append(c)
                }
            } else if c.isLetter || c.isNumber || c == "-" || c == "_" {
                level.append(c)
            }
        }
        
        /// Finish up
        if level.count > 0 {
            tag.addLevel(level)
        }
        if tag.count > 0 {
            tags.append(tag)
        }
        sort()
    }
    
    /// Sort the tags alphabetically
    public func sort() {
        tags.sort { $0.description < $1.description }
        removeDuplicates()
        calcValue()
    }
    
    func removeDuplicates() {
        var i = 0
        var j = 1
        while j < tags.count {
            if tags[i] == tags[j] {
                tags.remove(at: i)
            } else {
                i += 1
                j += 1
            }
        }
    }
    
    func calcValue() {
        value = ""
        var x = 0
        for tag in tags {
            if x > 0 {
                value.append(", ")
            }
            // if hashTags {
            //     value.append("#")
            // }
            var y = 0
            for level in tag.levels {
                if y > 0 {
                    value.append(".")
                }
                value.append(level.forDisplay)
                y += 1
            }
            x += 1
        }
    }
    
    /// Return the tags formatted for writing to disk.
    /// - Parameter mods: A mod of '#' will cause each tag to be preceded by a hash sign.
    /// - Returns: The formatted tags.
    public override func valueToWrite(mods: String = " ") -> String {
        
        var prefix = ""
        if mods.count > 0 && mods[mods.startIndex] == "#" {
            prefix = "#"
        }
        var valToWrite = ""
        var x = 0
        for tag in tags {
            if x > 0 {
                valToWrite.append(", ")
            }
            valToWrite.append(prefix)
            var y = 0
            for level in tag.levels {
                if y > 0 {
                    valToWrite.append(".")
                }
                valToWrite.append(level.forDisplay)
                y += 1
            }
            x += 1
        }
        return valToWrite
    }
    
    public var microTags: String {
        var valToWrite = ""
        var x = 0
        for tag in tags {
            if x > 0 {
                valToWrite.append(" ")
            }
            valToWrite.append("#")
            var y = 0
            for level in tag.levels {
                if y > 0 {
                    valToWrite.append(".")
                }
                valToWrite.append(StringUtils.wordDemarcation(level.forDisplay, caseMods: ["u", "u", "l"], delimiter: ""))
                y += 1
            }
            x += 1
        }
        return valToWrite
    }
    
    /// Create HTML Anchor links for the tags. Assume that periods separating multiple
    /// tags will be replaced by hyphens, when creating the href value. Separate
    /// multiple tags with commas.
    ///
    /// - Parameters:
    ///   - parent: The parent path to the folder containing the tags pages.
    ///   - ext: The file extension to be used for the pages. "html" is
    ///          the default, but may be overridden.
    /// - Returns: For each tag: The starting anchor tag, including the href,
    ///            the tags to be linked, and the ending anchor tag.
    func getLinkedTags(parent: String, htmlClass: String, ext: String = "html", sep: String = ", ") -> String {
        var html = ""
        for tag in tags {
            if html.count > 0 {
                html.append(sep)
            }
            html.append(tag.getLinkedTag(parent: parent, htmlClass: htmlClass, ext: ext))
        }
        return html
    }
    
    func getTag(_ x: Int) -> String? {
        if x < 0 || x >= tags.count {
            return nil
        } else {
            return tags[x].description
        }
    }
    
    func getLevel(tagIndex: Int, levelIndex: Int) -> String? {
        guard let level = getLevelObject(tagIndex: tagIndex, levelIndex: levelIndex) else { return nil }
        return level.forDisplay
    }
    
    func getLevelObject(tagIndex: Int, levelIndex: Int) -> TagLevel? {
        if tagIndex < 0 || tagIndex >= tags.count {
            return nil
        } else {
            let tag = tags[tagIndex]
            if levelIndex < 0 || levelIndex >= tag.count {
                return nil
            } else {
                return tag.levels[levelIndex]
            }
        }
    }
    
    /// Remove any characters that have a special meaning within a tag,
    /// to ensure that the string returned can itself be used as
    /// a single, single-level tag.
    public static func tagify(_ str: String) -> String {
        var tag = ""
        for char in str {
            if char == "," || char == ";" || char == "/" || char == "." || char == "#" {
                // drop it
            } else {
                tag.append(char)
            }
        }
        return tag
    }
    
    //
    // The following constants, variables and functions provide conformance to the MultiValues protocol.
    //
    
    public let multiDelimiter = "; "
    
    public var multiCount: Int {
        return tags.count
    }
    
    /// Return a sub-value at the given index position.
    /// - Returns: The indicated sub-value, for a valid index, otherwise nil.
    public func multiAt(_ index: Int) -> String? {
        guard index >= 0 else { return nil }
        guard index < tags.count else { return nil }
        let tag = tags[index].getTag(delim: "/")
        if hashtagsOption == .fieldWithHashSymbols {
            return "#" + tag
        } else {
            return tag
        }
    }
    
    public func append(_ str: String) {
        if self.isEmpty {
            set(str)
        } else {
            let anotherTag = TagValue(str)
            tags.append(anotherTag)
            sort()
        }
    }
}
