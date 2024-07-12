//
//  Created by yong on 2023/01/18.
//

import Foundation


class MonitoringMetricRegistry: MetricRegistry, AppStateListener {

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

    func onState(state: AppState, timestamp: Date) {
        Log.debug("MonitoringMetricRegistry.onState(state: \(state))")
        switch state {
        case .foreground: return
        case .background:
            eventQueue.async { [weak self] in
                self?.flush()
            }
        }
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
    static func record(operation: String, sample: TimerSample, response: HttpResponse) {
        let tags = [
            "operation": operation,
            "success": success(response: response)
        ]
        let timer = Metrics.timer(name: "api.call", tags: tags)
        sample.stop(timer: timer)
    }

    private static func success(response: HttpResponse) -> String {
        let success = response.isSuccessful || response.isNotModified
        return success ? "true" : "false"
    }
}
