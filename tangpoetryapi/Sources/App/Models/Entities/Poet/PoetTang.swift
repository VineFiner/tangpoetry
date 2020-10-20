//
//  PoetTang.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Fluent
import Vapor

final class PoetTang: Model, Content {
    static let schema = "poettangs"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "author")
    var authorName: String
    
    @Field(key: "content")
    var content: String
    
    // 初始化的时候，需要添加 authorID
    @Parent(key: "author_id")
    var author: PoetTangAuthor
    
    /*
     through: The pivot model's type.
     from: Key path from the pivot to the parent relation referencing the root model.
     to: Key path from the pivot to the parent relation referencing the related model.
     */
    @Siblings(through: PoetTangTag.self, from: \.$poetTang, to: \.$tag)
    public var tags: [PoetTag]
    
    init() { }

    init(id: UUID? = nil, title: String, authorName: String, content: String, authorID: UUID) {
        self.id = id
        self.title = title
        self.authorName = authorName
        self.content = content
        self.$author.id = authorID
    }
}
