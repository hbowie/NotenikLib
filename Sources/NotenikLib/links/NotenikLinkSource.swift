//
//  NotenikLinkSource.swift
//  NotenikLib
//
//  Created by Herb Bowie on 5/2/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// This can be used to specify the source of a link. If it is coming from within Notenik, then we don't assume
/// that the thing to be opened is some kind of Notenik asset. If it is coming from outside of Notenik, on the other
/// hand, then we assume that it is some kind of asset to be opened by Notenik. 
public enum NotenikLinkSource {
    case fromWithin
    case fromWithout
}
