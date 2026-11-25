import Foundation

protocol DevToolsAPI {
    func addExperimentOverrides(experimentKey: Experiment.Key, request: OverrideRequest)
    func removeExperimentOverrides(experimentKey: Experiment.Key, request: OverrideRequest)
    func removeAllExperimentOverrides(request: OverrideRequest)
    func addFeatureFlagOverrides(experimentKey: Experiment.Key, request: OverrideRequest)
    func removeFeatureFlagOverrides(experimentKey: Experiment.Key, request: OverrideRequest)
    func removeAllFeatureFlagOverrides(request: OverrideRequest)
}

class DefaultDevToolsAPI: DevToolsAPI {
    private let sdk: Sdk
    private let url: URL
    private let httpClient: HttpClient

    init(sdk: Sdk, url: URL, httpClient: HttpClient) {
        self.sdk = sdk
        self.url = url
        self.httpClient = httpClient
    }

    func addExperimentOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        guard let body = request.toData() else {
            return
        }
        execute(method: "PATCH", path: "/v1/experiments/\(experimentKey)/overrides", body: body)
    }

    func removeExperimentOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        guard let body = request.toData() else {
            return
        }
        execute(method: "DELETE", path: "/v1/experiments/\(experimentKey)/overrides", body: body)
    }

    func removeAllExperimentOverrides(request: OverrideRequest) {
        guard let body = request.toData() else {
            return
        }
        execute(method: "DELETE", path: "/v1/experiments/overrides", body: body)
    }

    func addFeatureFlagOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        guard let body = request.toData() else {
            return
        }
        execute(method: "PATCH", path: "/v1/feature-flags/\(experimentKey)/overrides", body: body)
    }

    func removeFeatureFlagOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        guard let body = request.toData() else {
            return
        }
        execute(method: "DELETE", path: "/v1/feature-flags/\(experimentKey)/overrides", body: body)
    }

    func removeAllFeatureFlagOverrides(request: OverrideRequest) {
        guard let body = request.toData() else {
            return
        }
        execute(method: "DELETE", path: "/v1/feature-flags/overrides", body: body)
    }

    private func execute(method: String, path: String, body: Data) {
        let request = HttpRequest(
            url: url.appendingPathComponent(path),
            method: method,
            headers: [
                "X-HACKLE-API-KEY": sdk.key,
                "Content-Type": "application/json"
            ],
            body: body
        )
        httpClient.execute(request: request) { response in
            if !response.isSuccessful {
                let result = response.statusCode?.description ?? response.error?.localizedDescription ?? "Internal Error"
                Log.error("[\(result)] \(method) \(path)")
            }
        }
    }
}

struct OverrideRequest {
    var user: User
    var variation: Variation?
}

private extension OverrideRequest {
    func toData() -> Data? {
        var dict: [String: Any] = [
            "user": user.toDto(),
        ]
        if let variation = variation {
            dict["variation"] = variation.key
        }
        return Json.serialize(dict)
    }
}
