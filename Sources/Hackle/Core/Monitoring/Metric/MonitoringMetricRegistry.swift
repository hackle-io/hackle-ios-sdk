//
//  Created by yong on 2023/01/18.
//

import Foundation


class MonitoringMetricRegistry: MetricRegistry {

    private let endpoint: URL
    private let eventQueue: DispatchQueue
    private let httpQueue: DispatchQueue
    private let httpClient: HttpClient

    init(monitoringBaseUrl: URL, eventQueue: DispatchQueue, httpQueue: DispatchQueue, httpClient: HttpClient) {
        self.endpoint = monitoringBaseUrl.appendingPathComponent("/metrics")
        self.eventQueue = eventQueue
        self.httpQueue = httpQueue
        self.httpClient = httpClient
        super.init()
    }

    override func createCounter(id: MetricId) -> Counter {
        FlushCounter(id: id)
    }

    override func createTimer(id: MetricId) -> Timer {
        FlushTimer(id: id)
    }

    private func flush() {
        httpQueue.async { [weak self] in
            self?.doFlush()
        }
    }

    private func doFlush() {
        metrics
            .compactMap { metric in
                metric as? FlushMetric
            }
            .map { metric in
                metric.flush()
            }
            .filter(isDispatchTarget)
            .chunked(into: 500)
            .forEach(dispatch)
    }

    // Dispatch only measured metrics
    private func isDispatchTarget(metric: Metric) -> Bool {
        switch metric.id.type {
        case .counter:
            guard let counter = metric as? Counter else {
                return false
            }
            return counter.count() > 0
        case .timer:
            guard let timer = metric as? Timer else {
                return false
            }
            return timer.count() > 0
        }
    }

    private func dispatch(metrics: [Metric]) {
        let batch = batch(metrics: metrics)
        guard let body = Json.serialize(batch) else {
            return
        }

        let request = HttpRequest.post(url: endpoint, body: body)
        httpClient.execute(request: request) { response in
            if !response.isSuccessful {
                Log.error("Failed to flushing metrics")
            }
        }
    }

    private func batch(metrics: [Metric]) -> [String: Any] {
        [
            "metrics": metrics.map(metric)
        ]
    }

    private func metric(metric: Metric) -> [String: Any] {
        [
            "name": metric.id.name,
            "type": metric.id.type.rawValue,
            "tags": metric.id.tags,
            "measurements": metric.measure().associate { measurement in
                (measurement.field.rawValue, measurement.value)
            }
        ]
    }
}

extension MonitoringMetricRegistry: ApplicationLifecycleListener {
    func onForeground(timestamp: Date, isFromBackground: Bool) {
        // nothing to do
    }
    
    func onBackground(timestamp: Date) {
        Log.debug("MonitoringMetricRegistry.onBackground")
        eventQueue.async { [weak self] in
            self?.flush()
        }
    }
}

enum DecisionMetrics {

    static func experiment(sample: TimerSample, key: Int, decision: Decision) {
        let tags = [
            "key": String(key),
            "variation": decision.variation,
            "reason": decision.reason
        ]
        let timer = Metrics.timer(name: "experiment.decision", tags: tags)
        sample.stop(timer: timer)
    }

    static func featureFlag(sample: TimerSample, key: Int, decision: FeatureFlagDecision) {
        let tags = [
            "key": String(key),
            "on": decision.isOn ? "true" : "false",
            "reason": decision.reason
        ]
        let timer = Metrics.timer(name: "feature.flag.decision", tags: tags)
        sample.stop(timer: timer)
    }

    static func remoteConfig(sample: TimerSample, key: String, decision: RemoteConfigDecision) {
        let tags = [
            "key": key,
            "reason": decision.reason
        ]
        let timer = Metrics.timer(name: "remote.config.decision", tags: tags)
        sample.stop(timer: timer)
    }

    static func inAppMessage(sample: TimerSample, key: Int64, decision: InAppMessageDecision) {
        let tags = [
            "key": String(key),
            "show": decision.isShow ? "true" : "false",
            "reason": decision.reason
        ]
        let timer = Metrics.timer(name: "iam.decision", tags: tags)
        sample.stop(timer: timer)
    }
}

enum ApiCallMetrics {
    private static let noneTag = "NONE"
    
