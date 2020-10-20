//
//  PublicPoetTang.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Fluent
import Vapor

struct PublicPoetTang: Content {
    
    var id: UUID

    var title: String

    var author: String
    
    var content: [String]

    init(id: UUID, title: String, author: String, content: [String]) {
        self.id = id
        self.title = title
        self.author = author
        self.content = content
    }
}
