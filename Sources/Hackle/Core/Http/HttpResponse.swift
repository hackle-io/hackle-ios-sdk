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

    var statusCode: Int? {
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            return nil
        }
        return urlResponse.statusCode
    }

    var isSuccessful: Bool {
        guard let urlResponse = urlResponse as? HTTPURLResponse, error == nil else {
            return false
        }
        return urlResponse.isSuccessful
    }

    func isStatusCode(_ code: Int) -> Bool {
        guard let urlResponse = urlResponse as? HTTPURLResponse, error == nil else {
            return false
        }
        return urlResponse.statusCode == code
    }

    var isNoContent: Bool {
        isStatusCode(204)
    }

    var isNotModified: Bool {
        isStatusCode(304)
    }

    func header(_ header: HttpHeader) -> String? {
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            return nil
        }
        return urlResponse.header(header)
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
