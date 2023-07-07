//
// Created by yong on 2020/12/14.
//

import Foundation

struct HttpResponse {
    var request: HttpRequest
    var data: Data?
    var urlResponse: URLResponse?
    var error: Error?
}


extension HttpResponse {
    var isSuccessful: Bool {
        guard let urlResponse = urlResponse as? HTTPURLResponse, error == nil else {
            return false
        }
        return (200..<300).contains(urlResponse.statusCode)
    }
}