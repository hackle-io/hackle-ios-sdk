//
// Created by yong on 2020/12/11.
//

import Foundation

protocol HttpClient {
    func execute(request: HttpRequest, completion: @escaping (HttpResponse) -> Void)
}

class DefaultHttpClient: HttpClient {

    private let sdk: Sdk
    private let session: URLSession

    init(sdk: Sdk) {
        self.sdk = sdk
        self.session = URLSession(configuration: URLSessionConfiguration.default)
    }

    func execute(request: HttpRequest, completion: @escaping (HttpResponse) -> Void) {

        var req = URLRequest(url: request.url)
        req.httpMethod = request.method
        req.httpBody = request.body
        request.headers?.forEach { k, v in
            req.setValue(v, forHTTPHeaderField: k)
        }
        req.setValue(sdk.key, forHTTPHeaderField: "X-HACKLE-SDK-KEY")
        req.setValue(sdk.name, forHTTPHeaderField: "X-HACKLE-SDK-NAME")
        req.setValue(sdk.version, forHTTPHeaderField: "X-HACKLE-SDK-VERSION")
        req.setValue(String(Date().epochMillis), forHTTPHeaderField: "X-HACKLE-SDK-TIME")

        let task = session.dataTask(with: req) { data, response, error in
            completion(HttpResponse(request: request, data: data, urlResponse: response, error: error))
        }

        task.resume()
    }
}
