//
//  AuthorPickList.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class AuthorPickList: PickList {
    
    public override init() {
        super.init()
    }
    
    public func registerAuthor(_ author: AuthorValue) {
        _ = registerValue(author)
    }
    
}
