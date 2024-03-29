//
//  RowImporter.swift
//  Notenik
//
//  Created by Herb Bowie on 8/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public protocol RowImporter {
    
    /// Initialize the class with a Row Consumer and an optional
    /// Script Workspace. 
    func setContext(consumer: RowConsumer)
    
    /// Read the file and break it down into fields and rows, returning each
    /// to the consumer, one at a time. Any errors encountered should be
    /// logged.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    func read(fileURL: URL)
    
}
