//
//  CreateTag.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Foundation
import Fluent

struct CreatePoetTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettags")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("poettags").delete()
    }
}

final class PoetTagSeed: Migration {
    
    public init() { }
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            "唐诗", "宋词"
        ].map {
            PoetTag(name: $0)
                .create(on: database)
        }, on: database.eventLoop)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        PoetTag.query(on: database).delete()
    }
}
