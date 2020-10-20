//
//  LyricistController.swift
//  App
//
//  Created by Finer  Vine on 2020/10/20.
//

// 这里是 词
import Fluent
import Vapor

struct LyricistController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let lyricists = routes.grouped("api", "lyricists")
        
        lyricists.get(use: index)
        lyricists.get("index", use: indexPage(req:))
        lyricists.get("search", use: queryTitle(req:))
        
        lyricists.post(use: create)
        lyricists.group(":ID") { lyricist in
            lyricist.get(use: getSingle)
            lyricist.post("update", use: getSingleUpdate)
            lyricist.delete(use: delete)
        }
    }
    /// http://127.0.0.1:8080/api/lyricists
    func index(req: Request) throws -> EventLoopFuture<Response> {
        return PoetTang
            .query(on: req.db)
            .range(0..<20)
            .all()
            .makeJson(on: req)
    }
    // 分页获取 http://127.0.0.1:8080/api/lyricists/index?page=1&per=10
    func indexPage(req: Request) throws -> EventLoopFuture<Page<PublicPoetTang>> {
        
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
        let page: EventLoopFuture<Page<PoetTang>> = PoetTang.query(on: req.db)
            .paginate(PageRequest(page: pageInfo.page, per: pageInfo.per))
        // 这里做 额外处理
        return page.flatMapThrowing { (page: Page<PoetTang>) -> Page<PublicPoetTang> in
            let simple: Page<PublicPoetTang> = try page.map { (tang) -> PublicPoetTang in
                return try PublicPoetTang(id: tang.requireID(), title: tang.title, author: tang.authorName, content: tang.content.split(separator: "\n").map {"\($0)"})
            }
            return simple
        }
    }
    // 查询 http://127.0.0.1:8080/api/lyricists/search?title=将军行
    func queryTitle(req: Request) throws -> EventLoopFuture<Response> {
        guard let poetryTitle = req.query[String.self, at: "title"], !poetryTitle.isEmpty else {
            throw Abort(.notFound, reason: "No poetry matched the provided title")
        }
        // ~~ 模糊匹配。
        let result = PoetTang.query(on: req.db)
            .group(.or) { query in
                query.filter(\.$title ~~ poetryTitle)
                    .filter(\.$content ~~ poetryTitle)
        }
        .range(0..<20)
        .all()
        .makeJson(on: req)
        return result
    }
    
    func create(req: Request) throws -> EventLoopFuture<PoetTang> {
        let poet = try req.content.decode(PoetTang.self)
        return poet.save(on: req.db).map { poet }
    }
    
    /// http://127.0.0.1:8080/lyricists/2FB8EB31-0F2F-42EB-BE9E-EE0CB66906EF
    func getSingle(req: Request) throws -> EventLoopFuture<Response> {
        guard let poetryID = req.parameters.get("poetID", as: UUID.self) else {
            throw Abort(.notFound, reason: "No poetry matched the provided id")
        }
        print("id:\(poetryID)")
        return PoetTang.find(poetryID, on: req.db).unwrap(or: Abort(.notFound)).makeJson(on: req)
    }
    /// http://127.0.0.1:8080/lyricists/2FB8EB31-0F2F-42EB-BE9E-EE0CB66906EF
    func getSingleUpdate(req: Request) throws -> EventLoopFuture<PoetTang> {
        guard let poetryID = req.parameters.get("poetID", as: UUID.self) else {
            throw Abort(.notFound, reason: "No poetry matched the provided id")
        }
        print("id:\(poetryID)")
        let patch = try req.content.decode(PublicPoetTang.self)
        
        return PoetTang
            .find(poetryID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { (tang) -> EventLoopFuture<PoetTang> in
                tang.content = patch.author
                return tang.save(on: req.db).transform(to: tang)
        }
    }
    
    /// http://127.0.0.1:8080/lyricists/2FB8EB31-0F2F-42EB-BE9E-EE0CB66906EF
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return PoetTang.find(req.parameters.get("poetID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
