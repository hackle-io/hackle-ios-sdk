import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class EvaluationSpecs: QuickSpec {
    override func spec() {

        it("variationKey 에 대한 Variation 이 있으면 해당 Variation 정보로 Evaluation 을 생성한다") {
            let variation = MockVariation(id: 42, key: "C", isDropped: false, parameterConfigurationId: 320)
            let experiment = MockExperiment()
            every(experiment.getVariationByKeyOrNilMock).returns(variation)
            let reason = DecisionReason.TRAFFIC_ALLOCATED
            let config = ParameterConfigurationEntity(id: 32, parameters: [:])
            let workspace = MockWorkspace()
            every(workspace.getParameterConfigurationOrNilMock).returns(config)

            let actual = try Evaluation.of(workspace: workspace, experiment: experiment, variationKey: "C", reason: reason)

            expect(actual) == Evaluation(variationId: 42, variationKey: "C", reason: DecisionReason.TRAFFIC_ALLOCATED, config: config)
        }

        it("Variation 의 parameterConfigurationId 로 ParameterConfiguration 을 찾을 수 없으면 예외 발생") {
            let variation = MockVariation(id: 42, key: "C", isDropped: false, parameterConfigurationId: 320)
            let experiment = MockExperiment()
            every(experiment.getVariationByKeyOrNilMock).returns(variation)
            let reason = DecisionReason.TRAFFIC_ALLOCATED
            let workspace = MockWorkspace()
            every(workspace.getParameterConfigurationOrNilMock).returns(nil)


            expect(try Evaluation.of(workspace: workspace, experiment: experiment, variationKey: "C", reason: reason))
                .to(throwError(HackleError.error("ParameterConfiguration[320]")))
        }

        it("variationKey 에 해당하는 Variation 이 없으면 key 만 설정한다") {
            let experiment = MockExperiment()
            every(experiment.getVariationByKeyOrNilMock).returns(nil)
            let reason = DecisionReason.TRAFFIC_ALLOCATED
            let config = ParameterConfigurationEntity(id: 32, parameters: [:])
            let workspace = MockWorkspace()
            every(workspace.getParameterConfigurationOrNilMock).returns(config)

            let actual = try Evaluation.of(workspace: workspace, experiment: experiment, variationKey: "C", reason: reason)

            expect(actual) == Evaluation(variationId: nil, variationKey: "C", reason: DecisionReason.TRAFFIC_ALLOCATED, config: nil)
        }
    }
}