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
        return urlResponse.isSuccessful
    }
    var isNotModified: Bool {
        guard let urlResponse = urlResponse as? HTTPURLResponse, error == nil else {
            return false
        }
        return urlResponse.isNotModified
    }
}

extension HTTPURLResponse {
    var isSuccessful: Bool {
        (200..<300).contains(statusCode)
    }

    var isNotModified: Bool {
        statusCode == 304
    }

    func header(_ header: HttpHeader) -> String? {
        allHeaderFields[header.rawValue] as? String
    }
}
