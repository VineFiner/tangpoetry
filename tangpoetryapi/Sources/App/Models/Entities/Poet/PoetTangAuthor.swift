//
//  PoetTangAuthor.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Fluent
import Vapor

final class PoetTangAuthor: Model, Content {
    static let schema = "poettangauthors"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "desc")
    var desc: String
    
    // 无需 初始化添加 [poets]
    @Children(for: \.$author)
    var poets: [PoetTang]
    
    init() { }

    init(id: UUID? = nil, name: String, desc: String) {
        self.id = id
        self.name = name
        self.desc = desc
    }
}
