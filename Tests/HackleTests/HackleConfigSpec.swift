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

        describe("exposureEventDedupInterval") {

            it("설정하지 않으면 -1") {
                let config = HackleConfigBuilder()
                    .build()
                expect(config.exposureEventDedupInterval) == -1
            }

            it("1 보다 작은 값으로 설정하면 -1로 설정된다") {
                let config = HackleConfigBuilder()
                    .exposureEventDedupInterval(0.9999)
                    .build()
                expect(config.exposureEventDedupInterval) == -1
            }

            it("3600 보다 큰 값으로 설정하면 -1로 설정된다") {
                let config = HackleConfigBuilder()
                    .exposureEventDedupInterval(3600.1)
                    .build()
                expect(config.exposureEventDedupInterval) == -1
            }

            it("1 ~ 3600 사이의 값으로 설정해야 된다") {
                for i in 1...3600 {
                    let config = HackleConfigBuilder()
                        .exposureEventDedupInterval(Double(i))
                        .build()
                    expect(config.exposureEventDedupInterval) == Double(i)
                }
            }
        }
    }
}
