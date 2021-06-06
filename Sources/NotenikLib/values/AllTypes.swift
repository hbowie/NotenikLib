//
//  AllTypes.swift
//  Notenik
//
//  Created by Herb Bowie on 10/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A catalog of all available field types. One of these should be created for each Collection.
public class AllTypes {
    
    let artistType  = ArtistType()
    let authorType  = AuthorType()
    let bodyType    = BodyType()
    let booleanType = BooleanType()
    let codeType    = CodeType()
    let dateAddedType = DateAddedType()
    let dateModifiedType = DateModifiedType()
    let dateType    = DateType()
    let imageNameType = ImageNameType()
    let indexType   = IndexType()
    let intType     = IntType()
    let labelType   = StringType()
    let levelType   = LevelType()
    let linkType    = LinkType()
    let longTextType = LongTextType()
    let minutesToReadType = MinutesToReadType()
    let pickListType = PickListType()
    let ratingType  = RatingType()
    let recursType  = RecursType()
    let seqType     = SeqType()
    let statusType  = StatusType()
    let stringType  = StringType()
    let tagsType    = TagsType()
    let teaserType  = LongTextType()
    let titleType   = TitleType()
    let timestampType = TimestampType()
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
        
fieldTypes.append(artistType)
        
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
        fieldTypes.append(indexType)
        fieldTypes.append(intType)
        
        labelType.typeString = "label"
        fieldTypes.append(labelType)
        
        fieldTypes.append(levelType)
        
        fieldTypes.append(linkType)
        fieldTypes.append(longTextType)
        
        teaserType.properLabel = "Teaser"
        teaserType.commonLabel = "teaser"
        fieldTypes.append(teaserType)
        
        fieldTypes.append(minutesToReadType)
        fieldTypes.append(pickListType)
        fieldTypes.append(ratingType)
        fieldTypes.append(recursType)
        fieldTypes.append(seqType)
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
