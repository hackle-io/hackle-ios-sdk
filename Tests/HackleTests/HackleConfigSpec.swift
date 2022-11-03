//
//  HackleConfigSpec.swift
//  HackleTests
//
//  Created by yong on 2022/08/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class HackleConfigSpec: QuickSpec {
    override func spec() {

        it("exposureEventDedupInterval") {
            expect(HackleConfigBuilder().build().exposureEventDedupInterval) == 60
            expect(HackleConfigBuilder().exposureEventDedupIntervalSeconds(0.9999).build().exposureEventDedupInterval) == 60
            expect(HackleConfigBuilder().exposureEventDedupIntervalSeconds(3600.1).build().exposureEventDedupInterval) == 60


            for i in 1...3600 {
                let config = HackleConfigBuilder()
                    .exposureEventDedupIntervalSeconds(Double(i))
                    .build()
                expect(config.exposureEventDedupInterval) == Double(i)
            }
        }

        it("eventFlushInterval") {
            expect(HackleConfigBuilder().build().eventFlushInterval) == 10
            expect(HackleConfigBuilder().eventFlushIntervalSeconds(0.9999).build().eventFlushInterval) == 10
            expect(HackleConfigBuilder().eventFlushIntervalSeconds(60.1).build().eventFlushInterval) == 10


            for i in 1...60 {
                let config = HackleConfigBuilder()
                    .eventFlushIntervalSeconds(Double(i))
                    .build()
                expect(config.eventFlushInterval) == Double(i)
            }
        }

        it("eventFlushThreshold") {
            expect(HackleConfigBuilder().build().eventFlushThreshold) == 10
            expect(HackleConfigBuilder().eventFlushThreshold(4).build().eventFlushThreshold) == 10
            expect(HackleConfigBuilder().eventFlushThreshold(31).build().eventFlushThreshold) == 10


            for i in 5...30 {
                let config = HackleConfigBuilder()
                    .eventFlushThreshold(i)
                    .build()
                expect(config.eventFlushThreshold) == i
            }
        }
    }
}
