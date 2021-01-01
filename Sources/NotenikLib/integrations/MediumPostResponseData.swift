//
//  MediumPostResponseData.swift
//
//  Created by Herb Bowie on 12/30/20.

//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MediumPostResponseData: Codable {
    var id = ""
    var title = ""
    var authorId = ""
    var tags: [String] = []
    var url = ""
    var canonicalUrl = ""
    var publishStatus = ""
    var publishedAt: Int?
    var license = ""
    var licenseUrl = ""
}
