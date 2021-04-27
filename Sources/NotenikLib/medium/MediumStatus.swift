//
//  MediumStatus.swift
//
//  Created by Herb Bowie on 12/29/20.
//
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public enum MediumStatus {
    case tokenNeeded
    case authenticationNeeded
    case authenticationStarted
    case authenticationFailed
    case authenticationSucceeded
    case postStarted
    case postFailed
    case postSucceeded
    case internalError
}
