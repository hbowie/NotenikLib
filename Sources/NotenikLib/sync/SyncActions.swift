//
//  SyncActions.swift
//  NotenikLib
//
//  Created by Herb Bowie on 6/21/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
public enum SyncActions {
    case logOnly
    case logDetails
    case logSummary
    case debugging
    
    public var reportDetails: Bool {
        switch self {
        case .debugging, .logOnly, .logDetails:
            return true
        case .logSummary:
            return false
        }
    }
    
    public var performUpdates: Bool {
        switch self {
        case .debugging, .logOnly:
            return false
        case .logSummary, .logDetails:
            return true
        }
    }
    
    public var debugging: Bool {
        return self == .debugging
    }
}
