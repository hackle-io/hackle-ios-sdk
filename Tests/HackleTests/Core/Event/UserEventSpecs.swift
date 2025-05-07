import Foundation
import Quick
import Nimble
@testable import Hackle

class UserEventSpecs: QuickSpec {
    override func spec() {
        describe("ExposureEvent") {
            it("copy") {
                let parameterConfiguration = ParameterConfigurationEntity(id: 42, parameters: [:])
                let evaluation = ExperimentEvaluation(reason: DecisionReason.TRAFFIC_ALLOCATED, targetEvaluations: [], experiment: experiment(), variationId: 42, variationKey: "A", config: parameterConfiguration)
                let user = HackleUser.of(userId: "test_id")
                let event = UserEvents.exposure(user: user, evaluation: evaluation, properties: ["a": "1"], timestamp: Date(timeIntervalSince1970: 42))
                let newUser = HackleUser.of(userId: "new")
                let actual = event.with(user: newUser)

                // then
                expect(actual).to(beAnInstanceOf(UserEvents.Exposure.self))
                let exposureEvent = actual as! UserEvents.Exposure
                expect(exposureEvent.user).to(beIdenticalTo(newUser))
                expect(exposureEvent.variationId) == event.variationId
                expect(exposureEvent.variationKey) == event.variationKey
                expect(exposureEvent.timestamp) == event.timestamp
                expect(exposureEvent.decisionReason) == event.decisionReason
                expect(exposureEvent.properties["a"]).to(be("1"))
            }
        }

        describe("RemoteConfig") {
            it("copy") {
                let parameter = RemoteConfigParameter(id: 42, key: "key", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("dv")))
                let user = HackleUser.of(userId: "id")
                let evaluation = RemoteConfigEvaluation(reason: DecisionReason.DEFAULT_RULE, targetEvaluations: [], parameter: parameter, valueId: 42, value: .string("42"), properties: ["1": "2"])
                let event = UserEvents.remoteConfig(user: user, evaluation: evaluation, properties: ["1": "2"], timestamp: Date(timeIntervalSince1970: 42))
                let newUser = HackleUser.of(userId: "new")
                let actual = event.with(user: newUser)
                let remoteConfigEvent = actual as! UserEvents.RemoteConfig

                expect(remoteConfigEvent.user).to(beIdenticalTo(newUser))
                expect(remoteConfigEvent.parameter).to(beIdenticalTo(parameter))
                expect(remoteConfigEvent.valueId) == 42
                expect(remoteConfigEvent.decisionReason) == DecisionReason.DEFAULT_RULE
                expect(remoteConfigEvent.properties["1"] as? String) == "2"
            }
        }
    }
}
