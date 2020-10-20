//
//  AdminController.swift
//  App
//
//  Created by Finer  Vine on 2020/7/14.
//

import Foundation
import Vapor
import Fluent

struct AdminController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let admin = routes.versioned().grouped("admin")
        
        // 单一身份认证器，并不会阻止路由
        admin.grouped(UserToken.authenticator())
         // .grouped(User.redirectMiddleware(path: ""))
            // 使用 guard 来保证用户已经认证
            .group(User.guardMiddleware()) { (admin) in
            admin.get(use: index(_:))
            admin.get("usersList", use: userList)
            admin.post("updateFreeze", use: udpateFreeze)
            admin.post("deleteUser", use: deleteUser)
        }
    }
    
    func index(_ req: Request) throws -> EventLoopFuture<Response> {
        
        let user = try req.auth.require(User.self)
        
        // 这里不再抛出错误
        //        let user = req.auth.get(User.self)
        if user.isAdmin {
            return JSONContainer<Empty>.successEmpty.encodeResponse(for: req)
        } else {
            throw AuthenticationError.invalidEmailOrPassword
        }
    }
    func userList(_ req: Request) throws -> EventLoopFuture<Response> {
        let users = User.query(on: req.db).all().mapEach { UserDTO(from: $0) }
        return users.makeJson(on: req)
    }
    
    struct PatchFreeze: Decodable {
        let email: String
        let isFreeze: Bool
    }
    /// 通过 email， 进行更新
    func udpateFreeze(_ req: Request) throws -> EventLoopFuture<Response> {
        let patch = try req.content.decode(PatchFreeze.self)
        return User.query(on: req.db).filter(\.$email == patch.email)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { (user) -> EventLoopFuture<UserDTO> in
                //                let email = patch.email
                let isFreeze = patch.isFreeze
                user.isFreeze = isFreeze
                return user.save(on: req.db).transform(to: UserDTO(from: user))
        }.makeJson(on: req)
    }
    
    struct DeleteUser: Decodable {
        let email: String
        /// 是否强制删除
        let isForce: Bool?
    }
    /// 通过 email，进行删除
    func deleteUser(_ req: Request) throws -> EventLoopFuture<Response> {
        let delete = try req.content.decode(DeleteUser.self)
        return User.query(on: req.db).filter(\.$email == delete.email)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { (user) -> EventLoopFuture<Void> in
                if let force = delete.isForce {
                    return user.delete(force: force, on: req.db)
                } else {
                    return user.delete(on: req.db)
                }
        }.makeJson(on: req)
    }
}
