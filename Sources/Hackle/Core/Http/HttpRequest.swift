//
// Created by yong on 2020/12/14.
//

import Foundation

struct HttpRequest {

    let url: URL
    let method: String
    let headers: [String: String]?
    let body: Data?

    init(url: URL, method: String, headers: [String: String]?, body: Data?) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }

    static func get(url: URL, headers: [String: String]? = nil) -> HttpRequest {
        HttpRequest(url: url, method: "get", headers: headers, body: nil)
    }

    static func post(url: URL, body: Data) -> HttpRequest {
        HttpRequest(url: url, method: "post", headers: ["Content-Type": "application/json"], body: body)
    }
}
