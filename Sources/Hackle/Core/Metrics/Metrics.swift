//
//  Metrics.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class Metrics {

    static let queue = DispatchQueue(label: "io.hackle.metrics", qos: .utility)
    static let globalRegistry = DelegatingMetricRegistry()

    static func clear() {
        queue.async {
            globalRegistry.clear()
        }
    }

    static func addRegistry(registry: MetricRegistry) {
        queue.async {
            globalRegistry.add(registry: registry)
            Log.info("MetricRegistry added [\(registry)]")
        }
    }

    static func counter(name: String, tags: [String: String] = [:], _ block: @escaping (Counter) -> Void) {
        queue.async {
            block(globalRegistry.counter(name: name, tags: tags))
        }
    }

    static func timer(name: String, tags: [String: String] = [:], _ block: @escaping (Timer) -> Void) {
        queue.async {
            block(globalRegistry.timer(name: name, tags: tags))
        }
    }
}
