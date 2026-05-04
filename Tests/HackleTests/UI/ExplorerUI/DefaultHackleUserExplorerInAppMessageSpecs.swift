import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class DefaultHackleUserExplorerInAppMessageSpecs: QuickSpec {
    override class func spec() {

        var core: MockHackleCore!
        var userManager: MockUserManager!
        var pushTokenManager: MockPushTokenManager!
        var abTestOverrideStorage: HackleUserManualOverrideStorage!
        var featureFlagOverrideStorage: HackleUserManualOverrideStorage!
        var devToolsAPI: MockDevToolsAPI!
        var sut: DefaultHackleUserExplorer!

        beforeEach {
            core = MockHackleCore()
            userManager = MockUserManager()
            pushTokenManager = MockPushTokenManager()
            abTestOverrideStorage = HackleUserManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository())
            featureFlagOverrideStorage = HackleUserManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository())
            devToolsAPI = MockDevToolsAPI()
            sut = DefaultHackleUserExplorer(
                core: core,
                userManager: userManager,
                pushTokenManager: pushTokenManager,
                abTestOverrideStorage: abTestOverrideStorage,
                featureFlagOverrideStorage: featureFlagOverrideStorage,
                devToolsAPI: devToolsAPI
            )
        }

        describe("getInAppMessageDecisions") {

            it("core.inAppMessages 결과를 그대로 반환한다") {
                let inAppMessage = InAppMessage.create(id: 1, key: 100)
                let evaluation = InAppMessage.eligibilityEvaluation(reason: DecisionReason.IN_APP_MESSAGE_TARGET)
                every(core.inAppMessagesMock).returns([(inAppMessage, evaluation)])

                let actual = sut.getInAppMessageDecisions()

                expect(actual).to(haveCount(1))
                expect(actual[0].0.key) == 100
                expect(actual[0].1.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
            }

            it("core.inAppMessages 가 throw 하면 빈 배열을 반환한다") {
                every(core.inAppMessagesMock).willThrow(HackleError.error("test"))

                let actual = sut.getInAppMessageDecisions()

                expect(actual).to(beEmpty())
            }
        }
    }
}
