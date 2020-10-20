//
//  SearchController.swift
//  App
//
//  Created by Finer  Vine on 2020/10/20.
//

import Fluent
import Vapor

struct SearchController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let search = routes.grouped("api", "search")
        search.get("info", use: queryInfo(req:))
    }
    
    // 查询 http://127.0.0.1:8080/api/search/info?key=将军行
    func queryInfo(req: Request) throws -> EventLoopFuture<Response> {
        guard let poetryKey = req.query[String.self, at: "key"], !poetryKey.isEmpty else {
            throw Abort(.notFound, reason: "No poetry matched the provided title")
        }
        
        if let poetryType = req.query[String.self, at: "type"], !poetryType.isEmpty {
            // ~~ 模糊匹配。
            let result = PoetTang.query(on: req.db)
                .group(.or) { query in
                    query.filter(\.$title ~~ poetryKey)
                        .filter(\.$content ~~ poetryKey)
            }
            .range(0..<20)
            .all()
            .makeJson(on: req)
            return result
        } else {
            // ~~ 模糊匹配。
            let result = PoetTang.query(on: req.db)
                .group(.or) { query in
                    query.filter(\.$title ~~ poetryKey)
                        .filter(\.$content ~~ poetryKey)
            }
            .range(0..<20)
            .all()
            .makeJson(on: req)
            return result
        }
    }
}
