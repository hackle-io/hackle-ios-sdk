//
// Created by yong on 2020/12/17.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class BucketingDeciderSpec: QuickSpec {
    override func spec() {

        var bucketer: MockBucketer!
        var sut: BucketingDecider!

        beforeEach {
            bucketer = MockBucketer()
            sut = BucketingDecider(bucketer: bucketer)
        }

        let user = User(id: "test_id")
        describe("decide") {

            context("완료된 실험은") {
                it("winner variation으로 강제 할당한다") {
                    // given
                    let experiment = MockCompletedExperiment(winnerVariationKey: "F")

                    // when
                    let actual = sut.decide(experiment: experiment, user: user)

                    // then
                    if case let .ForcedAllocated(variationKey) = actual {
                        expect(variationKey) == "F"
                    } else {
                        fail()
                    }
                }
            }

            context("override된 사용자는") {
                it("override된 variation으로 강제 할당한다") {
                    // given
                    let experiment = MockRunningExperiment()
                    let variation = MockVariation(key: "F")
                    every(experiment.mockGetOverriddenVariationOrNil).returns(variation)

                    // when
                    let actual = sut.decide(experiment: experiment, user: user)

                    // then
                    if case let .ForcedAllocated(variationKey) = actual {
                        expect(variationKey).to(equal("F"))
                    } else {
                        fail()
                    }
                }
            }

            context("할당되지 않은 사용자는") {
                it("NotAllocated를 리턴한다") {
                    // given
                    let experiment = MockRunningExperiment()
                    every(bucketer.mockBucketing).returns(nil)

                    // when
                    let actual = sut.decide(experiment: experiment, user: user)

                    // then
                    expect(actual.isNotAllocated) == true
                }
            }

            context("다른 실험의 슬롯에 할당된 사용자는") {
                it("NotAllocated를 리턴한다") {
                    // given
                    let experiment = MockRunningExperiment()
                    every(experiment.mockGetVariationOrNil).returns(nil)
                    every(bucketer.mockBucketing).returns(MockSlot())

                    // when
                    let actual = sut.decide(experiment: experiment, user: user)

                    // then
                    expect(actual.isNotAllocated) == true
                }
            }

            context("드랍된 Variation인 경우") {
                it("NotAllocated를 리턴한다") {
                    // given
                    let experiment = MockRunningExperiment()
                    every(experiment.mockGetVariationOrNil).returns(MockVariation(isDropped: true))
                    every(bucketer.mockBucketing).returns(MockSlot())

                    // when
                    let actual = sut.decide(experiment: experiment, user: user)

                    // then
                    expect(actual.isNotAllocated) == true
                }
            }

            context("Bucketing으로 할당된 사용자는") {
                it("NaturalAllocated를 리턴한다") {
                    // given
                    let variation = MockVariation(id: 42, key: "E")
                    let experiment = MockRunningExperiment()
                    every(experiment.mockGetVariationOrNil).returns(variation)
                    every(bucketer.mockBucketing).returns(MockSlot())

                    // when
                    let actual = sut.decide(experiment: experiment, user: user)

                    // then
                    if case let .NaturalAllocated(variation) = actual {
                        expect(variation.id) == 42
                        expect(variation.key) == "E"
                    } else {
                        fail()
                    }
                }
            }
        }
    }
}

extension Decision {

    var isNotAllocated: Bool {
        switch self {
        case .NotAllocated:
            return true
        default:
            return false
        }
    }
}
