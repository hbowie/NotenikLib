//
//  TitleValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/3/18.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A title field value
public class TitleValue: StringValue {
    
    /// The lowest common denominator of the title (lower case, no whitespace, no punctuation)
    var common = ""
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Is this value empty?
    public override var isEmpty: Bool {
        return (value.count == 0 || common.count == 0)
    }
    
    /// Does this value have any data stored in it?
    public override var hasData: Bool {
        return (value.count > 0 && common.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public override var sortKey: String {
        return common
    }
    
    /// Set a new title value, converting to a lowest common denominator form while we're at it
    public override func set(_ value: String) {
        super.set(StringUtils.cleanAndTrim(value))
        common = StringUtils.toCommon(value)
    }
    
}
