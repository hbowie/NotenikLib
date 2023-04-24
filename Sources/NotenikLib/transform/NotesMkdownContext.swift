//
//  NotesMkdownContext.swift
//  NotenikLib
//
//  Created by Herb Bowie on 7/12/21.
//
//  Copyright © 2021 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikMkdown
import NotenikUtils

/// A class that can provide the Markdown parser with contextual information about
/// the environment from which the Markdown text was provided. 
public class NotesMkdownContext: MkdownContext {
    
    // -----------------------------------------------------------
    //
    // MARK: Initial setup.
    //
    // -----------------------------------------------------------
    
    
    // Loaded at initialization. 
    var io: NotenikIO
    var displayParms = DisplayParms()
    
    var mkdownCommandList = MkdownCommandList(collectionLevel: false)
    
    let htmlConverter = StringConverter()
    
    public var includedNotes: [String] = []
    
    public init(io: NotenikIO, displayParms: DisplayParms? = nil) {
        self.io = io
        if displayParms != nil {
            self.displayParms = displayParms!
        }
        htmlConverter.addHTML()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Set the title of the Note to be parsed.
    //
    // -----------------------------------------------------------
    
    /// Set the Title of the Note whose Markdown text is to be parsed.
    public func setTitleToParse(title: String, shortID: String) {
        guard let collection = io.collection else { return }
        collection.titleToParse = title
        collection.shortID = shortID
        mkdownCommandList = MkdownCommandList(collectionLevel: false)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Expose the usage of a Markdown command. 
    //
    // -----------------------------------------------------------
    
    /// Expose the usage of a Markdown command found within the page.
    public func exposeMarkdownCommand(_ command: String) {
        guard let collection = io.collection else { return }
        guard !collection.titleToParse.isEmpty else { return }
        mkdownCommandList.updateWith(command: command, noteTitle: collection.titleToParse, code: nil)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Wiki Link Lookup.
    //
    // -----------------------------------------------------------
    
    /// Investigate an apparent link to another note, replacing it, if necessary, with
    /// a current and valid link.
    /// - Parameter title: A wiki link target that is possibly a timestamp instead of a title.
    /// - Returns: The corresponding title, if the lookup was successful, otherwise the title
    ///            that was passed as input.
    public func mkdownWikiLinkLookup(linkText: String) -> WikiLinkTarget? {
        
        let resolution = NoteLinkResolution(io: io, linkText: linkText)
        NoteLinkResolver.resolve(resolution: resolution)
        return resolution.genWikiLinkTarget()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Include another item (Note or file).
    //
    // -----------------------------------------------------------
    
    public func mkdownInclude(item: String, style: String) -> String? {
        guard io.collection != nil else { return nil }
        guard io.collectionOpen else { return nil }
        var str: String?
        if item.contains(".") {
            str = includeFromFile(item: item)
        }
        if str == nil {
            str = includeFromNote(item: item, style: style)
        }
        return str
    }
    
    func includeFromFile(item: String) -> String? {
        guard let collection = io.collection else { return nil }
        guard let collectionURL = collection.fullPathURL else { return nil }
        let fileURL = URL(fileURLWithPath: item,
                                isDirectory: false,
                                relativeTo: collectionURL)
        if let str = try? String(contentsOf: fileURL) {
            return str
        }
        return nil
    }
    
    public func clearIncludedNotes() {
        includedNotes = []
    }
    
    func includeFromNote(item: String, style: String) -> String? {
        
        let resolution = NoteLinkResolution(io: io, linkText: item)
        NoteLinkResolver.resolve(resolution: resolution)

        guard resolution.result != .badInput else { return item }
        
        guard resolution.result == .resolved else {
            return "Note titled '\(item)' could not be included"
        }
        
        includedNotes.append(resolution.pathSlashID)
        
        switch style {
        case "body":
            return resolution.resolvedNote!.body.value
        case "note":
            return includeTextFromNote(note: resolution.resolvedNote!)
        case "quotebody", "quote-body":
            return includeQuoteFromNote(note: resolution.resolvedNote!, withAttrib: false)
        case "quote":
            return includeQuoteFromNote(note: resolution.resolvedNote!)
        default:
            return resolution.resolvedNote!.body.value
        }
    }
    
    func includeTextFromNote(note: Note) -> String? {
        let maker = NoteLineMaker()
        _ = maker.putNote(note)
        if let writer = maker.writer as? BigStringWriter {
            return writer.bigString
        }
        return nil
    }
    
    func includeQuoteFromNote(note: Note, withAttrib: Bool = true) -> String? {
        let markedUp = Markedup(format: .htmlFragment)
        markedUp.newLine()
        markedUp.newLine()
        markedUp.startCompacting()
        let fieldsToHTML = NoteFieldsToHTML()
        fieldsToHTML.formatQuoteWithAttribution(note: note,
                                                markedup: markedUp,
                                                parms: displayParms,
                                                io: io,
                                                bodyHTML: nil,
                                                withAttrib: withAttrib)
        return markedUp.code
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Collection Table of Contents.
    //
    // -----------------------------------------------------------
    
    var levelStart = 0
    var levelEnd = 999
    var hasLevel = false
    var hasSeq = false
    var hasLevelAndSeq: Bool {
        return hasLevel && hasSeq
    }
    var toc = Markedup(format: .htmlFragment)
    var levels: [Int] = []
    var lastLevel: Int {
        if levels.count > 0 {
            return levels[levels.count - 1]
        } else {
            return 0
        }
    }
    
    public func mkdownCollectionTOC(levelStart: Int, levelEnd: Int) -> String {
        self.levelStart = levelStart
        self.levelEnd = levelEnd
        guard io.collectionOpen else { return "" }
        guard let collection = io.collection else { return "" }
        collection.tocNoteID = StringUtils.toCommon(collection.titleToParse)
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        levels = []
        toc = Markedup(format: .htmlFragment)
        var (note, position) = io.firstNote()
        while note != nil {
            if note!.noteID.identifier != collection.tocNoteID {
                genTocEntry(for: note!)
            }
            (note, position) = io.nextNote(position)
        }
        closeTocEntries(downTo: 0)
        return toc.code
    }
    
    func genTocEntry(for note: Note) {
        var level = note.level.getInt()
        let seq = note.seq.value
        if hasLevelAndSeq && level <= 1 && seq.count == 0 { return }
        if !hasLevel { level = 1 }
        guard level >= levelStart else { return }
        guard level <= levelEnd else { return }
        guard note.mkdownCommandList.includeInBook(epub: displayParms.epub3) else { return }
        
        // Manage nested lists.
        if level < lastLevel {
            closeTocEntries(downTo: level)
        }
        /* else */
        if level == lastLevel {
            toc.finishListItem()
        }
        /* else */
        if level > lastLevel {
            toc.startUnorderedList(klass: nil)
            levels.append(level)
        }
        
        // Display the next TOC entry
        toc.startListItem()
        if seq.count > 0 && !note.klass.frontOrBack {
            toc.write("\(seq) ")
        }
        let title = note.title.value
        let link = displayParms.assembleWikiLink(title: title)
        let text = htmlConverter.convert(from: title)
        toc.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
    }
    
    func closeTocEntries(downTo: Int) {
        while lastLevel > downTo {
            toc.finishListItem()
            toc.finishUnorderedList()
            let top = levels.count - 1
            levels.remove(at: top)
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for an Index to the Collection.
    //
    // -----------------------------------------------------------
    
    var indexCollection  = IndexCollection()
    
    public var termCount = 0
    public var pageCount = 0
    
    /// Return an index to the Collection, formatted in HTML.
    public func mkdownIndex() -> String {
        
        // Spin through the collection and collection index terms and references.
        indexCollection  = IndexCollection()
        var (note, position) = io.firstNote()
        while note != nil {
            if note!.hasTitle() && note!.hasIndex() && note!.mkdownCommandList.includeInBook(epub: displayParms.epub3) {
                let pageType = note!.getFieldAsString(label: NotenikConstants.typeCommon)
                indexCollection.add(page: note!.title.value, pageType: pageType, index: note!.index)
            }
            (note, position) = io.nextNote(position)
        }
        
        // Now sort the list of terms.
        indexCollection.sort()
        
        // Generate an index, formatted using Markdown.
        let mkdown = Markedup(format: .htmlFragment)
        termCount = 0
        pageCount = 0
        var lastLetter = " "
        
        // Generate Table of Contents
        mkdown.startParagraph()
        for term in indexCollection.list {
            let initialLetter = term.term.prefix(1).uppercased()
            if initialLetter != lastLetter {
                mkdown.link(text: initialLetter, path: "#letter-\(initialLetter.lowercased())", klass: Markedup.htmlClassNavLink)
                mkdown.newLine()
                lastLetter = initialLetter
            }
        }
        mkdown.finishParagraph()
        
        // Generate the index
        lastLetter = " "
        for term in indexCollection.list {
            termCount += 1
            let initialLetter = term.term.prefix(1).uppercased()
            if initialLetter != lastLetter {
                if lastLetter != " " {
                    mkdown.finishDefinitionList()
                }
                mkdown.heading(level: 3, text: "&#8212; \(initialLetter) &#8212;", addID: true, idText: "letter-\(initialLetter)")
                lastLetter = initialLetter
                mkdown.startDefinitionList(klass: nil)
            }
            mkdown.startDefTerm()
            mkdown.append(term.term)
            mkdown.finishDefTerm()
            for ref in term.refs {
                pageCount += 1
                mkdown.startDefDef()
                let link = displayParms.assembleWikiLink(title: ref.page)
                let text = htmlConverter.convert(from: ref.page)
                mkdown.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                mkdown.finishDefDef()
            }
        }
        mkdown.finishDefinitionList()
        return mkdown.code
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Collection Search Form.
    //
    // -----------------------------------------------------------
    
    /// Return a search page for the Collection, formatted in HTML.
    public func mkdownSearch(siteURL: String) -> String {
        
        // Generate the page, formatted using HTML.
        let markup = Markedup(format: .htmlFragment)
        
        markup.startDiv(klass: "search-page")
        
        markup.startDiv(klass: "search-form")
        markup.startForm(action: "https://duckduckgo.com/", method: "get", id: "form-search")
        markup.formLabel(labelFor: "input-search", labelText: "Enter your search term:")
        markup.formInput(inputType: "text", name: "q", value: nil, id: "input-search")
        markup.formInput(inputType: "hidden", name: "sites", value: siteURL, id: nil)
        markup.formButton(buttonType: "submit", buttonText: "Search",
                          klass: "btn btn-primary", id: "submit-search")
        markup.finishForm()
        markup.finishDiv()
        
        markup.startDiv(klass: nil, id: "search-results")
        markup.finishDiv()
        markup.finishDiv()
        
        markup.startScript()
        markup.ensureNewLine()
        markup.writeLine("let searchIndex = [ ")
        var (note, position) = io.firstNote()
        while note != nil {
            
            markup.writeLine("    { ")
            
            // Generate title
            markup.writeLine("        title: \"\(note!.title.value)\", ")
            
            // Generate date
            if note!.hasDate() {
                markup.writeLine("        date: \"\(note!.getDateAsField()!)\", ")
            } else {
                markup.writeLine("        date: \"\", ")
            }
            
            // Generate URL
            let resolution = NoteLinkResolution(io: io, linkText: note!.title.value)
            NoteLinkResolver.resolve(resolution: resolution)
            if let target = resolution.genWikiLinkTarget() {
                let url = displayParms.assembleWikiLink(target: target)
                markup.writeLine("        url: \"\(url)\", ")
            } else {
                markup.writeLine("        url: \"\", ")
            }
            
            // Generate summary
            var summaryText = ""
            if note!.hasTeaser() {
                summaryText = note!.teaser.value
            } else {
                summaryText = StringUtils.summarize(note!.body.value)
            }
            let mkd = MkdownParser(summaryText, options: displayParms.genMkdownOptions())
            mkd.parse()
            
            let escaped = StringUtils.prepHTMLforJSON(mkd.html)
            markup.writeLine("        summary: \"\(escaped)\", ")
            
            // Generate content
            let pureContent = StringUtils.purifyPunctuation(note!.body.value)
            markup.writeLine("        content: \"\(pureContent)\"")
            
            markup.writeLine("    }, ")
            (note, position) = io.nextNote(position)
        }
        markup.ensureNewLine()
        markup.writeLine("]; ")
        let searchScript = """
        /**
         * Based on Go Make Things blog post at:
         * https://gomakethings.com/how-to-create-a-vanilla-js-search-page-for-a-static-website/
         */
        (function (window, document, undefined) {

            'use strict';

            //
            // Variables
            //

            let form = document.querySelector('#form-search');
            let input = document.querySelector('#input-search');
            let resultList = document.querySelector('#search-results');

            //
            // Methods
            //

            /**
             * Create the HTML for each result
             * @param  {Object} article The article
             * @param  {Number} id      The result index
             * @return {String}         The markup
             */
            let createHTML = function (article, id) {
                let html =
                    '<div id="search-result-' + id + '">' +
                        '<h4>' +
                            '<a href="' + article.url + '" class="nav-link">' +
                                article.title +
                            '</a>' +
                        '</h2>' +
                        article.summary + '<br>' +
                    '</div>';
                return html;
            };

            /**
             * Create the markup for results
             * @param  {Array} results The results to display
             * @return {String}        The results HTML
             */
            let createResultsHTML = function (results) {
                let html = '<p>Found ' + results.length + ' matching pages</p>';
                html += results.map(function (article, index) {
                    return createHTML(article, index);
                }).join('');
                return html;
            };

            /**
             * Create the markup when no results are found
             * @return {String} The markup
             */
            let createNoResultsHTML = function () {
                return '<p>Sorry, no matches were found.</p>';
            };

            /**
             * Search for matches
             * @param  {String} query The term to search for
             */
            let search = function (query) {

                // Variables
                let reg = new RegExp(query, 'gi');
                let priority1 = []
                let priority2 = []

                searchIndex.forEach(function (article) {
                    if (reg.test(article.title)) return priority1.push(article);
                    if (reg.test(article.content)) priority2.push(article);
                });

                let results = [].concat(priority1, priority2)

                // Display the results
                resultList.innerHTML = results.length < 1 ? createNoResultsHTML() : createResultsHTML(results);
            };

            /**
             * Handle submit events
             */
            let submitHandler = function (event) {
                event.preventDefault();
                search(input.value);
            };

            //
            // Inits & Event Listeners
            //

            // Make sure required content exists
            if (!form || !input || !resultList || !searchIndex) return;

            // Create a submit handler
            form.addEventListener('submit', submitHandler);

        })(window, document);
        """
        markup.append(searchScript)
        markup.finishScript()

        return markup.code
    }
    
    /// Generate javascript to sort the following table.
    public func mkdownTableSort(tableID: String) -> String {
        
        let markup = Markedup(format: .htmlFragment)
        
        markup.startScript()
        markup.newLine()
        let searchScript = """
        function sortTable(n) {
          var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
          var firstElement = "";
          var nextElement = "";
          var firstLowered = "";
          var nextLowered = "";
          var firstNumber = 0;
          var nextNumber = 0;
          var firstValue = 0;
          var nextValue = 0;
          table = document.getElementById("\(tableID)");
          switching = true;
          // Set the sorting direction to ascending:
          dir = "asc";
          /* Make a loop that will continue until
          no switching has been done: */
          while (switching) {
            // Start by saying: no switching is done:
            switching = false;
            rows = table.rows;
            /* Loop through all table rows (except the
            first, which contains table headers): */
            for (i = 1; i < (rows.length - 1); i++) {
              // Start by saying there should be no switching:
              shouldSwitch = false;
              /* Get the two elements you want to compare,
              one from current row and one from the next: */
              firstElement = rows[i].getElementsByTagName("TD")[n];
              nextElement = rows[i + 1].getElementsByTagName("TD")[n];
              firstLowered = firstElement.innerHTML.toLowerCase();
              nextLowered = nextElement.innerHTML.toLowerCase();
              firstNumber = Number(firstLowered);
              nextNumber = Number(nextLowered);
              if (isNaN(firstLowered) || isNaN(nextLowered)) {
                x = firstLowered;
                y = nextLowered;
              } else {
                x = firstNumber;
                y = nextNumber;
              }
              
              /* Check if the two rows should switch place,
              based on the direction, asc or desc: */
              if (dir == "asc") {
                if (x > y) {
                  // If so, mark as a switch and break the loop:
                  shouldSwitch = true;
                  break;
                }
              } else if (dir == "desc") {
                if (x < y) {
                  // If so, mark as a switch and break the loop:
                  shouldSwitch = true;
                  break;
                }
              }
            }
            if (shouldSwitch) {
              /* If a switch has been marked, make the switch
              and mark that a switch has been done: */
              rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
              switching = true;
              // Each time a switch is done, increase this count by 1:
              switchcount ++;
            } else {
              /* If no switching has been done AND the direction is "asc",
              set the direction to "desc" and run the while loop again. */
              if (switchcount == 0 && dir == "asc") {
                dir = "desc";
                switching = true;
              }
            }
          }
        }
        """
        markup.append(searchScript)
        markup.finishScript()

        return markup.code
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Tags Outline.
    //
    // -----------------------------------------------------------
  
    var tagsCode = Markedup(format: .htmlFragment)
    var tagsListLevel = 0
    
    /// Generate a separate page organized by Tags.
    public func mkdownTagsOutline(mods: String) -> String {
        guard io.collection != nil else { return "" }
        guard io.collectionOpen else { return "" }
        let includeUntagged = mods.isEmpty
        tagsCode = Markedup(format: .htmlFragment)
        tagsListLevel = 0
        openTagsList()
        let iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        while tagsNode != nil {
            generateTagsNode(node: tagsNode!, depth: iterator.depth, includeUntagged: includeUntagged)
            tagsNode = iterator.next()
        }
        closeTagContent(downTo: 0)
        return tagsCode.code
    }
    
    /// Generate html code for the next node.
    func generateTagsNode(node: TagsNode, depth: Int, includeUntagged: Bool) {
        switch node.type {
        case .root:
            break
        case .tag:
            closeTagContent(downTo: depth)
            tagsCode.startListItem()
            let text = htmlConverter.convert(from: node.description)
            tagsCode.startDetails(summary: text)
            // tagsCode.writeLine(text)
            openTagsList()
        case .note:
            let note = node.note!
            if includeUntagged || note.hasTags() {
                let seq = note.seq.value
                let title = note.title.value
                let link = displayParms.assembleWikiLink(title: title)
                tagsCode.startListItem()
                if seq.count > 0 {
                    tagsCode.write("\(seq) ")
                }
                let text = htmlConverter.convert(from: title)
                tagsCode.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                tagsCode.finishListItem()
            }
        }
    }
    
    func openTagsList() {
        tagsCode.startUnorderedList(klass: "tags-list")
        tagsListLevel += 1
    }
    
    func closeTagContent(downTo: Int) {
        while tagsListLevel > downTo {
            closeTagContents(level: tagsListLevel)
        }
    }
    
    func closeTagContents(level: Int) {
        tagsCode.finishUnorderedList()
        if level > 1 {
            tagsCode.finishDetails()
            tagsCode.finishListItem()
        }
        tagsListLevel -= 1
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML with teasers for children.
    //
    // -----------------------------------------------------------
    
    /// Return a list of children, with teasers formatted in HTML.
    public func mkdownTeasers() -> String {

        guard let collection = io.collection else { return "" }
        guard io.collectionOpen else { return "" }
        
        guard collection.seqFieldDef != nil else { return "" }
        guard collection.teaserFieldDef != nil else { return "" }
        guard collection.levelFieldDef != nil else { return "" }
        guard collection.sortParm == .seqPlusTitle else { return "" }
        
        
        guard let parent = io.getNote(knownAs: collection.titleToParse) else { return "" }
        let currentPosition = io.positionOfNote(parent)
        let (nextNote, nextPosition) = io.nextNote(currentPosition)
        guard nextPosition.valid && nextNote != nil else { return "" }
        
        var children: [Note] = []
        
        let nextLevel = nextNote!.level
        let nextSeq = nextNote!.seq

        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        var followingNote: Note?
        followingNote = nextNote
        var followingPosition = nextPosition
        var followingLevel = LevelValue(i: nextLevel.getInt(), config: io.collection!.levelConfig)
        var followingSeq = nextSeq.dupe()
        
        var displayedChildCount = 0
        
        while followingNote != nil
                && followingPosition.valid
                && followingLevel > parent.level
                && followingSeq > parent.seq {
            
            if followingLevel == nextLevel {
                children.append(followingNote!)
            }
            
            let (nextUpNote, nextUpPosition) = io.nextNote(followingPosition)

            displayedChildCount += 1

            followingNote = nextUpNote
            followingPosition = nextUpPosition

            if followingNote != nil {
                followingLevel = followingNote!.level
                followingSeq = followingNote!.seq
            }
        }
        
        let teasers = Markedup()
        let startingFormat = displayParms.format
        displayParms.format = .htmlFragment
        let mkdownOptions = displayParms.genMkdownOptions()
        
        for child in children {
            
            teasers.startParagraph()
            
            let seq = child.seq
            let seqStack = seq.seqStack
            let finalSegment = seqStack.segments[seqStack.max]
            teasers.append("\(finalSegment.value). ")
            
            let mkdown = MkdownParser(child.teaser.value, options: mkdownOptions)
            // mkdown.setWikiLinkFormatting(prefix: "", format: .fileName, suffix: ".html", context: workspace?.mkdownContext)
            // mkdown.setWikiLinkFormatting(prefix: "#", format: .fileName, suffix: "", context: workspace?.mkdownContext)
            mkdown.setWikiLinkFormatting(prefix: mkdownOptions.wikiLinkPrefix,
                                         format: mkdownOptions.wikiLinkFormatting,
                                         suffix: mkdownOptions.wikiLinkSuffix,
                                         context: self)
            mkdown.parse()
            let stripped = StringUtils.removeParagraphTags(mkdown.html)
            teasers.append(stripped)
 
            teasers.finishParagraph()
        }
        
        displayParms.format = startingFormat
        if displayedChildCount > 0 {
            collection.skipContentsForParent = true
        }
        
        return teasers.code
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate HTML for a Tags Cloud.
    //
    // -----------------------------------------------------------
    
    var tagsList: [String] = []
    var tagsConcat = ""
    var tagsLast = ""
    
    /// Return a tags cloud of the collection, formatted in HTML.
    public func mkdownTagsCloud(mods: String) -> String {
        guard io.collection != nil else { return "" }
        guard io.collectionOpen else { return "" }
        tagsCode = Markedup(format: .htmlFragment)
        
        // Perform first pass.
        tagsLast = ""
        tagsCode.startUnorderedList(klass: "tags-cloud")
        var iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        while tagsNode != nil {
            generateTagsCloudNode(pass: 1, node: tagsNode!, depth: iterator.depth)
            tagsNode = iterator.next()
        }
        tagsCode.finishUnorderedList()
        
        tagsCode.horizontalRule()
        
        // Perform second pass.
        tagsLast = ""
        tagsCode.startDiv(klass: "tags-contents")
        iterator = io.makeTagsNodeIterator()
        tagsNode = iterator.next()
        while tagsNode != nil {
            generateTagsCloudNode(pass: 2, node: tagsNode!, depth: iterator.depth)
            tagsNode = iterator.next()
        }
        if !tagsLast.isEmpty {
            tagsCode.finishUnorderedList()
        }
        tagsCode.finishDiv()
        
        return tagsCode.code
    }
    
    /// Generate html code for the next node.
    func generateTagsCloudNode(pass: Int, node: TagsNode, depth: Int) {
        switch node.type {
        case .root:
            break
        case .tag:
            if tagsList.count >= depth {
                tagsList[depth - 1] = node.tag!.forDisplay
            } else {
                tagsList.append(node.tag!.forDisplay)
            }
            tagsConcat = ""
            var i = 0
            while i < depth {
                if i > 0 {
                    tagsConcat.append(".")
                }
                tagsConcat.append(tagsList[i])
                i += 1
            }
        case .note:
            let note = node.note!
            guard note.hasTags() else { break }

            if tagsConcat != tagsLast {
                if pass == 1 {
                    startTagsCloudFirstPass()
                } else {
                    startTagsCloudSecondPass()
                }
                tagsLast = tagsConcat
            }
            
            guard pass == 2 else { break }
            
            let title = note.title.value
            let link = displayParms.assembleWikiLink(title: title)
            let text = htmlConverter.convert(from: title)
            tagsCode.startListItem()
            tagsCode.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
            tagsCode.finishListItem()

        }
    }
    
    func startTagsCloudFirstPass() {
        tagsCode.startListItem()
        tagsCode.link(text: tagsConcat, path: "#tags.\(StringUtils.toCommonFileName(tagsConcat))")
        tagsCode.finishListItem()
    }
    
    func startTagsCloudSecondPass() {
        if !tagsLast.isEmpty {
            tagsCode.finishUnorderedList()
        }
        tagsCode.heading(level: 5, text: tagsConcat, addID: true, idText: "tags.\(tagsConcat)")
        tagsCode.startUnorderedList(klass: nil)
    }
    
    var author = ""
    
    /// Generate a bibliography from Notes following this one.
    public func mkdownBibliography() -> String {

        guard let collection = io.collection else { return "" }
        guard io.collectionOpen else { return "" }
        guard collection.seqFieldDef != nil else { return "" }
        guard collection.levelFieldDef != nil else { return "" }
        let sortParm = collection.sortParm
        guard sortParm == .seqPlusTitle || sortParm == .custom else { return "" }
        
        guard let parent = io.getNote(knownAs: collection.titleToParse) else { return "" }
        
        hasLevel = (collection.levelFieldDef != nil)
        hasSeq = (collection.seqFieldDef != nil)
        
        let currentPosition = io.positionOfNote(parent)
        var (nextNote, nextPosition) = io.nextNote(currentPosition)
        guard nextPosition.valid && nextNote != nil else { return "" }
        
        let biblio = Markedup(format: .htmlFragment)
        biblio.startOrderedList(klass: "notenik-biblio-list")
        let startingFormat = displayParms.format
        displayParms.format = .htmlFragment
        
        var worksCount = 0
        var authorKlassFound = false
        
        while nextNote != nil
                && nextPosition.valid
                && nextNote!.level > parent.level
                && nextNote!.seq > parent.seq {
            
            if nextNote!.klass.value == NotenikConstants.authorKlass {
                author = nextNote!.title.value
                authorKlassFound = true
            }
            
            if nextNote!.hasAuthor() && !authorKlassFound {
                author = nextNote!.author.lastNameFirst
            }
            
            if (nextNote!.klass.value == NotenikConstants.workKlass || nextNote!.hasWorkTitle()) && !author.isEmpty {
                biblio.startListItem()
                
                // Author
                if authorKlassFound {
                    let link = displayParms.assembleWikiLink(title: author)
                    let text = htmlConverter.convert(from: author)
                    biblio.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                    biblio.append(" ")
                } else {
                    biblio.append("\(author) ")
                }
                
                // Date
                if nextNote!.hasDate() {
                    biblio.append("(\(nextNote!.date.value)) ")
                }
                
                // Title of Work
                var workTitle = ""
                if nextNote!.klass.value == NotenikConstants.workKlass {
                    workTitle = nextNote!.title.value
                } else {
                    workTitle = nextNote!.workTitle.value
                }
                let workType = nextNote!.workType
                var citeKlass = ""
                if workType.isMajor {
                    citeKlass = "notenik-cite-major"
                } else {
                    citeKlass = "notenik-cite-minor"
                }
                
                biblio.startCite(klass: citeKlass)
                if !workType.isMajor {
                    biblio.leftDoubleQuote()
                }
                if nextNote!.klass.value == NotenikConstants.workKlass {
                    let link = displayParms.assembleWikiLink(title: workTitle)
                    let text = htmlConverter.convert(from: workTitle)
                    biblio.link(text: text, path: link, klass: Markedup.htmlClassNavLink)
                } else {
                    biblio.append(workTitle)
                }
                
                if !workType.isMajor {
                    biblio.rightDoubleQuote()
                }
                biblio.finishCite()
                let workMajorTitle = nextNote!.getFieldAsString(label: "workmajortitle")
                if !workMajorTitle.isEmpty {
                    biblio.append(", ")
                    biblio.startCite(klass: "notenik-cite-major")
                    biblio.append(workMajorTitle)
                    biblio.finishCite()
                }
                biblio.append(". ")
                
                let publisher = nextNote!.getFieldAsString(label: NotenikConstants.publisherCommon)
                let pubCity = nextNote!.getFieldAsString(label: NotenikConstants.pubCityCommon)
                if !publisher.isEmpty {
                    if !pubCity.isEmpty {
                        biblio.append("\(pubCity): ")
                    }
                    biblio.append("\(publisher). ")
                }
                
                // Web Link
                var workLink = ""
                if nextNote!.hasLink() {
                    workLink = nextNote!.link.value
                }
                if !workLink.isEmpty {
                    biblio.startLink(path: workLink, klass: "ext-link", blankTarget: true)
                    biblio.append("Link")
                    biblio.finishLink()
                }
                biblio.finishListItem()
                worksCount += 1
            }
            
            (nextNote, nextPosition) = io.nextNote(nextPosition)
        }

        biblio.finishOrderedList()
        
        displayParms.format = startingFormat
        
        if worksCount > 0 {
            collection.skipContentsForParent = true
        }
        
        return biblio.code
    }
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "WebBookMaker",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "WebBookMaker",
                          level: .error,
                          message: msg)
    }
}
