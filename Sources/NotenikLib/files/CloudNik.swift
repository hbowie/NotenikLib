//
//  CloudNik.swift
//  
//
//  Created by Herb Bowie on 4/24/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class CloudNik {
    
    // Singleton instance
    static let shared = CloudNik()
    
    let fm = FileManager.default
    var ubiquityIdenityToken: Any?
    var url: URL?
    
    init() {
        print("CloudNik initialization...")
        ubiquityIdenityToken = fm.ubiquityIdentityToken
        if ubiquityIdenityToken == nil {
            print("iCloud not available")
        } else {
            print("iCloud available")
        }
        guard ubiquityIdenityToken != nil else { return }
        url = fm.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        if url == nil {
            print("iCloud container not available")
        } else {
            print("iCloud container located at \(url!.path)")
        }
    }
    
    var iCloudAvailable: Bool {
        ubiquityIdenityToken = fm.ubiquityIdentityToken
        return ubiquityIdenityToken != nil
    }
}
