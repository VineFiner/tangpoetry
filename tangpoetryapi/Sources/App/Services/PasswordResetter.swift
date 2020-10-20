import Vapor
import Queues
import Fluent

struct PasswordResetter {
    let queue: Queue
    let repository: PasswordTokenRepository
    let eventLoop: EventLoop
    let config: AppConfig
    let generator: RandomGenerator
    let database: Database
    
    func codeReset(for user: User) -> EventLoopFuture<Void> {
        do {
            /// 是否超过限制
            let oldToken = try PasswordToken.query(on: database)
                .filter(\.$user.$id == user.requireID())
                .all()
            return oldToken.flatMapThrowing { (tokens) -> (PasswordToken, EmailJob.Payload) in
                // 返回错误
                if tokens.count > 10 {
                    throw AuthenticationError.emailSendTooMuch
                }
                // 返回 token
                let token = self.generator.generate(bits: 32)
                let resetPasswordToken = try PasswordToken(userID: user.requireID(), token: SHA256.hash(token))
                let url = self.codeURL(token: token)
                let payload = EmailJob.Payload.init(ResetPasswordEmail(resetURL: url), to: user.email)
                return (resetPasswordToken, payload)
            }.flatMap { (resetPasswordToken, payload) -> EventLoopFuture<Void> in
                return self.repository.create(resetPasswordToken).flatMap {
                    return self.queue.dispatch(EmailJob.self, payload)
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
    private func codeURL(token: String) -> String {
        """
        邮箱验证码：\(token)
        """
    }
    /*
     /// Sends a email to the user with a reset-password URL
     func reset(for user: User) -> EventLoopFuture<Void> {
     do {
     let token = generator.generate(bits: 256)
     let resetPasswordToken = try PasswordToken(userID: user.requireID(), token: SHA256.hash(token))
     let url = resetURL(for: token)
     let payload = EmailJob.Payload.init(ResetPasswordEmail(resetURL: url), to: user.email)
     return repository.create(resetPasswordToken).flatMap {
     return self.queue.dispatch(EmailJob.self, payload)
     }
     } catch {
     return eventLoop.makeFailedFuture(error)
     }
     }
     
     private func resetURL(for token: String) -> String {
     "\(config.frontendURL)/auth/reset-password/verify?token=\(token)"
     }
     */
}

extension Request {
    var passwordResetter: PasswordResetter {
        .init(queue: self.queue, repository: self.passwordTokens, eventLoop: self.eventLoop, config: self.application.config, generator: self.application.random, database: self.application.db)
    }
}
