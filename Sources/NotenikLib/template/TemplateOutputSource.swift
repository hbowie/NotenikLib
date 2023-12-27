//
//  TemplateOutputSource.swift
//  NotenikLib
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 12/27/23.
//

import Foundation

/// Allow a query to be refreshed.
public protocol TemplateOutputSource {
    
    /// Refresh a previously defined  query.
    func refreshQuery()
    
}
