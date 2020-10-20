//
//  UserController.swift
//  App
//
//  Created by Finer  Vine on 2020/7/19.
//

import Vapor
import Fluent

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let users = routes.versioned().grouped("users")
        // 登录
        users.post("login", use: login)
        // 注册
        users.post("register", use: register(_:))
        // 发送验证码
        users.post("email-verification", use: sendEmailVerification(_:))
        
        /// 重置密码 验证码
        users.group("reset-password") { resetPasswordRoutes in
            /// 发送带有令牌的重置密码电子邮件
            resetPasswordRoutes.post("", use: resetPassword)
            
            /// 验证给定的重置密码令牌, 基本无用
//            resetPasswordRoutes.get("verify", use: verifyResetPasswordToken)
        }
        /// 前端页面，找回密码
        users.post("recover", use: recoverAccount)
        
        /// 为用户提供新的访问令牌和刷新令牌
        users.post("accessToken", use: refreshAccessToken)
        
        // Authentication required
        users.group(UserToken.authenticator()) { authenticated in
            authenticated.get("me", use: getCurrentUser)
            // 注销登录
            authenticated.get("logout", use: logout)
        }
        
        // Authentication required
        users.group(UserToken.authenticator()) { builder in
            builder.on(.POST, "uploadUserHead", body: .collect(maxSize: "1mb"), use: updateUserHead)
        }
    }
    // 登录
    func login(_ req: Request) throws -> EventLoopFuture<Response> {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        return req.users
            .find(email: loginRequest.email)
            .unwrap(or: AuthenticationError.invalidEmailOrPassword)
            // 密码未认证
            .guard({ $0.isEmailVerified }, else: AuthenticationError.emailIsNotVerified)
            // 账号已冻结
            .guard({ !$0.isFreeze }, else: AuthenticationError.accountIsFreeze)
            .flatMap { user -> EventLoopFuture<User> in
                return req.password
                    .async
                    .verify(loginRequest.password, created: user.passwordHash)
                    .guard({ $0 == true }, else: AuthenticationError.invalidEmailOrPassword)
                    .transform(to: user)
        }
        .flatMap { user -> EventLoopFuture<User> in
            // 删除旧token
            do {
                let deleteRefreshToken = try RefreshToken.query(on: req.db)
                    .filter(\.$user.$id == user.requireID())
                    .delete()
                let deleteAccessToken = try req.accessTokens.delete(for: user.requireID())
                
                return deleteRefreshToken.and(deleteAccessToken).transform(to: user)
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
        .flatMap { user in
            // 生成新 token
            do {
                let refreshValue = [UInt8].random(count: 16).base64
                let refreshToken = try RefreshToken(token: SHA256.hash(refreshValue), userID: user.requireID())
                
                let accessToken = try user.generateToken()
                
                //保存
                let saveRefresh = refreshToken.create(on: req.db)
                let saveAccess = accessToken.create(on: req.db)
                
                return saveRefresh.and(saveAccess).flatMapThrowing { (void) -> LoginResponse in
                    return LoginResponse(user: UserDTO(from: user),accessToken: accessToken.value, expiresIn: accessToken.expiresAt.timeIntervalSince1970,refreshToken: refreshValue)
                }.makeJson(on: req)
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
    }
    // 注册
    func register(_ req: Request) throws -> EventLoopFuture<Response> {
        try RegisterRequest.validate(content: req)
        let registerRequest = try req.content.decode(RegisterRequest.self)
        guard registerRequest.password == registerRequest.confirmPassword else {
            throw AuthenticationError.passwordsDontMatch
        }
        let hashedToken = SHA256.hash(registerRequest.verify)
        
        return req.emailTokens
            .find(token: hashedToken)
            .unwrap(or: AuthenticationError.emailTokenNotFound)
            .flatMap { req.emailTokens.delete($0).transform(to: $0) }
            .guard({ $0.expiresAt > Date() },
                   else: AuthenticationError.emailTokenHasExpired)
            .flatMap { (emailToken) -> EventLoopFuture<Void> in
                return req.password
                    .async
                    .hash(registerRequest.password)
                    .flatMap { (digest) -> EventLoopFuture<Void> in
                        User.query(on: req.db)
                            .filter(\.$id == emailToken.$user.id)
                            .set(\.$isEmailVerified, to: true)
                            .set(\.$fullName, to: registerRequest.username)
                            .set(\.$passwordHash, to: digest)
                            .update()
                }
        }.makeJson(on: req)
    }
    
    /* 验证并重设密码
     curl -i -X POST "http://127.0.0.1:8080/api/users/recover/" \
     -H "Content-Type: application/json" \
     -d '{"password": "thisispassword", "confirmPassword": "thisispassword", "token": ""}'
     */
    private func recoverAccount(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try RecoverAccountRequest.validate(content: req)
        let content = try req.content.decode(RecoverAccountRequest.self)
        
        let hashedToken = SHA256.hash(content.token)
        
        return req.passwordTokens
            .find(token: hashedToken)
            .unwrap(or: AuthenticationError.invalidPasswordToken)
            .flatMap { passwordToken -> EventLoopFuture<Void> in
                guard passwordToken.expiresAt > Date() else {
                    return req.passwordTokens
                        .delete(passwordToken)
                        .transform(to: req.eventLoop
                            .makeFailedFuture(AuthenticationError.passwordTokenHasExpired)
                    )
                }
                
                return req.password
                    .async
                    .hash(content.password)
                    .flatMap { digest in
                        req.users.set(\.$passwordHash, to: digest, for: passwordToken.$user.id)
                }
                .flatMap { req.passwordTokens.delete(for: passwordToken.$user.id) }
        }
        .transform(to: .noContent)
    }
    /// 注销登录
    private func logout(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let user = req.auth.get(User.self) else {
            return JSONContainer<Empty>.successEmpty.encodeResponse(for: req)
        }
        // 删除token
        let deleteRefreshToken = try RefreshToken.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
        let deleteAccessToken = try req.accessTokens.delete(for: user.requireID())
        
        return deleteRefreshToken.and(deleteAccessToken).transform(to: JSONContainer<Empty>.successEmpty.encodeResponse(for: req))
    }
    /*
     curl -i -X POST "http://127.0.0.1:8080/api/auth/accessToken" \
     -H "Content-Type: application/json" \
     -d '{"refreshToken": "MpUy0vYCsPqsyO7EoR2JzQ=="}'
     */
    private func refreshAccessToken(_ req: Request) throws -> EventLoopFuture<AccessTokenResponse> {
        let accessTokenRequest = try req.content.decode(AccessTokenRequest.self)
        let hashedRefreshToken = SHA256.hash(accessTokenRequest.refreshToken)
        
        return req.refreshTokens
            .find(token: hashedRefreshToken)
            .unwrap(or: AuthenticationError.refreshTokenOrUserNotFound)
            .flatMap { refresh -> EventLoopFuture<RefreshToken> in
                // 删除旧token
                let deleteRefreshToken = req.refreshTokens.delete(refresh)
                let deleteAccessToken = req.accessTokens.delete(for: refresh.$user.id)
                return deleteRefreshToken.and(deleteAccessToken).transform(to: refresh)
            }
            .guard({ $0.expiresAt > Date() }, else: AuthenticationError.refreshTokenHasExpired)
            .flatMap { req.users.find(id: $0.$user.id) }
            .unwrap(or: AuthenticationError.refreshTokenOrUserNotFound)
            .flatMap { user -> EventLoopFuture<(String, UserToken)> in
                do {
                    // 这里是刷新Token
                    let tokenValue = [UInt8].random(count: 16).base64
                    let refreshToken = try RefreshToken(token: SHA256.hash(tokenValue), userID: user.requireID())
                    
                    // 生成新的 token
                    let accessToken = try user.generateToken()
                    
                    //保存
                    let saveRefresh = refreshToken.create(on: req.db)
                    let saveAccess = accessToken.create(on: req.db)
                    return saveRefresh.and(saveAccess).transform(to: (tokenValue, accessToken))
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
        }
        .map { AccessTokenResponse(refreshToken: $0, expiresIn: $1.expiresAt.timeIntervalSince1970, accessToken: $1.value) }
    }
}
// 获取个人信息
extension UserController {
    /*
     curl -H "Authorization: Bearer PPMla5rf9aTlnK1Uu8zwIQ==" \
     -X GET "http://127.0.0.1:8080/api/auth/me"
     */
    private func getCurrentUser(_ req: Request) throws -> EventLoopFuture<Response> {
        let user = try req.auth.require(User.self)
        return req.eventLoop.future(UserDTO(from: user)).makeJson(on: req)
    }
}
// 验证 Email
extension UserController {
    struct UserVerificationEmail: Decodable, Validatable {
        let email: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("email", as: String.self, is: .email)
        }
    }
    func sendEmailVerification(_ req: Request) throws -> EventLoopFuture<Response> {
        try UserVerificationEmail.validate(content: req)
        let emailRequest = try req.content.decode(UserVerificationEmail.self)
        
        return req.users
            .find(email: emailRequest.email)
            .flatMap { (user) -> EventLoopFuture<Response> in
                // 有用户，且没有认证，继续认证
                if let user = user, !user.isEmailVerified {
                    return req.emailVerifier
                        .codeVerify(for: user)
                        .makeJson(on: req)
                } else {
                    let user = User(fullName: "", email: emailRequest.email, passwordHash: "")
                    return user.create(on: req.db).flatMapErrorThrowing{ (error) in
                        if let dbError = error as? DatabaseError, dbError.isConstraintFailure {
                            throw AuthenticationError.emailAlreadyExists
                        }
                        throw error
                    }.flatMap({ (void) -> EventLoopFuture<Void> in
                        // 这里是邮箱验证
                        return req.emailVerifier.codeVerify(for: user)
                    }).makeJson(on: req)
                }
        }
    }
    /* 重设密码, 验证码
     curl -i -X POST "http://127.0.0.1:8080/api/auth/reset-password" \
     -H "Content-Type: application/json" \
     -d '{"email": "test@vapor.codes"}'
     */
    private func resetPassword(_ req: Request) throws -> EventLoopFuture<Response> {
        let resetPasswordRequest = try req.content.decode(ResetPasswordRequest.self)
        
        return req.users
            .find(email: resetPasswordRequest.email)
            .unwrap(or: AuthenticationError.userNotFound)
            .flatMap { user in
                // 发送重设密码 email
                return req.passwordResetter
                          .codeReset(for: user)
        }.makeJson(on: req)
    }
}
extension UserController {
    struct Input: Decodable {
        // 文件
        var image: File?
    }
    /// http://127.0.0.1:8080/api/users
    func updateUserHead(_ req: Request) throws -> EventLoopFuture<Response> {
        // 获取用户
        let user = try req.auth.require(User.self)
        
        let patch = try req.content.decode(Input.self)
        
        if let image = patch.image,
            let data = image.data.getData(at: 0, length: image.data.readableBytes),
            !data.isEmpty {
            // 图片路径
            let key = req.application.directory.publicDirectory + "/uploads/" + image.filename
            // 这里是图片文件
            return req
                .fileio
                .writeFile(.init(data: data), at: "\(key)")
                .flatMap { () -> EventLoopFuture<UserDTO> in
                    user.imageUrl = image.filename
                    return user.save(on: req.db).transform(to: UserDTO(from: user))
            }.makeJson(on: req)
        } else {
            return JSONContainer<Empty>.successEmpty.encodeResponse(for: req)
        }
    }
}
