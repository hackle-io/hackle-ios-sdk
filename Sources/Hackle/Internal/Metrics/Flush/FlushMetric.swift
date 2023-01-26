//
//  FlushMetric.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


protocol FlushMetric: Metric {
    func flush() -> Metric
}
