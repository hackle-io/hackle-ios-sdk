import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class UserEventSpecs: QuickSpec {
    override class func spec() {
        describe("ExposureEvent") {
            it("copy") {
                let parameterConfiguration = ParameterConfigurationEntity(id: 42, parameters: [:])
                let evaluation = ExperimentEvaluation(
                    entity: experiment(),
                    result: ExperimentEvaluateResult(reason: DecisionReason.TRAFFIC_ALLOCATED, variation: VariationEntity(id: 42, key: "A", isDropped: false, parameterConfiguration: parameterConfiguration))
                )
                let user = HackleUser.of(userId: "test_id")
                let workspace = MockWorkspace()
                every(workspace.toPropertiesMock).returns(["config_modified_at": "2024-01-01T00:00:00.000Z"])
                let event = UserEvents.exposure(user: user, workspace: workspace, evaluation: evaluation, properties: ["a": "1"], timestamp: Date(timeIntervalSince1970: 42))
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
                expect(exposureEvent.properties["a"] as? String) == "1"
                expect(exposureEvent.internalProperties["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"
            }
        }

        describe("RemoteConfig") {
            it("copy") {
                let parameter = RemoteConfigParameterEntity(id: 42, key: "key", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("dv")))
                let user = HackleUser.of(userId: "id")
                let evaluation = RemoteConfigEvaluation(
                    entity: parameter,
                    result: RemoteConfigEvaluateResult(reason: DecisionReason.DEFAULT_RULE, value: RemoteConfigParameter.Value(id: 42, rawValue: .string("42")))
                )
                let workspace = MockWorkspace()
                every(workspace.toPropertiesMock).returns(["config_modified_at": "2024-01-01T00:00:00.000Z"])
                let event = UserEvents.remoteConfig(user: user, workspace: workspace, evaluation: evaluation, properties: ["1": "2"], timestamp: Date(timeIntervalSince1970: 42))
                let newUser = HackleUser.of(userId: "new")
                let actual = event.with(user: newUser)
                let remoteConfigEvent = actual as! UserEvents.RemoteConfig

                expect(remoteConfigEvent.user).to(beIdenticalTo(newUser))
                expect(remoteConfigEvent.parameter as? RemoteConfigParameterEntity).to(beIdenticalTo(parameter))
                expect(remoteConfigEvent.valueId) == 42
                expect(remoteConfigEvent.decisionReason) == DecisionReason.DEFAULT_RULE
                expect(remoteConfigEvent.properties["1"] as? String) == "2"
                expect(remoteConfigEvent.internalProperties["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"
            }
        }

        describe("internalProperties") {
            it("attaches workspace internalProperties to events") {
                // given
                let workspace = MockWorkspace()
                every(workspace.toPropertiesMock).returns(["config_modified_at": "2024-01-01T00:00:00.000Z"])
                let user = HackleUser.of(userId: "user")

                // exposure
                let exposureEvent = UserEvents.exposure(user: user, workspace: workspace, evaluation: experimentEvaluation(), properties: [:], timestamp: Date())
                expect(exposureEvent.internalProperties["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"
                expect(exposureEvent.toDto()["internalProperties"] as? [String: Any])
                    .toNot(beNil())
                expect((exposureEvent.toDto()["internalProperties"] as? [String: Any])?["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"

                // track
                let trackEvent = UserEvents.track(event: Event.builder("test").build(), workspace: workspace, timestamp: Date(), user: user)
                expect(trackEvent.internalProperties["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"
                expect((trackEvent.toDto()["internalProperties"] as? [String: Any])?["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"
                expect(trackEvent.toDto()["eventTypeId"] as? Int) == 0
                expect(trackEvent.toDto()["eventTypeKey"] as? String) == "test"

                // remoteConfig
                let parameter = RemoteConfigParameterEntity(id: 42, key: "key", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: .string("dv")))
                let rcEvaluation = RemoteConfigEvaluation(
                    entity: parameter,
                    result: RemoteConfigEvaluateResult(reason: DecisionReason.DEFAULT_RULE, value: RemoteConfigParameter.Value(id: 42, rawValue: .string("42")))
                )
                let remoteConfigEvent = UserEvents.remoteConfig(user: user, workspace: workspace, evaluation: rcEvaluation, properties: [:], timestamp: Date())
                expect(remoteConfigEvent.internalProperties["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"
                expect((remoteConfigEvent.toDto()["internalProperties"] as? [String: Any])?["config_modified_at"] as? String) == "2024-01-01T00:00:00.000Z"
            }

            it("track event carries no internalProperties when workspace is nil") {
                let event = UserEvents.track(event: Event.builder("test").build(), workspace: nil, timestamp: Date(), user: HackleUser.of(userId: "user"))
                expect(event.internalProperties.isEmpty) == true
            }
        }
    }
}
