//
//  FieldDictionary.swift
//  Notenik
//
//  Created by Herb Bowie on 12/3/18.
//  Copyright © 2018 - 2020 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// A Dictionary of Field Definitions
public class FieldDictionary {
    
    var dict = [:] as [String: FieldDefinition]
    public var list: [FieldDefinition] = []
    var insertPositionFromEnd = 0
    var locked = false
    
    /// Default initializer
    init() {
        
    }
    
    /// Return the number of definitions in the dictionary
    var count: Int {
        return dict.count
    }
    
    /// Is this dictionary empty?
    var isEmpty: Bool {
        return (dict.isEmpty)
    }
    
    /// Does this dictionary have any definitions stored in it?
    var hasData: Bool {
        return (dict.count > 0)
    }
    
    public var isLocked: Bool {
        return locked
    }
    
    /// Lock the dictionary so that no more definitions may be added
    public func lock() {
        locked = true
    }
    
    /// Unlock the dictionary so that more definitions may be added
    public func unlock() {
        locked = false
    }
    
    public func checkTitle() {
        var i = 0
        var titleIx = -1
        for def in list {
            if def.fieldType.typeString == NotenikConstants.titleCommon  && i > 0 {
                titleIx = i
            }
            i += 1
        }
        if titleIx > 0 {
            let titleDef = list[titleIx]
            list.remove(at: titleIx)
            list.insert(titleDef, at: 0)
        }
    }
    
    /// Does the dictionary contain a definition for this field label?
    public func contains (_ def: FieldDefinition) -> Bool {
        let def = dict[def.fieldLabel.commonForm]
        return def != nil
    }
    
    /// Does the dictionary contain a definition for this field label?
    public func contains (_ label: FieldLabel) -> Bool {
        let def = dict[label.commonForm]
        return def != nil
    }
    
    /// Does the dictionary contain a definition for this field label?
    public func contains (_ label: String) -> Bool {
        let fieldLabel = FieldLabel(label)
        let def = dict[fieldLabel.commonForm]
        return def != nil
    }
    
    /// Return the optional definition for this field label
    func getDef(_ def: FieldDefinition) -> FieldDefinition? {
        return dict[def.fieldLabel.commonForm]
    }
    
    /// Return the optional definition for this field label
    func getDef(_ label: FieldLabel) -> FieldDefinition? {
        return dict[label.commonForm]
    }
    
    /// Return the optional definition for this field label
    public func getDef(_ labelStr: String) -> FieldDefinition? {
        let fieldLabel = FieldLabel(labelStr)
        return dict[fieldLabel.commonForm]
    }
    
    /// Get the definition from the dictionary, given its place in the list.
    ///
    /// - Parameter i: An index into the list of definitions in the dictionary.
    /// - Returns: An optional Field Definition, of nil, if the index is out of range.
    func getDef(_ i: Int) -> FieldDefinition? {
        if i < 0 || i >= list.count {
            return nil
        } else {
            return list [i]
        }
    }
    
    /// Add a new field definition to the dictionary, based on the passed field label string
    public func addDef (typeCatalog: AllTypes, label: String) -> FieldDefinition? {
        let def = FieldDefinition(typeCatalog: typeCatalog, label: label)
        return addDef(def)
    }
    
    /// Add a new field definition to the dictionary, based on the passed Field Label
    func addDef (typeCatalog: AllTypes, label: FieldLabel) -> FieldDefinition? {
        let def = FieldDefinition(typeCatalog: typeCatalog, label: label)
        return addDef(def)
        
    }
    
    /// Add a new field definition to the dictionary.
    ///
    /// - Parameter def: The field definition to be added.
    ///
    /// - Returns: The new definition just added, or the existing definition,
    ///            if the field was already in the dictionary.
    ///
    func addDef(_ def : FieldDefinition, family: String? = nil) -> FieldDefinition? {
        let common = def.fieldLabel.commonForm
        let existingDef = dict[common]
        if existingDef != nil {
            return existingDef!
        } else if locked {
            return nil
        } else {
            dict [common] = def
            if common == NotenikConstants.titleCommon
                || def.fieldType.typeString == NotenikConstants.titleCommon {
                if list.isEmpty {
                    list.append(def)
                } else {
                    list.insert(def, at: 0)
                }
            } else if common == NotenikConstants.bodyCommon
                        || def.fieldType.typeString == NotenikConstants.bodyCommon {
                list.append(def)
                insertPositionFromEnd += 1
            } else if family != nil && !family!.isEmpty {
                var i = list.count - 1
                while i > 1 && !list[i].fieldLabel.commonForm.starts(with: family!) {
                    i -= 1
                }
                list.insert(def, at: i + 1)
            } else if insertPositionFromEnd <= 0 {
                list.append(def)
            } else {
                list.insert(def, at: list.count - insertPositionFromEnd)
            }
            return def
        }
    }
    
    /// Remove the given definition from the dictionary and report our success
    public func removeDef(_ def: FieldDefinition) -> Bool {
        var removeOK = false
        let common = def.fieldLabel.commonForm
        dict.removeValue(forKey: common)
        var i = 0
        var looking = true
        while looking && i < list.count {
            let listDef = list[i]
            if common == listDef.fieldLabel.commonForm {
                looking = false
                removeOK = true
                list.remove(at: i)
            } else {
                i += 1
            }
        }
        return removeOK
    }
    
    public func display() {
        print("FieldDictionary.display")
        for def in list {
            var values = ""
            if let picks = def.pickList {
                values = picks.getValueString()
            }
            print("- \(def.fieldLabel.properForm) \(def.fieldLabel.commonForm) \(def.fieldType.typeString) \(values)")
        }
    }
    
}
