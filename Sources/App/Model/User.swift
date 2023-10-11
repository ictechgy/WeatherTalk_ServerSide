//
//  User.swift
//  
//
//  Created by Coden on 2023/10/11.
//

import Vapor
import Fluent

/// 신규 추가용 유저 DTO
struct UserToBeAdded: Decodable {
    let name: String
    let imageUrl: String?
    let userDescription: String
}

/// 유저 Entity
final class User: Model, Content {
    static let schema = "users"
    
    @ID(custom: "id", generatedBy: .database) // Int 타입이면 기본값이 .database
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @OptionalParent(key: "group_id")
    var group: Group?
    
    @OptionalField(key: "image_url")
    var imageUrl: String?
    
    @Field(key: "description")
    var userDescription: String
    
    init() { }
    
    init(id: Int? = nil, name: String, group: Group? = nil, imageUrl: String? = nil, userDescription: String) {
        self.id = id
        self.name = name
        self.$group.id = group?.id
        self.imageUrl = imageUrl
        self.userDescription = userDescription
    }
}
