//
//  CreatePoetTangAuthor.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Foundation
import Fluent

struct CreateCreatePoetTangAuthor: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettangauthors")
            .id()
            .field("name", .string, .required)
            .field("desc", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettangauthors").delete()
    }
}
