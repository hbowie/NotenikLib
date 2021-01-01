//
//  MediumPost.swift
//
//  Created by Herb Bowie on 12/30/20.
//
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MediumPost: Codable {
    var title = ""
    var contentFormat = ""
    var content = ""
    var tags: [String]?
    var canonicalUrl: String?
    var publishStatus: String?
    var license: String?
    var notifyFollowers: Bool?
}
