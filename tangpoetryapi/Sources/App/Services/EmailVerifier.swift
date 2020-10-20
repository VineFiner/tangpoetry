import Vapor
import Queues
import Fluent

struct EmailVerifier {
    let emailTokenRepository: EmailTokenRepository
    let config: AppConfig
    let queue: Queue
    let eventLoop: EventLoop
    let generator: RandomGenerator
    let database: Database
    // 这里是 验证码 认证
    func codeVerify(for user: User) -> EventLoopFuture<Void> {
        do {
            /// 是否超过限制
            let oldToken = try EmailToken.query(on: database)
                .filter(\.$user.$id == user.requireID())
                .all()
            
            return oldToken.flatMapThrowing { (tokens) -> (EmailToken, EmailJob.Payload) in
                // 返回错误
                if tokens.count > 10 {
                    throw AuthenticationError.emailSendTooMuch
                }
                // 返回 token
                let token = self.generator.generate(bits: 32)
                let emailToken = try EmailToken(userID: user.requireID(), token: SHA256.hash(token))
                let verifyUrl = self.codeUrl(token: token)
                let payload = EmailJob.Payload.init(VerificationEmail(verifyUrl: verifyUrl), to: user.email)
                return (emailToken, payload)
            }.flatMap { (emailToken, payload) -> EventLoopFuture<Void> in
                return self.emailTokenRepository.create(emailToken).flatMap {
                    return self.queue.dispatch(EmailJob.self, payload)
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    private func codeUrl(token: String) -> String {
        """
        邮箱验证码：\(token)
        """
    }
    /*
    func verify(for user: User) -> EventLoopFuture<Void> {
        do {
            /// 是否超过限制
            let oldToken = try EmailToken.query(on: database)
                .filter(\.$user.$id == user.requireID())
                .all()
            
            return oldToken.flatMapThrowing { (tokens) -> (EmailToken, EmailJob.Payload) in
                // 返回错误
                if tokens.count > 10 {
                    throw AuthenticationError.emailSendTooMuch
                }
                // 返回 token
                let token = self.generator.generate(bits: 256)
                let emailToken = try EmailToken(userID: user.requireID(), token: SHA256.hash(token))
                let verifyUrl = self.url(token: token)
                let payload = EmailJob.Payload.init(VerificationEmail(verifyUrl: verifyUrl), to: user.email)
                return (emailToken, payload)
            }.flatMap { (emailToken, payload) -> EventLoopFuture<Void> in
                return self.emailTokenRepository.create(emailToken).flatMap {
                    return self.queue.dispatch(EmailJob.self, payload)
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    private func url(token: String) -> String {
        #"\#(config.apiURL)/api/auth/email-verification?token=\#(token)"#
    }
    */
}

extension Application {
    var emailVerifier: EmailVerifier {
        .init(emailTokenRepository: self.repositories.emailTokens, config: self.config, queue: self.queues.queue, eventLoop: eventLoopGroup.next(), generator: self.random, database: self.db)
    }
}

extension Request {
    var emailVerifier: EmailVerifier {
        .init(emailTokenRepository: self.emailTokens, config: application.config, queue: self.queue, eventLoop: eventLoop, generator: self.application.random, database: self.db)
    }
}
