import Vapor

struct RecoverAccountRequest: Content {
    let email: String
    let password: String
    let token: String
}

extension RecoverAccountRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("token", as: String.self, is: !.empty)
    }
}
