import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleInAppMessageItemSpecs: QuickSpec {
    override class func spec() {

        describe("of(decisions:)") {

            it("key 내림차순으로 정렬한다") {
                let m1 = InAppMessage.create(id: 1, key: 1)
                let m2 = InAppMessage.create(id: 2, key: 2)
                let m3 = InAppMessage.create(id: 3, key: 3)
                let e = InAppMessage.eligibilityEvaluation(reason: DecisionReason.IN_APP_MESSAGE_TARGET)

                let actual = HackleInAppMessageItem.of(decisions: [(m1, e), (m3, e), (m2, e)])

                expect(actual.map { $0.inAppMessage.key }) == [3, 2, 1]
            }
        }

        describe("labels") {

            it("keyLabel 은 '# {key}' 형식이다") {
                let m = InAppMessage.create(id: 1, key: 42)
                let e = InAppMessage.eligibilityEvaluation(reason: DecisionReason.IN_APP_MESSAGE_TARGET)

                let item = HackleInAppMessageItem(inAppMessage: m, evaluation: e)

                expect(item.keyLabel) == "# 42"
            }

            it("descLabel 은 status.rawValue 그대로다 (active)") {
                let m = InAppMessage.create(id: 1, key: 42, status: .active)
                let e = InAppMessage.eligibilityEvaluation(reason: DecisionReason.IN_APP_MESSAGE_TARGET)

                let item = HackleInAppMessageItem(inAppMessage: m, evaluation: e)

                expect(item.descLabel) == "ACTIVE"
            }

            it("descLabel 은 status.rawValue 그대로다 (draft)") {
                let m = InAppMessage.create(id: 1, key: 42, status: .draft)
                let e = InAppMessage.eligibilityEvaluation(reason: DecisionReason.IN_APP_MESSAGE_DRAFT)

                let item = HackleInAppMessageItem(inAppMessage: m, evaluation: e)

                expect(item.descLabel) == "DRAFT"
            }

            it("reasonLabel 은 evaluation.reason 그대로다") {
                let m = InAppMessage.create(id: 1, key: 42)
                let e = InAppMessage.eligibilityEvaluation(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)

                let item = HackleInAppMessageItem(inAppMessage: m, evaluation: e)

                expect(item.reasonLabel) == "NOT_IN_IN_APP_MESSAGE_TARGET"
            }
        }
    }
}
