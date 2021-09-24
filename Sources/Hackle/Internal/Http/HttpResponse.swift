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
