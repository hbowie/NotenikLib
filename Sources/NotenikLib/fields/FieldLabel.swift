//
//  FieldLabel.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A label used to identify a particular field within a collection of items.
public class FieldLabel: CustomStringConvertible {
    
    public var properForm = ""
    public var commonForm = ""
    var validLabel = false
    
    init() {
    
    }
    
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    func set(_ label: String) {
        properForm = label
        commonForm = StringUtils.toCommon(label)
        if isAuthor && commonForm != NotenikConstants.authorCommon {
            properForm = NotenikConstants.author
            commonForm = NotenikConstants.authorCommon
        } else if isLink && commonForm != NotenikConstants.linkCommon {
            properForm = NotenikConstants.link
            commonForm = NotenikConstants.linkCommon
        } else if isRating && commonForm != NotenikConstants.ratingCommon {
            properForm = NotenikConstants.rating
            commonForm = NotenikConstants.ratingCommon
        } else if isRecurs && commonForm != NotenikConstants.recursCommon {
            properForm = NotenikConstants.recurs
            commonForm = NotenikConstants.recursCommon
        } else if isSeq && commonForm != NotenikConstants.seqCommon {
            properForm = NotenikConstants.seq
            commonForm = NotenikConstants.seqCommon
        } else if isTags && commonForm != NotenikConstants.tagsCommon {
            properForm = NotenikConstants.tags
            commonForm = NotenikConstants.tagsCommon
        }
    }
    
    var isAuthor: Bool {
        return (commonForm == NotenikConstants.authorCommon
            || commonForm == "by"
            || commonForm == "creator")
    }
    
    var isBody: Bool {
        return commonForm == NotenikConstants.bodyCommon
    }
    
    var isCode: Bool {
        return commonForm == NotenikConstants.codeCommon
    }
    
    var isDate: Bool {
        return commonForm == NotenikConstants.dateCommon
    }
    
    var isDateAdded: Bool {
        return commonForm == NotenikConstants.dateAddedCommon
    }
    
    var isDateModified: Bool {
        return commonForm == NotenikConstants.dateModifiedCommon
    }
    
    var isIndex: Bool {
        return commonForm == NotenikConstants.indexCommon
    }
    
    var isLink: Bool {
        return (commonForm == NotenikConstants.linkCommon
            || commonForm == "url")
    }
    
    var isRating: Bool {
        return (commonForm == NotenikConstants.ratingCommon
            || commonForm == "priority")
    }
    
    var isRecurs: Bool {
        return (commonForm == NotenikConstants.recursCommon
            || commonForm == "every"
            || (commonForm.hasPrefix(NotenikConstants.recursCommon)
                && commonForm.hasSuffix("every")))
    }
    
    var isSeq: Bool {
        return (commonForm == NotenikConstants.seqCommon
            || commonForm == "sequence"
            || commonForm == "rev"
            || commonForm == "revision"
            || commonForm == "version")
    }
    
    var isStatus: Bool {
        return (commonForm == NotenikConstants.statusCommon)
    }
    
    var isTags: Bool {
        return (commonForm == NotenikConstants.tagsCommon
            || commonForm == "keywords"
            || commonForm == "category"
            || commonForm == "categories")
    }
    
    var isTeaser: Bool {
        return (commonForm == NotenikConstants.teaserCommon)
    }
    
    var isTimestamp: Bool {
        return (commonForm == NotenikConstants.timestampCommon)
    }
    
    var isTitle: Bool {
        return commonForm == NotenikConstants.titleCommon
        
    }
    
    var isType: Bool {
        return commonForm == NotenikConstants.typeCommon
    }
    
    var isWorkTitle: Bool {
        return commonForm == NotenikConstants.workTitleCommon
    }
    
    var isWorkType: Bool {
        return commonForm == NotenikConstants.workTypeCommon
    }
    
    var count: Int {
        return properForm.count
    }
    
    public var description: String {
        return properForm
    }
    
    var isEmpty: Bool {
        return (properForm.count == 0)
    }
    
    var hasData: Bool {
        return (properForm.count > 0)
    }
    
    func display() {
        print("FieldLabel | Proper Form: \(properForm), Common Form: \(commonForm), Valid? \(validLabel)")
    }
}
