//
//  FieldComparisonOperator.swift
//  Notenik
//
//  Created by Herb Bowie on 6/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Comparison Operator used to compare a field to something. 
class FieldComparisonOperator: CustomStringConvertible {
    
    var description = ""
    
    var op: ComparisonOperator = .undefined
    
    /// Initialize with a string contaning symbols, words or an abbreviation.
    convenience init(_ str: String) {
        self.init()
        description = str
        switch str {
        case "=", "==", "eq", "equals":
            op = .equals
        case ">", "gt", "greater than":
            op = .greaterThan
        case ">=", "!<", "ge", "greater than or equal to":
            op = .greaterThanOrEqualTo
        case "<", "lt", "less than":
            op = .lessThan
        case "<=", "!>", "le", "less than or equal to":
            op = .lessThanOrEqualTo
        case "<>", "!=", "ne", "not equal to":
            op = .notEqualTo
        case "()", "[]", "co", "contains":
            op = .contains
        case "!()", "![]", "nc", "does not contain":
            op = .doesNotContaIn
        case "(<)", "[<]", "st", "starts with":
            op = .startsWith
        case "!(<)", "![<]", "ns", "does not start with":
            op = .doesNotStartWith
        case "(>)", "[>]", "fi", "ends with":
            op = .endsWith
        case "!(>)", "![>]", "nf", "does not end with":
            op = .doesNotEndWith
        case "wi", "within", "is within":
            op = .within
        case "nw", "not within", "is not within":
            op = .notWithin
        default:
            op = .undefined
        }
    }
    
    /// Perform the appropriate comparison using the two passed values.
    func compare(_ value1: String, _ value2: String) -> Bool {
        
        let int1 = Int(value1)
        let int2 = Int(value2)
        if validForInts && int1 != nil && int2 != nil {
            return compareInts(int1!, int2!)
        }
        
        // Compare the string values.
        switch op {
        case .equals:
            return value1 == value2
        case .notEqualTo:
            return value1 != value2
        case .greaterThan:
            return value1 > value2
        case .greaterThanOrEqualTo:
            return value1 >= value2
        case .lessThan:
            return value1 < value2
        case .lessThanOrEqualTo:
            return value1 <= value2
        case .contains:
            return value1.contains(value2)
        case .doesNotContaIn:
            return !(value1.contains(value2))
        case .startsWith:
            return value1.hasPrefix(value2)
        case .doesNotStartWith:
            return !(value1.hasPrefix(value2))
        case .endsWith:
            return value1.hasSuffix(value2)
        case .doesNotEndWith:
            return !(value1.hasSuffix(value2))
        case .within:
            return value2.contains(value1)
        case .notWithin:
            return !value2.contains(value1)
        default:
            return true
        }
        
    }
    
    /// Perform the appropriate comparison using the two passed values.
    func compare(_ value1: StringValue, _ value2: String) -> Bool {
        let int1 = Int(value1.value)
        let int2 = Int(value2)
        if validForInts && int1 != nil && int2 != nil {
            return compareInts(int1!, int2!)
        }
        
        var value1Lower = ""
        if compareLowercase {
            value1Lower = value1.value.lowercased()
        }
        
        // Compare the string values.
        switch op {
        case .equals:
            return value1.value == value2
        case .notEqualTo:
            return value1.value != value2
        case .greaterThan:
            return value1.value > value2
        case .greaterThanOrEqualTo:
            return value1.value >= value2
        case .lessThan:
            return value1.value < value2
        case .lessThanOrEqualTo:
            return value1.value <= value2
        case .contains:
            return value1Lower.contains(value2)
        case .doesNotContaIn:
            return !(value1Lower.contains(value2))
        case .startsWith:
            return value1Lower.hasPrefix(value2)
        case .doesNotStartWith:
            return !(value1Lower.hasPrefix(value2))
        case .endsWith:
            return value1Lower.hasSuffix(value2)
        case .doesNotEndWith:
            return !(value1Lower.hasSuffix(value2))
        case .within:
            return value2.contains(value1Lower)
        case .notWithin:
            return !value2.contains(value1Lower)
        default:
            return true
        }
        
    }
    
    var compareLowercase: Bool {
        switch op {
        case .contains, .doesNotContaIn, .startsWith, .doesNotStartWith, .endsWith, .doesNotEndWith, .within, .notWithin:
            return true
        default:
            return false
        }
    }
    
    /// Is this operator valid for integers?
    var validForInts: Bool {
        switch op {
        case .equals, .greaterThanOrEqualTo, .greaterThan, .notEqualTo, .lessThanOrEqualTo, .lessThan:
            return true
        default:
            return false
        }
    }
    
    /// Compare integer values
    func compareInts(_ int1: Int, _ int2: Int) -> Bool {
        switch op {
        case .equals:
            return int1 == int2
        case .notEqualTo:
            return int1 != int2
        case .greaterThan:
            return int1 > int2
        case .greaterThanOrEqualTo:
            return int1 >= int2
        case .lessThan:
            return int1 < int2
        case .lessThanOrEqualTo:
            return int1 <= int2
        default:
            return true
        }
    }
}

/// The enum used to identify the comparison operator.
enum ComparisonOperator {
    
    case undefined
    case equals
    case greaterThan
    case greaterThanOrEqualTo
    case lessThan
    case lessThanOrEqualTo
    case notEqualTo
    case contains
    case within
    case notWithin
    case doesNotContaIn
    case startsWith
    case doesNotStartWith
    case endsWith
    case doesNotEndWith
}
