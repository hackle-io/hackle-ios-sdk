//
//  Metric.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation

protocol Metric {

    var id: MetricId { get }

    func measure() -> [Measurement]
}

struct MetricId: Equatable, Hashable {

    let name: String
    let tags: [String: String]
    let type: MetricType

    static func ==(lhs: MetricId, rhs: MetricId) -> Bool {
        lhs.name == rhs.name && lhs.tags == rhs.tags
    }

    func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(name)
        hasher.combine(tags)
    }
}

enum MetricType: String {
    case counter = "COUNTER"
    case timer = "TIMER"
}
