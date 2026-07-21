import Foundation

protocol InAppMessageHtmlContentResolver {
    func supports(resourceType: InAppMessage.HtmlResourceType) -> Bool
    func resolve(html: InAppMessage.Message.Html, completion: @escaping @Sendable (Result<String, Error>) -> Void)
}

class TextInAppMessageHtmlContentResolver: InAppMessageHtmlContentResolver {
    func supports(resourceType: InAppMessage.HtmlResourceType) -> Bool {
        return resourceType == .text
    }

    func resolve(html: InAppMessage.Message.Html, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        guard let content = html.text else {
            completion(.failure(HackleError.error("Html text is nil")))
            return
        }
        completion(.success(content))
    }
}

// 저장 프로퍼티가 httpClient(let) 하나뿐이라 thread-safe(stateless).
final class PathInAppMessageHtmlContentResolver: InAppMessageHtmlContentResolver, @unchecked Sendable {
    private let httpClient: HttpClient

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    private static let timeout = 5.0

    func supports(resourceType: InAppMessage.HtmlResourceType) -> Bool {
        resourceType == .path
    }

    func resolve(html: InAppMessage.Message.Html, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        guard let path = html.path, let url = URL(string: path) else {
            completion(.failure(HackleError.error("Html path is nil or invalid")))
            return
        }

        let request = HttpRequest.get(url: url)
        let sample = TimerSample.start()
        httpClient.execute(request: request, timeout: Self.timeout) { [weak self] response in
            guard let self = self else {
                completion(.failure(HackleError.error("Failed to resolve html: instance deallocated")))
                return
            }
            ApiCallMetrics.record(operation: "get.iam-html", sample: sample, response: response)
            do {
                let content = try self.handleResponse(response: response)
                completion(.success(content))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func handleResponse(response: HttpResponse) throws -> String {
        if let error = response.error {
            throw error
        }

        guard let statusCode = response.statusCode else {
            throw HackleError.error("Response is empty")
        }

        guard response.isSuccessful else {
            throw HackleError.error("Http status code: \(statusCode)")
        }

        guard let data = response.data else {
            throw HackleError.error("Response body is empty")
        }

        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw HackleError.error("Response body is not UTF-8")
        }

        return htmlString
    }
}

protocol InAppMessageHtmlContentResolverFactory {
    func get(resourceType: InAppMessage.HtmlResourceType) throws -> InAppMessageHtmlContentResolver
}

class DefaultInAppMessageHtmlContentResolverFactory: InAppMessageHtmlContentResolverFactory {
    func get(resourceType: InAppMessage.HtmlResourceType) throws -> any InAppMessageHtmlContentResolver {
        guard let resolver = resolvers.first(where: { it in it.supports(resourceType: resourceType) }) else {
            throw HackleError.error("Not found InAppMessageHtmlContentResolver [\(resourceType)]")
        }
        return resolver
    }

    private let resolvers: [InAppMessageHtmlContentResolver]
    init(resolvers: [InAppMessageHtmlContentResolver]) {
        self.resolvers = resolvers
    }
}
