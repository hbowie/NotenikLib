//
//  TableMaker.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/21/24.
//

import Foundation
import NotenikUtils

public class TableMaker: RowConsumer {
    
    var piped = ""
    
    var lineCount = 0
        
    public init(str: String) {
        let reader = DelimitedReader()
        reader.setContext(consumer: self)
        reader.read(str: str)
    }
    
    public func getTable() -> String {
        return piped
    }
    
    public func consumeField(label: String, value: String) {

    }
    
    public func consumeRow(labels: [String], fields: [String]) {
        if lineCount == 0 {
            for label in labels {
                piped.append("| \(label)")
            }
            piped.append(" | \n")
            for label in labels {
                piped.append("| ---")
            }
            piped.append(" | \n")
        }
        for field in fields {
            piped.append("| \(field)")
        }
        piped.append(" | \n")
        lineCount += 1
    }
}
