//
//  AuthorValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 12/5/18.
//  Copyright © 2018 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The names associated with one or more individuals.
public class AuthorValue: StringValue, MultiValues {
    
    //
    // The following constants, variables and functions provide conformance to the MultiValues protocol.
    //
    
    public let multiDelimiter = ", "
    
    var lastName = ""
    var firstName = ""
    var middleName = ""
    var prefix = ""
    var suffix = ""
    var authors: [AuthorValue] = []
    
    public var multiCount: Int {
        if authors.count > 1 {
            return authors.count
        } else if self.value.isEmpty {
            return 0
        } else {
            return 1
        }
    }
    
    /// Return a sub-value at the given index position.
    /// - Returns: The indicated sub-value, for a valid index, otherwise nil.
    public func multiAt(_ index: Int) -> String? {
        
        guard index >= 0 else { return nil }
        guard index < multiCount else { return nil }
        if index > 0 || authors.count > 1 {
            return authors[index].firstNameFirst
        } else {
            return getCompleteName()
        }
    }
    
    public func append(_ str: String) {
        if self.isEmpty {
            set(str)
        } else {
            let anotherAuthor = AuthorValue(str)
            authors.append(anotherAuthor)
        }
    }
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value with a last name and a first name
    convenience init (lastName: String, firstName: String) {
        self.init()
        set(lastName: lastName, firstName: firstName)
    }
    
    /// Set an initial value with a last name and a first name and a suffix
    convenience init (lastName : String, firstName : String, suffix : String) {
        self.init()
        set(lastName: lastName, firstName: firstName, suffix: suffix)
    }
    
    /// Set an initial value with a complete name
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Use a last name first arrangement for the sort key
    public override var sortKey: String {
        return firstNameFirst
    }
    
    /// Return the first name first
    var firstNameFirst: String {
        var fnf = ""
        var i = 0
        if authors.count > 0 {
            for person in authors {
                fnf.append(person.firstNameFirst)
                if i < (authors.count - 2) {
                    fnf.append(", ")
                } else if i == (authors.count - 2) {
                    fnf.append(" and ")
                }
                i += 1
            }
        } else {
            fnf.append(firstName)
            if fnf.count > 0 && lastName.count > 0 {
                fnf.append(" ")
            }
            fnf.append(lastName)
            if fnf.count > 0 && suffix.count > 0 {
                fnf.append(" ")
            }
            fnf.append(suffix)
        }
        return fnf
    }
    
    var lastNameOrNames: String {
        if authors.count > 0 {
            var lastNames = ""
            for person in authors {
                if lastNames.count > 0 {
                    lastNames.append(", ")
                }
                lastNames.append(person.lastName)
            }
            return lastNames
        } else {
            return lastName
        }
    }
    
    /// Return the last name followed by a comma, then the first name and suffix
    var lastNameFirst: String {
        var lnf = ""
        var i = 0
        if authors.count > 0 {
            for person in authors {
                lnf.append(person.lastNameFirst)
                if i < (authors.count - 2) {
                    lnf.append(", ")
                } else if i == (authors.count - 2) {
                    lnf.append(" and ")
                }
                i += 1
            }
        } else {
            let lastNameLowered = lastName.lowercased()
            if lastNameLowered == "association" {
                lnf = firstNameFirst
            } else {
                lnf.append(lastName)
                if lnf.count > 0 && firstName.count > 0 {
                    lnf.append(", ")
                }
                lnf.append(firstName)
                if lnf.count > 0 && suffix.count > 0 {
                    lnf.append(" ")
                }
                lnf.append(suffix)
            }
        }
        return lnf
    }
    
    /// Return the number of people.
    var peopleCount: Int {
        if authors.count > 1 {
            return authors.count
        } else if count > 0 {
            return 1
        } else {
            return 0
        }
    }
    
    /// Get the complete name(s), as originally input by the user
    func getCompleteName() -> String {
        return self.value
    }
    
    /// Get the first name of the first or only person.
    func getFirstName() -> String {
        if authors.count > 0 {
            return authors[0].firstName
        } else {
            return self.firstName
        }
    }
    
    /// Get the last name of the first or only person.
    func getLastName() -> String {
        if authors.count > 0 {
            return authors[0].lastName
        } else {
            return self.lastName
        }
    }
    
    /// Get the suffix of the first or only person.
    func getSuffix() -> String {
        if authors.count > 0 {
            return authors[0].suffix
        } else {
            return self.suffix
        }
    }
    
    /// Get person number i from a list of people, where the first is numbered zero
    func getSubPerson(_ i: Int) -> AuthorValue? {
        if i == 0 && authors.count == 0 {
            return self
        } else if i < 0 || i >= authors.count {
            return nil
        } else {
            return authors[i]
        }
    }
    
    func setFromVcardName(name: String) {
        let nameComponents = name.components(separatedBy: ";")
        var i = 0
        for component in nameComponents {
            switch i {
            case 0:
                self.lastName = String(component)
            case 1:
                self.firstName = String(component)
            case 2:
                self.middleName = String(component)
            case 3:
                self.prefix = String(component)
            case 4:
                self.suffix = String(component)
            default:
                break
            }
            i += 1
        }
        self.value = name
        while self.value.hasSuffix(";") {
            self.value.removeLast()
        }
    }
    
    /// Set the person's name from a first name and last name
    func set (lastName : String, firstName : String) {
        authors = []
        self.lastName  = lastName
        self.firstName = firstName
        self.suffix    = ""
        self.value = lastName
        if lastName.count > 0 && firstName.count > 0 {
            self.value.append(", ")
        }
        self.value.append(firstName)
    }
    