    static func record(operation: String, sample: TimerSample, response: HttpResponse) {
        let tags = [
            "operation": operation,
            "success": success(response: response),
            "status": status(response: response),
            "exception": exception(error: response.error)
        ]
        let timer = Metrics.timer(name: "api.call", tags: tags)
        sample.stop(timer: timer)
    }

    private static func success(response: HttpResponse) -> String {
        let success = response.isSuccessful || response.isNotModified
        return success ? "true" : "false"
    }
    
    private static func status(response: HttpResponse) -> String {
        if let statusCode = response.statusCode {
            return String(statusCode)
        }
        return noneTag
    }
    
    private static func exception(error: Error?) -> String {
        guard let error = error else {
            return noneTag
        }
        if let urlError = error as? URLError {
            return urlError.code.toString()
        }

        return String(describing: type(of: error))
    }
}

extension URLError.Code {
    fileprivate func toString() -> String {
        switch self {
        case .unknown:
            return "Unknown"
        case .cancelled:
            return "Cancelled"
        case .badURL:
            return "BadURL"
        case .timedOut:
            return "TimedOut"
        case .unsupportedURL:
            return "UnsupportedURL"
        case .cannotFindHost:
            return "CannotFindHost"
        case .cannotConnectToHost:
            return "CannotConnectToHost"
        case .networkConnectionLost:
            return "NetworkConnectionLost"
        case .dnsLookupFailed:
            return "DNSLookupFailed"
        case .httpTooManyRedirects:
            return "HTTPTooManyRedirects"
        case .resourceUnavailable:
            return "ResourceUnavailable"
        case .notConnectedToInternet:
            return "NotConnectedToInternet"
        case .redirectToNonExistentLocation:
            return "RedirectToNonExistentLocation"
        case .badServerResponse:
            return "BadServerResponse"
        case .userCancelledAuthentication:
            return "UserCancelledAuthentication"
        case .userAuthenticationRequired:
            return "UserAuthenticationRequired"
        case .zeroByteResource:
            return "ZeroByteResource"
        case .cannotDecodeRawData:
            return "CannotDecodeRawData"
        case .cannotDecodeContentData:
            return "CannotDecodeContentData"
        case .cannotParseResponse:
            return "CannotParseResponse"
        case .appTransportSecurityRequiresSecureConnection:
            return "AppTransportSecurityRequiresSecureConnection"
        case .fileDoesNotExist:
            return "FileDoesNotExist"
        case .fileIsDirectory:
            return "FileIsDirectory"
        case .noPermissionsToReadFile:
            return "NoPermissionsToReadFile"
        case .dataLengthExceedsMaximum:
            return "DataLengthExceedsMaximum"

        // SSL/TLS error
        case .secureConnectionFailed:
            return "SecureConnectionFailed"
        case .serverCertificateHasBadDate:
            return "ServerCertificateHasBadDate"
        case .serverCertificateUntrusted:
            return "ServerCertificateUntrusted"
        case .serverCertificateHasUnknownRoot:
            return "ServerCertificateHasUnknownRoot"
        case .serverCertificateNotYetValid:
            return "ServerCertificateNotYetValid"
        case .clientCertificateRequired:
            return "ClientCertificateRequired"
        case .clientCertificateRejected:
            return "ClientCertificateRejected"
        
        // background session error
        case .backgroundSessionRequiresSharedContainer:
            return "BackgroundSessionRequiresSharedContainer"
        case .backgroundSessionInUseByAnotherProcess:
            return "BackgroundSessionInUseByAnotherProcess"
        case .backgroundSessionWasDisconnected:
            return "BackgroundSessionWasDisconnected"
            
        // other error
        case .internationalRoamingOff:
            return "InternationalRoamingOff"
        case .callIsActive:
            return "CallIsActive"
        case .dataNotAllowed:
            return "DataNotAllowed"
        case .requestBodyStreamExhausted:
            return "RequestBodyStreamExhausted"
        case .downloadDecodingFailedMidStream:
            return "DownloadDecodingFailedMidStream"
        case .downloadDecodingFailedToComplete:
            return "DownloadDecodingFailedToComplete"
        default:
            return "NSURLError"
        }
    }
}
