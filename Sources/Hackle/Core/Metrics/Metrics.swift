//
//  Metrics.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class Metrics {

    static let globalRegistry = DelegatingMetricRegistry()

    static func clear() {
        globalRegistry.clear()
    }

    static func addRegistry(registry: MetricRegistry) {
        globalRegistry.add(registry: registry)
        Log.info("MetricRegistry added [\(registry)]")
    }

    static func counter(name: String, tags: [String: String] = [:]) -> Counter {
        globalRegistry.counter(name: name, tags: tags)
    }

    static func timer(name: String, tags: [String: String] = [:]) -> Timer {
        globalRegistry.timer(name: name, tags: tags)
    }
}
