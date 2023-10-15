//
//  Group.swift
//  
//
//  Created by Coden on 2023/10/11.
//

import Vapor
import Fluent

// MARK: - GROUP Entity
final class Group: Model, Content {
    static let schema = "groups"
    
    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    init() { }
    
    init(id: Int?, name: String) {
        self.id = id
        self.name = name
    }
}
