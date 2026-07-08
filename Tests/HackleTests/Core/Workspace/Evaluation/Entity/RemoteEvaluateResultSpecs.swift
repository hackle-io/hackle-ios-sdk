import Foundation
import Quick
import Nimble
@testable import Hackle

class RemoteEvaluateResultSpecs: QuickSpec {
    override class func spec() {

        describe("ExperimentRemoteEvaluateResult") {
            let variation = VariationEntity(id: 42, key: "B", isDropped: false, parameterConfiguration: nil)
            let sut = ExperimentRemoteEvaluateResult(
                id: 1,
                key: 10,
                version: 2,
                type: .abTest,
                executionVersion: 3,
                variation: variation,
                reason: DecisionReason.OVERRIDDEN,
                references: [DefaultEntity(serviceType: .abTest, id: 99)]
            )

            it("is an Experiment entity carrying the server-evaluated result") {
                expect(sut.serviceType).to(equal(.abTest))
                expect(sut.entityKey).to(equal(EntityKey(serviceType: .abTest, id: 1)))
                expect(sut.key).to(equal(10))
                expect(sut.version).to(equal(2))
                expect(sut.type).to(equal(.abTest))
                expect(sut.executionVersion).to(equal(3))
                expect(sut.variation.id).to(equal(42))
                expect(sut.reason).to(equal(DecisionReason.OVERRIDDEN))
                expect(sut.references.count).to(equal(1))
            }

            it("toEvaluation returns ExperimentEvaluation of itself") {
                let evaluation = sut.toEvaluation()
                guard let experimentEvaluation = evaluation as? ExperimentEvaluation else {
                    fail("expected ExperimentEvaluation")
                    return
                }
                expect(experimentEvaluation.entity.entityKey).to(equal(sut.entityKey))
                expect(experimentEvaluation.experimentResult.variation.key).to(equal("B"))
            }
        }

        describe("RemoteConfigParameterRemoteEvaluateResult") {
            let value = RemoteConfigParameterEntity.Value(id: 7, rawValue: HackleValue(value: "v"))
            let sut = RemoteConfigParameterRemoteEvaluateResult(
                id: 2,
                key: "rc_key",
                type: .string,
                value: value,
                reason: DecisionReason.TARGET_RULE_MATCH,
                references: []
            )

            it("is a RemoteConfigParameter entity carrying the server-evaluated result") {
                expect(sut.serviceType).to(equal(.remoteConfig))
                expect(sut.key).to(equal("rc_key"))
                expect(sut.type).to(equal(.string))
                expect(sut.value?.id).to(equal(7))
                expect(sut.reason).to(equal(DecisionReason.TARGET_RULE_MATCH))
                expect(sut.references).to(beEmpty())
            }

            it("toEvaluation returns RemoteConfigEvaluation of itself") {
                let evaluation = sut.toEvaluation()
                guard let rcEvaluation = evaluation as? RemoteConfigEvaluation else {
                    fail("expected RemoteConfigEvaluation")
                    return
                }
                expect(rcEvaluation.parameter.id).to(equal(2))
                expect(rcEvaluation.remoteConfigResult.value?.id).to(equal(7))
            }
        }
    }
}
