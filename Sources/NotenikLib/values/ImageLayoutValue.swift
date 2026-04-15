//
//  ImageLayoutValue.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/6/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Indicates the sort of image layout desired. 
public class ImageLayoutValue: StringValue {
    
    let layouts = ImageLayoutList.shared
    
    public override func set(_ value: String) {
        let original = layouts.matchesOriginal(value: value)
        if original == nil {
            self.value = value
        } else {
            self.value = original!
        }
    }
    
    var enumValue: ImageLayoutEnum {
        if let eVal = ImageLayoutEnum(rawValue: value) {
            return eVal
        } else if let eVal = ImageLayoutEnum(rawValue: value.lowercased()) {
            return eVal
        } else {
            return ImageLayoutEnum.belowTitleFullWidth
        }
    }

}
