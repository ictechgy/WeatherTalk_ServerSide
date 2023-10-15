//
//  User.swift
//  
//
//  Created by Coden on 2023/10/11.
//

import Vapor
import Fluent

// MARK: - User

// MARK: User DTO for add
/// 신규 추가용 유저 DTO
struct UserToBeAdded: Decodable {
    let name: String
    let imageUrl: String?
    let userDescription: String
}

// MARK: - User Entity
/// 유저 Entity
final class User: Model, Content {
    static let schema = "users"
    
    @ID(custom: "id", generatedBy: .database) // Generator -> Self가 Int 타입이면 기본값이 .database
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @OptionalParent(key: "group_id") // 유의: Optional Parent의 경우 생성에 nil 불가. Decoding fail
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
