//
//  PoetTangTag.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Vapor
import Fluent

final class PoetTangTag: Model, Content {
    // Name of the table or collection.
    static let schema: String = "poettang+tag"
    
    // Unique identifier for this Tag.
    @ID(key: .id)
    var id: UUID?
    
    // Reference to the Tag this pivot relates.
    @Parent(key: "tag_id")
    var tag: PoetTag
    
    // Reference to the Star this pivot relates.
    @Parent(key: "poettang_id")
    var poetTang: PoetTang
    
    // Creates a new, empty pivot.
    init() {}
    
    // Creates a new pivot with all properties set.
    init(id: UUID? = nil, poetTang: PoetTang, tag: PoetTag) throws {
        self.id = id
        self.poetTang.id = try poetTang.requireID()
        self.$tag.id = try tag.requireID()
    }
}
