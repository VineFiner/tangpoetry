import Vapor

enum AuthenticationError: AppError {
    case passwordsDontMatch
    case emailAlreadyExists
    case invalidEmailOrPassword
    case refreshTokenOrUserNotFound
    case refreshTokenHasExpired
    case userNotFound
    case emailTokenHasExpired
    case emailTokenNotFound
    case emailIsNotVerified
    case emailSendTooMuch
    case invalidPasswordToken
    case passwordTokenHasExpired
    case accountIsFreeze
}

extension AuthenticationError: AbortError {
    var status: HTTPResponseStatus {
        switch self {
        case .passwordsDontMatch:
            return .badRequest
        case .emailAlreadyExists:
            return .badRequest
        case .emailTokenHasExpired:
            return .badRequest
        case .invalidEmailOrPassword:
            return .unauthorized
        case .refreshTokenOrUserNotFound:
            return .notFound
        case .userNotFound:
            return .notFound
        case .emailTokenNotFound:
            return .notFound
        case .refreshTokenHasExpired:
            return .unauthorized
        case .emailIsNotVerified:
            return .unauthorized
        case .emailSendTooMuch:
            return .unauthorized
        case .invalidPasswordToken:
            return .notFound
        case .passwordTokenHasExpired:
            return .unauthorized
        case .accountIsFreeze:
            return .unauthorized
        }
    }
    
    var reason: String {
        switch self {
        case .passwordsDontMatch:
            return "Passwords did not match"
        case .emailAlreadyExists:
            return "A user with that email already exists"
        case .invalidEmailOrPassword:
            return "Email or password was incorrect"
        case .refreshTokenOrUserNotFound:
            return "User or refresh token was not found"
        case .refreshTokenHasExpired:
            return "Refresh token has expired"
        case .userNotFound:
            return "User was not found"
        case .emailTokenNotFound:
            return "Email token not found"
        case .emailTokenHasExpired:
            return "Email token has expired"
        case .emailIsNotVerified:
            return "Email is not verified"
        case .emailSendTooMuch:
            return "email send too much"
        case .invalidPasswordToken:
            return "Invalid reset password token"
        case .passwordTokenHasExpired:
            return "Reset password token has expired"
        case .accountIsFreeze:
            return "账号已冻结"
        }
    }
    
    var identifier: String {
        switch self {
        case .passwordsDontMatch:
            return "passwords_dont_match"
        case .emailAlreadyExists:
            return "email_already_exists"
        case .invalidEmailOrPassword:
            return "invalid_email_or_password"
        case .refreshTokenOrUserNotFound:
            return "refresh_token_or_user_not_found"
        case .refreshTokenHasExpired:
            return "refresh_token_has_expired"
        case .userNotFound:
            return "user_not_found"
        case .emailTokenNotFound:
            return "email_token_not_found"
        case .emailTokenHasExpired:
            return "email_token_has_expired"
        case .emailIsNotVerified:
            return "email_is_not_verified"
        case .emailSendTooMuch:
            return "email_send_too_much"
        case .invalidPasswordToken:
            return "invalid_password_token"
        case .passwordTokenHasExpired:
            return "password_token_has_expired"
        case .accountIsFreeze:
            return "accoutn_is_freeze"
        }
    }
    
    
}
