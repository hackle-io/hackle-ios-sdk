//
//  MetricsRaceSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/20/26.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class MetricsRaceSpecs: QuickSpec {
    override class func spec() {
        it("test") {
            let q1 = DispatchQueue.concurrent()
            let q2 = DispatchQueue.concurrent()

            let global = DelegatingMetricRegistry()
            let registry = CumulativeMetricRegistry()
            global.add(registry: registry)

            q1.async {
                print("read start")
                for _ in 0..<1000 {
                    let _ = registry.metrics
                }
                print("read end")
            }

            q2.async {
                print("write start")
                for it in 0..<1000 {
                    let _ = global.counter(name: String(it))
                }
                print("write end")
            }

            q1.await()
            q2.await()
        }
        
    }
}
