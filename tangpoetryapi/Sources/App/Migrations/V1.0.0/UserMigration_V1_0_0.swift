//
//  UserMigration_V1_0_0.swift
//  App
//
//  Created by Finer  Vine on 2020/7/15.
//

import Foundation
import Fluent

struct UserMigration_V1_0_0: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("is_freeze", .bool, .custom("DEFAULT FALSE"))
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .deleteField("is_freeze")
            .update()
    }
}
