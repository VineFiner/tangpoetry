//
//  PoetAuthorController.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//

import Fluent
import Vapor

struct PoetAuthorController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let poets = routes.grouped("poets", "author")
        
        poets.get(use: index)
        poets.get("index", use: indexPage(req:))
        poets.get("search", use: queryTitle(req:))
        
        poets.post(use: create)
        poets.group(":authorID") { author in
            author.get(use: getSingle)
            author.delete(use: delete)
            author.get("poets", use: getSingleWithPoet)
        }
    }
    /// http://127.0.0.1:8080/poets/author
    func index(req: Request) throws -> EventLoopFuture<[PoetTangAuthor]> {
        return PoetTangAuthor
            .query(on: req.db)
            .range(0..<20)
            .all()
    }
    // 分页获取 http://127.0.0.1:8080/poets/author/index?page=1&per=10
    func indexPage(req: Request) throws -> EventLoopFuture<Page<PoetTangAuthor>> {
        
        struct PageInfo: Codable {
            var page: Int
            var per: Int
        }
        var pageInfo = try req.query.decode(PageInfo.self)
        print(pageInfo)
        // 这里限定显示30个
        if pageInfo.per > 30 {
            pageInfo.per = 30
        }
        // 这里是分页
        let page: EventLoopFuture<Page<PoetTangAuthor>> = PoetTangAuthor.query(on: req.db)
            .paginate(PageRequest(page: pageInfo.page, per: pageInfo.per))
        // 这里做 额外处理
        return page
    }
    // 查询 http://127.0.0.1:8080/poets/author/search?title=将军行
    func queryTitle(req: Request) throws -> EventLoopFuture<[PoetTangAuthor]> {
        guard let authorName = req.query[String.self, at: "title"] else {
            throw Abort(.notFound, reason: "No poetry matched the provided title")
        }
        // ~~ 模糊匹配。
        let result = PoetTangAuthor.query(on: req.db)
            .group(.or) { query in
                query.filter(\.$name ~~ authorName)
        }
        .range(0..<20)
        .all()
        return result
    }
    
    func create(req: Request) throws -> EventLoopFuture<PoetTangAuthor> {
        let poet = try req.content.decode(PoetTangAuthor.self)
        return poet.save(on: req.db).map { poet }
    }
    
    /// http://127.0.0.1:8080/poets/2FB8EB31-0F2F-42EB-BE9E-EE0CB66906EF
    func getSingle(req: Request) throws -> EventLoopFuture<PoetTangAuthor> {
        guard let authorID = req.parameters.get("authorID", as: UUID.self) else {
            throw Abort(.notFound, reason: "No poetry matched the provided id")
        }
        print("id:\(authorID)")
        return PoetTangAuthor.find(authorID, on: req.db).unwrap(or: Abort(.notFound))
    }
    /// http://127.0.0.1:8080/poets/author/3D258ACB-816F-4557-863E-0F37C441B3BC
    func getSingleWithPoet(req: Request) throws -> EventLoopFuture<PoetTangAuthor> {
        guard let authorID = req.parameters.get("authorID", as: UUID.self) else {
            throw Abort(.notFound, reason: "No poetry matched the provided id")
        }
        print("id:\(authorID)")
        return PoetTangAuthor
            .query(on: req.db)
            .filter(\.$id == authorID)
            .with(\.$poets)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    /// http://127.0.0.1:8080/poets/2FB8EB31-0F2F-42EB-BE9E-EE0CB66906EF
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return PoetTang.find(req.parameters.get("poetID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
