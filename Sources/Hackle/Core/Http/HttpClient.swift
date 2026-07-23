//
// Created by yong on 2020/12/11.
//

import Foundation

protocol HttpClient {
    func execute(request: HttpRequest, completion: @escaping @Sendable (HttpResponse) -> Void)
    func execute(request: HttpRequest, timeout: TimeInterval, completion: @escaping @Sendable (HttpResponse) -> Void)
}

extension HttpClient {
    /// 콜백 기반 execute를 async로 감싸는 유일한 continuation 브리지.
    ///
    /// - Important: conformer는 completion을 **정확히 1회** 호출해야 한다. 0회 호출 시
    ///   continuation이 resume되지 않아 호출 Task가 영구 정지한다. `DefaultHttpClient`는
    ///   URLSession dataTask 계약으로 이를 보장하며, 테스트 더블(`MockHttpClient`)은 등록한
    ///   answer가 반드시 completion을 1회 호출해야 한다.
    func execute(request: HttpRequest, timeout: TimeInterval? = nil) async -> HttpResponse {
        await withCheckedContinuation { continuation in
            let completion: @Sendable (HttpResponse) -> Void = { response in
                continuation.resume(returning: response)
            }
            if let timeout {
                execute(request: request, timeout: timeout, completion: completion)
            } else {
                execute(request: request, completion: completion)
            }
        }
    }
}

class DefaultHttpClient: HttpClient {

    private let sdk: Sdk
    private let session: URLSession

    init(sdk: Sdk) {
        self.sdk = sdk
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
    }

    func execute(request: HttpRequest, completion: @escaping @Sendable (HttpResponse) -> Void) {
        execute(request: request, timeout: session.configuration.timeoutIntervalForRequest, completion: completion)
    }

    func execute(request: HttpRequest, timeout: TimeInterval, completion: @escaping @Sendable (HttpResponse) -> Void) {
        var req = URLRequest(url: request.url)
        req.httpMethod = request.method
        req.httpBody = request.body
        req.timeoutInterval = timeout
        request.headers?.forEach { k, v in
            req.setValue(v, forHTTPHeaderField: k)
        }
        req.setValue(sdk.key, forHTTPHeaderField: "X-HACKLE-SDK-KEY")
        req.setValue(sdk.name, forHTTPHeaderField: "X-HACKLE-SDK-NAME")
        req.setValue(sdk.version, forHTTPHeaderField: "X-HACKLE-SDK-VERSION")
        req.setValue(String(Date().epochMillis), forHTTPHeaderField: "X-HACKLE-SDK-TIME")

        Log.debug("--> \(request.method) \(request.url)")
        let task = session.dataTask(with: req) { data, response, error in
            let httpResponse = HttpResponse(request: request, data: data, urlResponse: response, error: error)
            Log.debug("<-- \(request.method) \(request.url) status: \(httpResponse.statusCode ?? -1)\(error.map { ", error: \($0)" } ?? "")")
            completion(httpResponse)
        }

        task.resume()
    }
}
