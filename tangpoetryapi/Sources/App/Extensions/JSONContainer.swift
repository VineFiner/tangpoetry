//
//  JSONContainer.swift
//  App
//
//  Created by Finer  Vine on 2020/5/12.
//

import Foundation
import Vapor

/// 封装成 struct 优于 enum.
//struct ResponseStatus: Content {
//    var code: UInt
//    var desc: String
//
//    static var ok = ResponseStatus(code: 0, desc: "请求成功")
//    /// 接口失败
//    static var userExist = ResponseStatus(code: 20, desc: "用户已经存在")
//    static var userNotExist = ResponseStatus(code: 21, desc: "用户不存在")
//    static var passwordError = ResponseStatus(code: 22, desc: "密码错误")
//    static var emailNotExist = ResponseStatus(code: 23, desc: "邮箱不存在")
//    static var modelNotExist = ResponseStatus(code: 25, desc: "对象不存在")
//    static var modelExisted = ResponseStatus(code: 26, desc: "对象已存在")
//    static var authFail = ResponseStatus(code: 27, desc: "认证失败")
//    static var codeFail = ResponseStatus(code: 28, desc: "验证码错误")
//    static var resonNotExist = ResponseStatus(code: 29, desc: "不存在reason")
//    static var base64DecodeError = ResponseStatus(code: 30, desc: "base64 decode 失败")
//    static var custom = ResponseStatus(code: 31, desc: "出错了")
//    static var refreshTokenNotExist = ResponseStatus(code: 32, desc: "refreshToken 不存在")
//
//
//    // 用于修改
//    mutating func message(_ str: String) {
//        self.desc = str
//    }
//}

enum ResponseStatus: Int, Content {
    case ok = 0
    case error = 1
    case missesPara = 3
    case unknown = 10
    
    var desc : String {
        switch self {
        case .ok:
            return "请求成功"
        case .error:
            return "请求失败"
        case .missesPara:
            return "缺少参数"
        case .unknown:
            return "未知失败"
        }
        
    }
}
struct Empty: Content {
    
}

struct JSONContainer<D: Content>: Content {
    private var status: ResponseStatus
    private var message: String
    private var data: D?
    
    /// 这里是成功的空数据
    static var successEmpty: JSONContainer<Empty> {
        return JSONContainer<Empty>()
    }
    
    init(data:D? = nil) {
        self.status = .ok
        self.message = self.status.desc
        self.data = data
    }
    
    init(data: D) {
        self.status = .ok
        self.message = status.desc
        self.data = data
    }
    
    init(status: ResponseStatus = .ok, message: String? = nil, data:D? = nil) {
        self.status = status
        self.message = message ?? status.desc
        self.data = data
    }
}

extension EventLoopFuture where Value == Void {
    func makeJson(on request: Request) -> EventLoopFuture<Response> {
        return self.map { data in
            return JSONContainer<Empty>.successEmpty
        }.encodeResponse(for: request)
    }
}

extension EventLoopFuture where Value: Content {
    func makeJson(on request: Request) -> EventLoopFuture<Response> {
        return self.map { data in
            return JSONContainer(data: data)
        }.encodeResponse(for: request)
    }
}

extension Request {
    // void json
    func makeJson() -> EventLoopFuture<Response> {
        return JSONContainer<Empty>(data: nil).encodeResponse(for: self)
    }
}

