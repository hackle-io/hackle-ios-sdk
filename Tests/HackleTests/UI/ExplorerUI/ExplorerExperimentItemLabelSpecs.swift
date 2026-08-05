import Foundation
import Nimble
import Quick
@testable import Hackle

class ExplorerExperimentItemLabelSpecs: QuickSpec {
    override class func spec() {

        func remoteExperiment(type: ExperimentType) -> Experiment {
            ExperimentRemoteEvaluateResult(
                id: 1,
                key: 42,
                version: 3,
                status: .running,
                order: 0,
                type: type,
                executionVersion: 1,
                variation: VariationEntity(id: 1, key: "A", isDropped: false, parameterConfiguration: nil),
                reason: DecisionReason.TRAFFIC_ALLOCATED,
                references: []
            )
        }

        it("AB descLabel: ExperimentConfig(LOCAL)는 기존 형식을 유지한다") {
            let config = experiment(id: 1, key: 42, type: .abTest)
            let item = HackleAbTestItem(
                experiment: config,
                decision: Decision.of(experiment: config, variation: "A", reason: DecisionReason.TRAFFIC_ALLOCATED),
                overriddenVariation: nil
            )
            expect(item.descLabel) == "V1 | running | A/B | $id"
        }

        it("AB descLabel: ExperimentConfig가 아니면(REMOTE) 빈 문자열을 반환한다") {
            let remote = remoteExperiment(type: .abTest)
            let item = HackleAbTestItem(
                experiment: remote,
                decision: Decision.of(experiment: remote, variation: "A", reason: DecisionReason.TRAFFIC_ALLOCATED),
                overriddenVariation: nil
            )
            expect(item.descLabel) == ""
        }

        it("FF descLabel: ExperimentConfig(LOCAL)는 기존 형식을 유지한다") {
            let config = experiment(id: 2, key: 43, type: .featureFlag)
            let item = HackleFeatureFlagItem(
                experiment: config,
                decision: FeatureFlagDecision.off(featureFlag: config, reason: DecisionReason.FEATURE_FLAG_INACTIVE),
                overriddenVariation: nil
            )
            expect(item.descLabel) == "running | $id"
        }

        it("FF descLabel: ExperimentConfig가 아니면(REMOTE) 빈 문자열을 반환한다") {
            let remote = remoteExperiment(type: .featureFlag)
            let item = HackleFeatureFlagItem(
                experiment: remote,
                decision: FeatureFlagDecision.off(featureFlag: remote, reason: DecisionReason.FEATURE_FLAG_INACTIVE),
                overriddenVariation: nil
            )
            expect(item.descLabel) == ""
        }
    }
}
