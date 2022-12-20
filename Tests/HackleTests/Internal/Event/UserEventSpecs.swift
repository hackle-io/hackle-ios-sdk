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

            it("copy") {
                let parameterConfiguration = ParameterConfigurationEntity(id: 42, parameters: [:])
                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED, config: parameterConfiguration)
                let experiment = MockExperiment()
                let user = HackleUser.of(userId: "test_id")
                let event = UserEvents.exposure(experiment: experiment, user: user, evaluation: evaluation) as! UserEvents.Exposure

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
                expect(exposureEvent.properties["$parameterConfigurationId"]).to(be(42))
            }
        }

        describe("RemoteConfig") {
            it("create") {
                // given
                let parameter = RemoteConfigParameter(id: 42, key: "key", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("dv")))
                let user = HackleUser.of(userId: "id")
                let evaluation = RemoteConfigEvaluation(valueId: 42, value: HackleValue.string("remote config value"), reason: DecisionReason.DEFAULT_RULE, properties: [
                    "string": "a",
                    "number": 1,
                    "bool": false
                ])

                // when
                let actual = UserEvents.remoteConfig(parameter: parameter, user: user, evaluation: evaluation)

                // then
                expect(actual).to(beAnInstanceOf(UserEvents.RemoteConfig.self))
                let remoteConfigEvent = actual as! UserEvents.RemoteConfig

                expect(remoteConfigEvent.parameter).to(beIdenticalTo(parameter))
                expect(remoteConfigEvent.valueId) == 42
                expect(remoteConfigEvent.decisionReason) == DecisionReason.DEFAULT_RULE
                expect(remoteConfigEvent.properties["string"] as? String) == "a"
                expect(remoteConfigEvent.properties["number"] as? Int) == 1
                expect(remoteConfigEvent.properties["bool"] as? Bool) == false
            }

            it("copy") {
                let parameter = RemoteConfigParameter(id: 42, key: "key", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("dv")))
                let user = HackleUser.of(userId: "id")
                let evaluation = RemoteConfigEvaluation(valueId: 42, value: HackleValue.string("remote config value"), reason: DecisionReason.DEFAULT_RULE, properties: [
                    "string": "a",
                    "number": 1,
                    "bool": false
                ])

                let event = UserEvents.remoteConfig(parameter: parameter, user: user, evaluation: evaluation)

                let newUser = HackleUser.of(userId: "new")
                let actual = event.with(user: newUser)

                let remoteConfigEvent = actual as! UserEvents.RemoteConfig

                expect(remoteConfigEvent.user).to(beIdenticalTo(newUser))
                expect(remoteConfigEvent.parameter).to(beIdenticalTo(parameter))
                expect(remoteConfigEvent.valueId) == 42
                expect(remoteConfigEvent.decisionReason) == DecisionReason.DEFAULT_RULE
                expect(remoteConfigEvent.properties["string"] as? String) == "a"
                expect(remoteConfigEvent.properties["number"] as? Int) == 1
                expect(remoteConfigEvent.properties["bool"] as? Bool) == false
            }
        }
    }
}
