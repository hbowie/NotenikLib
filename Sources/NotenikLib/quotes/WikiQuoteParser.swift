//
//  WikiQuoteParser.swift
//  NotenikLib
//
//  Created by Herb Bowie on 9/24/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import SwiftSoup

public class WikiQuoteParser {
    
    var doc: Document
    var elements: Elements?
    public var quotes: [Quote] = []
    
    public var count: Int {
        return quotes.count
    }
    
    var quote = Quote()
    var quoteIndex = -1
    
    public init?(author: String, link: String, html: String) {
        quote.author = author
        quote.link = link
        do {
            doc = try SwiftSoup.parse(html)
            elements = try? doc.getAllElements()
            if elements != nil {
                var quotesStarted = false
                var quotesFinished = false
                var id = ""
                for element in elements! {
                    if !quotesStarted && element.id() == "Quotes" {
                        quotesStarted = true
                    }
                    if !quotesFinished {
                        if element.id().starts(with: "Quotes_about") {
                            quotesFinished = true
                        }
                        if element.id() == "External_links" {
                            quotesFinished = true
                        }
                        if element.id() == "footer" {
                            quotesFinished = true
                        }
                    }
                    if quotesStarted && !quotesFinished {
                        if element.tagNameNormal() == "h3" {
                            if element.id().count > 0 {
                                id = "#\(element.id())"
                            }
                            if element.hasText() {
                                let text = try element.text()
                                quote.setWorkTitleAndYear(str: text)
                            }
                        }
                        if element.tagNameNormal() == "li" {
                            if element.hasText() {
                                let text = try element.text()
                                if quote.hasText {
                                    if quote.text.hasSuffix(text) {
                                        quote.text.removeLast(text.count)
                                        quote.parseTrailer(text)
                                    } else {
                                        saveQuote()
                                        quote.link = "\(link)\(id)"
                                        quote.setText(str: text)
                                    }
                                } else {
                                    quote.link = "\(link)\(id)"
                                    quote.setText(str: text)
                                }
                            }
                        }
                    }
                }
            }
        } catch Exception.Error(_, let message) {
            print(message)
            return nil
        } catch {
            print("error")
            return nil
        }
    }
    
    func saveQuote() {
        guard quote.hasText else { return }
        quotes.append(quote)
        let newQuote = Quote(quote)
        quote = newQuote
    }
    
}
