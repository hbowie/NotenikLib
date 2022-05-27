//
//  AllTypes.swift
//  NotenikLib
//
//  Created by Herb Bowie on 10/25/19.
//  Copyright © 2019 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A catalog of all available field types. One of these should be created for each Collection.
public class AllTypes {
    
    let akaType     = AKAType()
    let artistType  = ArtistType()
    let attribType  = AttribType()
    let authorType  = AuthorType()
    let backlinkType = BacklinkType()
    let bodyType    = BodyType()
    let booleanType = BooleanType()
    let codeType    = CodeType()
    let comboType   = ComboType()
    let dateAddedType = DateAddedType()
    let dateModifiedType = DateModifiedType()
    let dateType    = DateType()
    let imageNameType = ImageNameType()
    let includeChildrenType = IncludeChildrenType()
    let indexType   = IndexType()
    let intType     = IntType()
    let klassType   = KlassType()
    let labelType   = StringType()
    let levelType   = LevelType()
    let linkType    = LinkType()
    let longTextType = LongTextType()
    let lookupType  = LookupType()
    let minutesToReadType = MinutesToReadType()
    let pickListType = PickListType()
    let ratingType  = RatingType()
    let recursType  = RecursType()
    let seqType     = SeqType()
    let shortIdType = ShortIdType()
    let statusType  = StatusType()
    let stringType  = StringType()
    let tagsType    = TagsType()
    let teaserType  = TeaserType()
    let titleType   = TitleType()
    let timestampType = TimestampType()
    let wikilinkType = WikilinkType()
    let workLinkType = WorkLinkType()
    let workTitleType = WorkTitleType()
    let workTypeType = WorkTypeType()
    
    var fieldTypes: [AnyType] = []
    
    var statusValueConfig: StatusValueConfig {
        get {
            return statusType.statusValueConfig
        }
        set {
            statusType.statusValueConfig = newValue
        }
    }
    
    var levelValueConfig: IntWithLabelConfig {
        get {
            return levelType.config
        }
        set {
            levelType.config = newValue
        }
    }
    
    /// Initialize with all of the standard types. 
    init() {
        
        fieldTypes.append(akaType)
        fieldTypes.append(artistType)
        fieldTypes.append(attribType)
        
        fieldTypes.append(workLinkType)
        fieldTypes.append(workTitleType)
        fieldTypes.append(workTypeType)
        fieldTypes.append(artistType)
        fieldTypes.append(authorType)
        
        fieldTypes.append(bodyType)
        fieldTypes.append(booleanType)
        fieldTypes.append(codeType)
        fieldTypes.append(dateAddedType)
        fieldTypes.append(dateModifiedType)
        fieldTypes.append(dateType)
        fieldTypes.append(imageNameType)
        fieldTypes.append(includeChildrenType)
        fieldTypes.append(indexType)
        fieldTypes.append(intType)
        
        fieldTypes.append(klassType)
        
        labelType.typeString = "label"
        fieldTypes.append(labelType)
        
        fieldTypes.append(levelType)
        
        fieldTypes.append(backlinkType)
        fieldTypes.append(wikilinkType)
        
        fieldTypes.append(linkType)
        fieldTypes.append(longTextType)
        fieldTypes.append(lookupType)
        
        fieldTypes.append(teaserType)
        
        fieldTypes.append(comboType)
        fieldTypes.append(minutesToReadType)
        fieldTypes.append(pickListType)
        fieldTypes.append(ratingType)
        fieldTypes.append(recursType)
        fieldTypes.append(seqType)
        fieldTypes.append(shortIdType)
        fieldTypes.append(statusType)
        fieldTypes.append(stringType)
        fieldTypes.append(tagsType)
        fieldTypes.append(timestampType)
        fieldTypes.append(titleType)
        
    }
    
    /// Assign a field type based on a field label and, optionally, a type string. 
    func assignType(label: FieldLabel, type: String?) -> AnyType {
        
        for fieldType in fieldTypes {
            if fieldType.appliesTo(label: label, type: type) {
                return fieldType
            }
        }
        return stringType
    }
    
    /// Given just a data value, return value type that is the best fit.
    func assignType(value: String) -> AnyType {
        if value.count == 0 {
            return stringType
        } else {
            let possibleInt = Int(value)
            if possibleInt != nil {
                return intType
            } else {
                return stringType
            }
        }
    }
    
}
