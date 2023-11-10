//
//  LinkFormatter.swift
//  NotenikLib
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 11/7/23.
//

import Foundation

import NotenikUtils

public class LinkFormatter {
    
    let sepChar = "|"
    
    let schemeIx   = 0
    let hostIx     = 1
    let pathIx     = 2
    let queryIx    = 3
    let fragmentIx = 4
    
    let numberOfParts = 5
    
    var formatStack: [LinkPartInstruction] = []

    
    public init() {
        
    }
    
    public init(with codes: String) {
        set(to: codes)
    }
    
    public var hasCodes: Bool {
        return !formatStack.isEmpty
    }
    
    public var isEmpty: Bool {
        return formatStack.isEmpty
    }
    
    public func set(to codes: String) {
        let codeArray = codes.components(separatedBy: sepChar)
        var i =  0
        var lastInstruction = LinkPartInstruction(rawValue: "a")
        while i < numberOfParts {
            var instruction = LinkPartInstruction(rawValue: lastInstruction!.rawValue)
            if i < codeArray.count {
                let code = codeArray[i].lowercased()
                if !code.isEmpty {
                    let raw = code[code.startIndex]
                    let instr = LinkPartInstruction(rawValue: raw)
                    if instr != nil {
                        instruction = instr
                    }
                }
            }
            formatStack.append(instruction!)
            lastInstruction = instruction
            i += 1
        }
    }
    
    public func toCodes(withOptionalPrefix: Bool = true) -> String {
        var codes = ""
        if !formatStack.isEmpty && withOptionalPrefix {
            codes = ": "
        }
        var i = 0
        while i < formatStack.count {
            if i > 0 {
                codes.append(sepChar)
            }
            codes.append(formatStack[i].rawValue)
            i += 1
        }
        return codes
    }
    
    
    public func format(link: LinkValue) -> String {

        guard !formatStack.isEmpty else { return link.value }
        guard let url = link.url else { return link.value }
        guard let scheme = url.scheme else { return link.value }
        guard scheme == "http" || scheme == "https" else { return link.value }
        var str = ""
        
        // Format URL scheme.
        let schemeInstruction = formatStack[schemeIx]
        if schemeInstruction != .exclude {
            str.append(scheme + "://")
        }
        
        // Format URL Host.
        let hostInstruction = formatStack[hostIx]
        let host = url.host
        if host != nil {
            // Yes, we have host
            if hostInstruction != .exclude {
                // Yes we want to include the host.
                var hostStr = host!
                if hostInstruction == .simplify {
                    // We want to simply the presentation
                    let hostParts = host!.components(separatedBy: ".")
                    if hostParts.count >= 2 {
                        let lastIx = hostParts.count - 1
                        let nextToLastIx = lastIx - 1
                        let domainName = hostParts[nextToLastIx]
                        hostStr = String(domainName[domainName.startIndex]).uppercased()
                        if domainName.count > 1 {
                            let startPlusOne = domainName.index(after: domainName.startIndex)
                            hostStr.append(String(domainName[startPlusOne..<domainName.endIndex]))
                        } // end domain name of more than one character
                        let minor = hostParts[lastIx]
                        if minor != "com" && minor != "org" {
                            hostStr.append("." + minor)
                        }
                    } // end if we have at least two parts to the host
                } // end of simplification logic
                str.append(hostStr)
            }
        }
        
        // Format URL path.
        let pathInstruction = formatStack[pathIx]
        let path = url.path
        if !path.isEmpty && path != "/" {
            if pathInstruction != .exclude {
                if !str.isEmpty {
                    if pathInstruction == .simplify || (host != nil && hostInstruction == .simplify) {
                        str.append(": ")
                    } else {
                        str.append("/")
                    }
                }
                if pathInstruction == .simplify {
                    let lastPath = url.deletingPathExtension().lastPathComponent
                    let simplified = StringUtils.wordDemarcation(lastPath, caseMods: ["a", "a", "a"], delimiter: " ")
                    str.append(simplified)
                } else {
                    str.append(path)
                }
            }
        }
        
        // Format query.
        if let query = url.query {
            let queryInstruction = formatStack[queryIx]
            if queryInstruction != .exclude {
                str.append("?" + query)
            }
        }
        
        // Format fragment.
        if let fragment = url.fragment {
            let fragmentInstruction = formatStack[queryIx]
            if fragmentInstruction != .exclude {
                str.append("#" + fragment)
            }
        }
        
        return str
    }
    
    enum LinkPartInstruction: Character {
        case asIs     = "a"
        case simplify = "s"
        case exclude  = "x"
    }
}
