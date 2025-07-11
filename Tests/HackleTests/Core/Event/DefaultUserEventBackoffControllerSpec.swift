//
//  DefaultUserEventBackoffControllerSpec.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/11/25.
//

import Quick
import Nimble
@testable import Hackle
import Foundation

class DefaultUserEventBackoffControllerSpec: QuickSpec {
    override func spec() {
        var sut: DefaultUserEventBackoffController!
        var clock: FixedClock!

        beforeEach {
            clock = FixedClock(date: Date())
            sut = DefaultUserEventBackoffController(clock: clock)
        }

        describe("DefaultUserEventBackoffController") {

            context("초기 상태일 때") {
                it("isAllowNextFlush()는 항상 true를 반환해야 한다") {
                    expect(sut.isAllowNextFlush()).to(beTrue())
                }
            }

            context("checkResponse에 성공(true)을 전달했을 때") {
                it("isAllowNextFlush()는 계속 true를 반환해야 한다") {
                    sut.checkResponse(true)
                    expect(sut.isAllowNextFlush()).to(beTrue())

                    sut.checkResponse(true)
                    expect(sut.isAllowNextFlush()).to(beTrue())
                }
            }

            context("checkResponse에 실패(false)를 전달했을 때") {
                it("첫 실패 후에는 60초 동안 flush가 허용되지 않아야 한다") {
                    // given: 첫 실패
                    sut.checkResponse(false) // failureCount = 1 -> delay = 2^(1-1) * 60 = 60초

                    // when: 60초가 지나기 전
                    clock.fastForward(58)
                    // then: flush는 허용되지 않음
                    expect(sut.isAllowNextFlush()).to(beFalse())

                    // when: 60초가 지났을 때
                    clock.fastForward(3)
                    // then: flush가 허용됨
                    expect(sut.isAllowNextFlush()).to(beTrue())
                }

                it("연속 두 번 실패 후에는 120초 동안 flush가 허용되지 않아야 한다") {
                    // given: 연속 두 번 실패
                    sut.checkResponse(false) // 60초 delay 설정됨
                    sut.checkResponse(false) // failureCount = 2 -> delay = 2^(2-1) * 60 = 120초

                    // when: 120초가 지나기 전
                    clock.fastForward(118)
                    // then: flush는 허용되지 않음
                    expect(sut.isAllowNextFlush()).to(beFalse())

                    // when: 120초가 지났을 때
                    clock.fastForward(3)
                    // then: flush가 허용됨
                    expect(sut.isAllowNextFlush()).to(beTrue())
                }
            }

            context("실패 후 성공했을 때") {
                it("backoff 타이머가 리셋되어 즉시 flush가 허용되어야 한다") {
                    // given: 실패하여 flush가 막힌 상태
                    sut.checkResponse(false)
                    expect(sut.isAllowNextFlush()).to(beFalse())

                    // when: 성공 응답을 받으면
                    sut.checkResponse(true)

                    // then: backoff 상태가 리셋되어 즉시 flush 가능
                    expect(sut.isAllowNextFlush()).to(beTrue())
                }
            }
            
            context("실패가 계속되어 최대 간격(maxInterval)에 도달했을 때") {
                it("지연 시간이 userEventMaxInterval을 초과하지 않아야 한다") {
                    for _ in 0..<10 {
                        sut.checkResponse(false)
                    }

                    // when: 최대 간격이 지나기 전
                    clock.fastForward(Double(userEventRetryMaxInterval / 1000 - 5))
                    // then: flush는 허용되지 않음
                    expect(sut.isAllowNextFlush()).to(beFalse())

                    // when: 최대 간격이 지났을 때
                    clock.fastForward(10)
                    // then: flush가 허용됨
                    expect(sut.isAllowNextFlush()).to(beTrue())
                }
            }
        }
    }
}
