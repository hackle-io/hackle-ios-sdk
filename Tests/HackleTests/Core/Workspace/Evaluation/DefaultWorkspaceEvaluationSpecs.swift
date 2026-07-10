import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultWorkspaceEvaluationSpecs: QuickSpec {
    override class func spec() {

        func decodeResponse() -> WorkspaceEvaluateResponseDto {
            let file = Bundle(for: DefaultWorkspaceEvaluationSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data)
        }

        describe("from(dto:)") {
            it("results를 serviceType별로 분류한다") {
                let dto = decodeResponse().evaluation!
                let sut = DefaultWorkspaceEvaluation.from(dto: dto)

                expect(sut.experimentResults.count) == 1
                expect(sut.featureFlagResults.count) == 1
                expect(sut.remoteConfigParameterResults.count) == 1 // valueType 파싱 실패 항목은 skip
                expect(sut.inAppMessageResults.count) == 1
            }

            it("알 수 없는 type·변환 실패 항목은 skip한다") {
                let dto = decodeResponse().evaluation!
                let sut = DefaultWorkspaceEvaluation.from(dto: dto)

                // UNKNOWN_SERVICE(1건)·rc_invalid(1건)가 빠져 총 4건만 남는다
                let total: Int = sut.experimentResults.count + sut.featureFlagResults.count + sut.remoteConfigParameterResults.count + sut.inAppMessageResults.count
                expect(total) == 4
            }

            it("metadata를 매핑한다") {
                let dto = decodeResponse().evaluation!
                let sut = DefaultWorkspaceEvaluation.from(dto: dto)

                expect(sut.metadata.id) == 1
                expect(sut.metadata.environmentId) == 2
                expect(sut.evaluatedAt) == 1720000000000
                expect(sut.modifiedAt) == "Thu, 10 Jul 2026 00:00:00 GMT"
            }
        }

        describe("조회") {
            it("getXxxResultOrNil은 key로 조회한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().evaluation!)

                expect(sut.getExperimentResultOrNil(experimentKey: 10)?.id) == 100
                expect(sut.getExperimentResultOrNil(experimentKey: 99)).to(beNil())
                expect(sut.getFeatureFlagResultOrNil(featureKey: 20)?.id) == 200
                expect(sut.getRemoteConfigParameterResultOrNil(parameterKey: "rc_key")?.id) == 300
                expect(sut.getInAppMessageResultOrNil(inAppMessageKey: 40)?.id) == 400
            }

            it("result(entity:)는 serviceType별 리스트에서 id로 찾는다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().evaluation!)

                expect(sut.result(entity: DefaultEntity(serviceType: .abTest, id: 100))?.id) == 100
                expect(sut.result(entity: DefaultEntity(serviceType: .featureFlag, id: 200))?.id) == 200
                expect(sut.result(entity: DefaultEntity(serviceType: .remoteConfig, id: 300))?.id) == 300
                expect(sut.result(entity: DefaultEntity(serviceType: .inAppMessage, id: 400))?.id) == 400
                expect(sut.result(entity: DefaultEntity(serviceType: .abTest, id: 999))).to(beNil())
            }
        }

        describe("매핑 상세") {
            it("experiment result의 variation·reason을 매핑한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().evaluation!)
                let result = sut.getExperimentResultOrNil(experimentKey: 10)!

                expect(result.variation.key) == "B"
                expect(result.reason) == "TRAFFIC_ALLOCATED"
                expect(result.references.count) == 1 // UNKNOWN_TYPE reference는 skip
            }

            it("in-app message result의 period·evaluateContext·layout을 매핑한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().evaluation!)
                let result = sut.getInAppMessageResultOrNil(inAppMessageKey: 40)!

                expect(result.isEligible) == true
                expect(result.evaluateContext.atDeliverTime) == true
                expect(result.layout.id) == 400
                expect(result.layout.reason) == "IN_APP_MESSAGE_TARGET" // outer(eligibility) reason이어야 하며, nested layout.reason("LAYOUT_INNER_REASON")이 아니어야 한다
                if case .range = result.period {
                } else {
                    fail("period must be range")
                }
            }
        }

        describe("toProperties") {
            it("config_modified_at과 remote_evaluated_at을 포함한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().evaluation!)
                let properties = sut.toProperties()

                expect(properties["config_modified_at"] as? String) == "Thu, 10 Jul 2026 00:00:00 GMT"
                expect(properties["remote_evaluated_at"] as? Int64) == 1720000000000
            }
        }
    }
}
