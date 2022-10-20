import Foundation
import Quick
import Nimble
@testable import Hackle

class UserEventSpecs: QuickSpec {
    override func spec() {

        describe("ExposureEvent") {

            it("parameterConfigurationId 를 속성으로 설정한다") {
                // given
                let parameterConfiguration = ParameterConfigurationEntity(id: 42, parameters: [:])
                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED, config: parameterConfiguration)
                let experiment = MockExperiment()
                let user = HackleUser.of(userId: "test_id")

                // when
                let actual = UserEvents.exposure(experiment: experiment, user: user, evaluation: evaluation)

                // then
                expect(actual).to(beAnInstanceOf(UserEvents.Exposure.self))
                let exposureEvent = actual as! UserEvents.Exposure
                expect(exposureEvent.properties["$parameterConfigurationId"]).to(be(42))
            }
        }

    }
}
