//
//  CreatePoetTangTag.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Foundation
import Fluent

struct CreatePoetTangTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettang+tags")
            .id()
            /// 外键 数据库 schema
            .field("poettang_id", .uuid, .required, .references(PoetTang.schema, "id"))
            .field("tag_id", .uuid, .required, .references(PoetTag.schema, "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettang+tags").delete()
    }
}
