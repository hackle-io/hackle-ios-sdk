//
//  DelegatingMetric.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


protocol DelegatingMetric: Metric {

    func add(registry: MetricRegistry)
}
