//
//  NoteSlugger.swift
//  NotenikLib
//
//  Created by Herb Bowie on 3/22/24.
//
//  Copyright © 2024 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class NoteSlugger {
    
    /// Generate nicely formatted HTML to display Author and Work and related fields.
    /// - Parameter fromNote: The note supplying the fields.
    /// - Returns: Formatted html, or blank.
    public static func authorWorkSlug(fromNote: Note,
                                      links: Bool = true,
                                      verbose: Bool = false,
                                      intLinks: Bool = false) -> String {
        
        let markedUp = Markedup(format: .htmlFragment)
        
        if let authorField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.authorCommon) {
            if verbose {
                markedUp.append("&#8212; ")
            }
            var authorValue = AuthorValue()
            if let av = authorField.value as? AuthorValue {
                authorValue = av
            } else {
                authorValue = AuthorValue(authorField.value.value)
            }
            
            if links {
                var authorLinkStr = ""
                if intLinks {
                    authorLinkStr = "../authors/" +
                        StringUtils.toCommonFileName(authorValue.value) +
                        ".html"
                    markedUp.startLink(path: authorLinkStr)
                } else {
                    let authorLink = FieldGrabber.getField(note: fromNote,
                                                           label: NotenikConstants.authorLinkCommon)
                    if authorLink != nil {
                        authorLinkStr = authorLink!.value.value
                        markedUp.startLink(path: authorLinkStr,
                                           klass: Markedup.htmlClassExtLink,
                                           blankTarget: true)
                    }
                }
                markedUp.append(authorValue.firstNameFirst)
                if !authorLinkStr.isEmpty {
                    markedUp.finishLink()
                }
            } else {
                markedUp.append(authorValue.firstNameFirst)
            }
        } else {
            return ""
        }
        
        var workTitle = ""
        if fromNote.klass.value == NotenikConstants.workKlass {
            workTitle = fromNote.title.value
        } else if let wt = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTitleCommon) {
            workTitle = wt.value.value
        }
        
        if !workTitle.isEmpty && workTitle.lowercased() != "unknown" {
            if !markedUp.code.isEmpty {
                markedUp.append(", ")
                // if verbose {
                    markedUp.append("from ")
                // }
            }
            var majorWork = true
            if let workTypeField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTypeCommon) {
                if let workType = workTypeField.value as? WorkTypeValue {
                    majorWork = workType.isMajor
                    let theType = workType.theType
                    if !theType.isEmpty {
                        markedUp.append("\(theType) ")
                    }
                }
            }
            if majorWork {
                markedUp.startCite()
            } else {
                markedUp.leftDoubleQuote()
            }
            
            if links {
                var workLink = ""
                if let wl = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workLinkCommon) {
                    workLink = wl.value.value
                } else if fromNote.klass.value == NotenikConstants.workKlass {
                    workLink = fromNote.link.value
                }
                if !workLink.isEmpty {
                    markedUp.startLink(path: workLink, klass: Markedup.htmlClassExtLink, blankTarget: true)
                }
                markedUp.append(workTitle)
                if !workLink.isEmpty {
                    markedUp.finishLink()
                }
            } else {
                markedUp.append(workTitle)
            }

            if majorWork {
                markedUp.finishCite()
            } else {
                markedUp.rightDoubleQuote()
            }
        }
        
        if !markedUp.code.isEmpty {
            var slugDate = ""
            let workDate = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workDateCommon)
            if workDate != nil {
                slugDate = workDate!.value.value
            } else {
                let date = FieldGrabber.getField(note: fromNote, label: NotenikConstants.dateCommon)
                if date != nil {
                    slugDate = date!.value.value
                }
            }
            if !slugDate.isEmpty {
                markedUp.append(", \(slugDate)")
            }
        }
        
        let rights = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workRightsCommon)
        let holder = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workRightsHolderCommon)
        if rights != nil || holder != nil {
            if !markedUp.code.isEmpty {
                markedUp.append(", ")
            }
            let author = FieldGrabber.getField(note: fromNote, label: NotenikConstants.authorCommon)
            if rights == nil || rights!.value.value.lowercased() == "copyright" {
                markedUp.append("&copy;")
            } else {
                markedUp.append(rights!.value.value)
            }
            markedUp.append(" ")
            if holder != nil && !holder!.value.value.isEmpty {
                markedUp.append(holder!.value.value)
            } else if author != nil && !author!.value.value.isEmpty {
                markedUp.append(author!.value.value)
            }
        }
        
        return markedUp.code
    }
    
    /// Generate nicely formatted HTML to display Author and Work and related fields.
    /// - Parameter fromNote: The note supplying the fields.
    /// - Returns: Formatted html, or blank.
    public static func finishedWorkSlug(fromNote: Note) -> String {
        let markedUp = Markedup(format: .htmlFragment)
        
        var majorWork = true
        var activity = "reading"
        if let workTypeField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTypeCommon) {
            if let workType = workTypeField.value as? WorkTypeValue {
                majorWork = workType.isMajor
                activity = workType.activity
            }
        }
        
        markedUp.append("Finished \(activity) ")
        
        var workTitle = ""
        if fromNote.klass.value == NotenikConstants.workKlass {
            workTitle = fromNote.title.value
        } else if let wt = FieldGrabber.getField(note: fromNote, label: NotenikConstants.workTitleCommon) {
            workTitle = wt.value.value
        }
        
        if !workTitle.isEmpty && workTitle.lowercased() != "unknown" {

            if majorWork {
                markedUp.startCite()
            } else {
                markedUp.leftDoubleQuote()
            }
            
            markedUp.append(workTitle)

            if majorWork {
                markedUp.finishCite()
            } else {
                markedUp.rightDoubleQuote()
            }
        }
        
        if markedUp.code.count < 40 {
            if let authorField = FieldGrabber.getField(note: fromNote, label: NotenikConstants.authorCommon) {
                var authorValue = AuthorValue()
                if let av = authorField.value as? AuthorValue {
                    authorValue = av
                } else {
                    authorValue = AuthorValue(authorField.value.value)
                }
                markedUp.append(" by \(authorValue.firstNameFirst)")
            }
        }
        
        return markedUp.code
    }
}
