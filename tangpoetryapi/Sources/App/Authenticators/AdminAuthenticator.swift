//
//  AdminAuthenticator.swift
//  App
//
//  Created by Finer  Vine on 2020/7/20.
//
/*
import Foundation
import Vapor
import Fluent
// User 遵从协议，是可验证的
// 这里是验证器
struct AdminAuthenticator: BearerAuthenticator {
    //    typealias User = App.User
    /// 这里是必要实现的方法
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        let db = request.db
        // 查询 token
        return UserToken.query(on: db)
            .filter(\.$value == bearer.token)
            .first()
            .flatMap { (token) -> EventLoopFuture<Void> in
                guard let token = token else {
                    return request.eventLoop.makeSucceededFuture(())
                }
                guard token.isValid else {
                    return token.delete(on: db)
                }
                // 手动登录用户
                request.auth.login(token)
                // 使用 get 方法来获取 关联对象的值
                return token.$user.get(on: db).map { (user) -> () in
                    if user.isAdmin {
                        // 手动登录用户
                        request.auth.login(user)
                    }
                }
        }
    }
}
*/
