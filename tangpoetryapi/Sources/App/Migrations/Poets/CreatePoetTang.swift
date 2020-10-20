//
//  CreatePoetTang.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Foundation
import Fluent

struct CreatePoetTang: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettangs")
            .id()
            .field("title", .string, .required)
            .field("author", .string, .required)
            .field("content", .string)
            .field("author_id", .uuid, .references("poettangauthors", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettangs").delete()
    }
}