    /// Set the Person's name from a first name and last name and suffix
    func set (lastName : String, firstName : String, suffix : String) {
        authors = []
        self.lastName  = lastName
        self.firstName = firstName
        self.suffix    = suffix
        self.value = lastName
        if lastName.count > 0 && firstName.count > 0 {
            self.value.append(", ")
        }
        self.value.append(firstName)
        if self.value.count > 0 && suffix.count > 0 {
            self.value.append(" ")
        }
        self.value.append(suffix)
    }
    
    /// Set the person name from a complete name
    ///
    /// Set the content of the Person object from a single String containing the
    /// complete name(s) of one or more person(s). If the string names multiple
    /// persons, then it is expected to be in the form "John Doe, Jane Smith and
    /// Joe Riley": in other words, with an "and" (or an ampersand) before the last
    /// name and with other names separated by commas.
    public override func set (_ value: String) {
        self.value = value
        self.lastName  = ""
        self.firstName = ""
        self.suffix    = ""
        authors = []
        var multiplePersons = false
        
        // Scan the input string and break it down into words
        var words : [PersonWord] = []
        var word = PersonWord()
        var commaCount = 0
        for c in value {
            if c == " " || c == "\t" || c == "\n" || c == "\r" || c == "~" || c == "_" {
                if word.count > 0 {
                    word.setDelim(" ")
                    if word.isAnd {
                        multiplePersons = true
                    }
                    words.append(word)
                    word = PersonWord()
                }
            } else if c == "," {
                if word.count > 0 {
                    word.setDelim(c)
                    words.append(word)
                    commaCount += 1
                    word = PersonWord()
                    if words.count > 1 {
                        multiplePersons = true
                    }
                }
            } else {
                word.append(c)
            }
        }
        if word.count > 0 {
            words.append(word)
        }
        
        // Now let's go through the list of words and create one or more names
        var wordNumber = 0
        var temp = TempName()
        for word in words {
            wordNumber += 1
            var endName = false
            if multiplePersons && word.isAnd {
                endName = true
            } else {
                temp.append(word: word, multiplePeople: multiplePersons)
                if multiplePersons && word.delim == "," {
                    endName = true
                }
                if wordNumber == words.count {
                    endName = true
                }
            }
            if endName && temp.count > 0 {
                if multiplePersons {
                    authors.append(temp.buildAuthorValue())
                    temp = TempName()
                } else {
                    self.lastName = temp.lastName
                    self.firstName = temp.firstName
                    self.suffix = temp.suffix
                }
            }
        }
    }
    
    func display() {
        print("    - Author last name: \(lastName), first name: \(firstName), suffix: \(suffix)")
    }
    
    /// A temporary inner class for building a single name
    class TempName {
        var completeName = ""
        var firstName = ""
        var lastName = ""
        var suffix = ""
        var lastNameFirst = false
        
        init() {
            
        }
        
        var count : Int {
            return completeName.count + firstName.count + lastName.count
        }
        
        /// Generate a valid Person Value from this temporary object
        func buildAuthorValue() -> AuthorValue {
            if lastName.count > 0 {
                return AuthorValue(lastName: lastName, firstName: firstName, suffix: suffix)
            } else {
                return AuthorValue(completeName)
            }
        }
        
        /// Figure out where to put the next word making up this temporary name
        func append (word: PersonWord, multiplePeople: Bool) {
            let lower = word.word.lowercased()
            if suffix.count == 0 && count > 0 && (lower == "jr" || lower == "jr."
                    || lower == "sr" || lower == "sr." || lower == "iii") {
                // We have a name suffix
                suffix = word.word
                appendToCompleteName(word.word)
            } else if word.delim == "," {
                if multiplePeople {
                    // Let's treat this as a last name (until another one comes along)
                    appendToCompleteName(word.word)
                    newLastName(word.word)
                } else {
                    // Delimiter is a comma indicating end of last name
                    lastNameFirst = true
                    appendToLastName(word.word)
                    appendToCompleteName(word.word)
                    if completeName.count > 0 {
                        completeName.append(", ")
                    }
                }
            } else {
                appendToCompleteName(word.word)
                if lastNameFirst {
                    appendToFirstName(word.word)
                } else {
                    newLastName(word.word)
                }
            }
        }
        
        /// Append the string to the complete name
        func appendToCompleteName(_ word : String) {
            if completeName.count > 0 {
                completeName.append(" ")
            }
            completeName.append(word)
        }
        
        /// Use this word as the new last name
        func newLastName(_ word : String) {
            appendToFirstName(lastName)
            lastName = word
        }
        
        /// Append the string to the last name
        func appendToLastName(_ word : String) {
            if lastName.count > 0 {
                lastName.append(" ")
            }
            lastName.append(word)
        }
        
        /// Append the string to the first name
        func appendToFirstName(_ word : String) {
            if firstName.count > 0 {
                firstName.append(" ")
            }
            firstName.append(word)
        }
        
    }
    
    /// An inner class for defining one word in a person's name
    class PersonWord {
        var word = ""
        var delim = " "
        
        init() {
            
        }
        
        var count: Int {
            return word.count
        }
        
        var isAnd: Bool {
            return word == "and" || word == "&" || word == "&amp;"
        }
        
        func append(_ c : Character) {
            word.append(String(c))
        }
        
        func setDelim(_ delim : Character) {
            self.delim = String(delim)
        }
        
        func display() {
            print("    - Person word: '\(word)', delim: '\(delim)', is and? \(isAnd)")
        }
        
    }
}
