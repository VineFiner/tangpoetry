//
//  UserRoleMiddleware.swift
//  App
//
//  Created by Finer  Vine on 2020/7/20.
//

import Foundation
import Vapor

struct UserRoleMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        if let user = request.auth.get(User.self), user.isFreeze {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "账号已冻结"))
        }
        return next.respond(to: request)
    }
}
