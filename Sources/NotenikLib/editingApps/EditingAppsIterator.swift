//
//  EditingAppsIterator.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/23/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class EditingAppsIterator: IteratorProtocol {

    // MARK: - Properties
    
    private var current = 0
    private let apps: [EditingApp]

    // MARK: - Initializers
    
    init(apps: [EditingApp]) {
        self.apps = apps
    }

    // MARK: - Methods
    
    public func next() -> EditingApp? {
        defer { current += 1 }
        if current >= 0 && current < apps.count {
            return apps[current]
        }
        return nil
    }
}
