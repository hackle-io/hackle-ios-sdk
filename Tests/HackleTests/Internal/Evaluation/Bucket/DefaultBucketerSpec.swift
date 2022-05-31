//
// Created by yong on 2020/12/13.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultBucketerSpec: QuickSpec {
    override func spec() {

        var slotNumberCalculator: MockSlotNumberCalculator!
        var sut: DefaultBucketer!

        beforeEach {
            slotNumberCalculator = MockSlotNumberCalculator()
            sut = DefaultBucketer(slotNumberCalculator: slotNumberCalculator)
        }

        describe("bucketing") {
            it("계산된 슬롯번호로 버켓에서 슬롯을 가져온다") {

                // given
                let slot = MockSlot()
                let bucket = MockBucket()
                every(bucket.mockGetSlotOrNil).returns(slot)
                every(slotNumberCalculator.mockCalculate).returns(320)

                // when
                let actual = sut.bucketing(bucket: bucket, identifier: "test_id")

                // then
                expect(actual).to(beIdenticalTo(slot))
                expect(bucket.mockGetSlotOrNil.invokations().count) == 1
                expect(bucket.mockGetSlotOrNil.invokations()[0].arguments) == 320
            }
        }
    }
}
