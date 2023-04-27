//
//  KlassValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/20/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class KlassValue: StringValue {
    
    override func set(_ value: String) {
        super.set(value.lowercased())
    }
    
    public var frontOrBack: Bool {
        switch value {
        case NotenikConstants.authorKlass:
            return true
        case NotenikConstants.backKlass:
            return true
        case NotenikConstants.biblioKlass:
            return true
        case NotenikConstants.frontKlass:
            return true
        case NotenikConstants.introKlass:
            return true
        case NotenikConstants.prefaceKlass:
            return true
        case NotenikConstants.titleKlass:
            return true
        case NotenikConstants.workKlass:
            return true
        default:
            return false
        }
    }
    
    public var exclude: Bool {
        switch value {
        case NotenikConstants.excludeKlass:
            return true
        default:
            return false
        }
    }
    
    public var include: Bool {
        switch value {
        case NotenikConstants.excludeKlass:
            return false
        default:
            return true
        }
    }
    
    public var frontMatter: Bool {
        switch value {
        case NotenikConstants.frontKlass, NotenikConstants.introKlass, NotenikConstants.prefaceKlass, NotenikConstants.titleKlass:
            return true
        default:
            return false
        }
    }
    
    public var biblio: Bool {
        switch value {
        case NotenikConstants.authorKlass, NotenikConstants.workKlass:
            return true
        default:
            return false
        }
    }
    
    public var quote: Bool {
        switch value {
        case NotenikConstants.quoteKlass, NotenikConstants.quotationKlass:
            return true
        default:
            return false
        }
    }
    
}
