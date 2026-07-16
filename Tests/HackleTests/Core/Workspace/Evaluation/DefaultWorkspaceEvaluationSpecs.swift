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

        func entityEvaluationDto() -> EntityEvaluationDto {
            let json = """
            {
              "workspace": {"id": 1, "environment": {"id": 2}},
              "metadata": {"evaluatedAt": 1720000000000, "config": {"modifiedAt": "Thu, 10 Jul 2026 00:00:00 GMT"}},
              "results": []
            }
            """
            return try! JSONDecoder().decode(EntityEvaluationDto.self, from: json.data(using: .utf8)!)
        }

        describe("from(dto:)") {
            it("results를 serviceType별로 분류한다") {
                let dto = decodeResponse().full!
                let sut = DefaultWorkspaceEvaluation.from(dto: dto, fullEvaluatedAt: 0)

                expect(sut.experimentResults.count) == 1
                expect(sut.featureFlagResults.count) == 1
                expect(sut.remoteConfigParameterResults.count) == 1 // valueType 파싱 실패 항목은 skip
                expect(sut.inAppMessageResults.count) == 1
            }

            it("알 수 없는 type·변환 실패 항목은 skip한다") {
                let dto = decodeResponse().full!
                let sut = DefaultWorkspaceEvaluation.from(dto: dto, fullEvaluatedAt: 0)

                // UNKNOWN_SERVICE(1건)·rc_invalid(1건)가 빠져 총 4건만 남는다
                let total: Int = sut.experimentResults.count + sut.featureFlagResults.count + sut.remoteConfigParameterResults.count + sut.inAppMessageResults.count
                expect(total) == 4
            }

            it("metadata를 매핑한다") {
                let dto = decodeResponse().full!
                let sut = DefaultWorkspaceEvaluation.from(dto: dto, fullEvaluatedAt: 0)

                expect(sut.metadata.id) == 1
                expect(sut.metadata.environmentId) == 2
                expect(sut.evaluatedAt) == 1720000000000
                expect(sut.modifiedAt) == "Thu, 10 Jul 2026 00:00:00 GMT"
            }

            it("experimentResults와 featureFlagResults를 order 오름차순으로 정렬한다") {
                func resultJson(type: String, id: Int64, order: Int64) -> String {
                    """
                    {
                      "type": "\(type)",
                      "id": \(id),
                      "hash": 1,
                      "\(type == "AB_TEST" ? "experiment" : "featureFlag")": {
                        "id": \(id),
                        "key": \(id),
                        "order": \(order),
                        "version": 1,
                        "executionVersion": 1,
                        "variation": {"id": 1, "key": "A", "status": "ACTIVE", "parameterConfigurationId": null},
                        "config": null,
                        "reason": "TRAFFIC_ALLOCATED",
                        "references": []
                      }
                    }
                    """
                }

                let json = """
                {
                  "workspace": {"id": 1, "environment": {"id": 2}},
                  "results": [
                    \(resultJson(type: "AB_TEST", id: 1, order: 3)),
                    \(resultJson(type: "AB_TEST", id: 2, order: 1)),
                    \(resultJson(type: "AB_TEST", id: 3, order: 2)),
                    \(resultJson(type: "FEATURE_FLAG", id: 11, order: 3)),
                    \(resultJson(type: "FEATURE_FLAG", id: 12, order: 1)),
                    \(resultJson(type: "FEATURE_FLAG", id: 13, order: 2))
                  ],
                  "metadata": {
                    "hash": 1,
                    "evaluatedAt": 1720000000000,
                    "user": {"hash": 1},
                    "config": {"modifiedAt": "Thu, 10 Jul 2026 00:00:00 GMT"}
                  }
                }
                """
                let data = json.data(using: .utf8)!
                let dto = try! JSONDecoder().decode(WorkspaceEvaluationDto.self, from: data)
                let sut = DefaultWorkspaceEvaluation.from(dto: dto, fullEvaluatedAt: 0)

                expect(sut.experimentResults.map { $0.order }) == [1, 2, 3]
                expect(sut.featureFlagResults.map { $0.order }) == [1, 2, 3]
            }

            it("inAppMessageResults를 order 오름차순으로 정렬한다") {
                func resultJson(id: Int64, order: Int64) -> String {
                    """
                    {
                      "type": "IN_APP_MESSAGE",
                      "id": \(id),
                      "hash": 1,
                      "inAppMessage": {
                        "id": \(id),
                        "key": \(id),
                        "order": \(order),
                        "period": null,
                        "timetable": null,
                        "eventTriggerRules": [],
                        "eventFrequencyCap": null,
                        "eventTriggerDelay": null,
                        "evaluateContext": {"atDeliverTime": false},
                        "messageContext": {
                          "defaultLang": "ko",
                          "exposure": {"type": "DEFAULT", "key": null},
                          "platformTypes": ["IOS"],
                          "orientations": ["VERTICAL"],
                          "messages": []
                        },
                        "isEligible": true,
                        "layout": {
                          "message": {
                            "lang": "ko",
                            "layout": {"displayType": "MODAL", "layoutType": "IMAGE_ONLY", "alignment": null},
                            "images": [],
                            "buttons": [],
                            "background": {"color": "#FFFFFF"},
                            "outerButtons": [],
                            "innerButtons": []
                          },
                          "reason": "LAYOUT_REASON",
                          "references": []
                        },
                        "reason": "IN_APP_MESSAGE_TARGET",
                        "references": []
                      }
                    }
                    """
                }

                let json = """
                {
                  "workspace": {"id": 1, "environment": {"id": 2}},
                  "results": [
                    \(resultJson(id: 1, order: 3)),
                    \(resultJson(id: 2, order: 1)),
                    \(resultJson(id: 3, order: 2))
                  ],
                  "metadata": {
                    "hash": 1,
                    "evaluatedAt": 1720000000000,
                    "user": {"hash": 1},
                    "config": {"modifiedAt": "Thu, 10 Jul 2026 00:00:00 GMT"}
                  }
                }
                """
                let data = json.data(using: .utf8)!
                let dto = try! JSONDecoder().decode(WorkspaceEvaluationDto.self, from: data)
                let sut = DefaultWorkspaceEvaluation.from(dto: dto, fullEvaluatedAt: 0)

                expect(sut.inAppMessageResults.map { $0.order }) == [1, 2, 3]
            }
        }

        describe("조회") {
            it("getXxxResultOrNil은 key로 조회한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().full!, fullEvaluatedAt: 0)

                expect(sut.getExperimentResultOrNil(experimentKey: 10)?.id) == 100
                expect(sut.getExperimentResultOrNil(experimentKey: 99)).to(beNil())
                expect(sut.getFeatureFlagResultOrNil(featureKey: 20)?.id) == 200
                expect(sut.getRemoteConfigParameterResultOrNil(parameterKey: "rc_key")?.id) == 300
                expect(sut.getInAppMessageResultOrNil(inAppMessageKey: 40)?.id) == 400
            }

            it("result(entity:)는 serviceType별 리스트에서 id로 찾는다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().full!, fullEvaluatedAt: 0)

                expect(sut.result(entity: DefaultEntity(serviceType: .abTest, id: 100))?.id) == 100
                expect(sut.result(entity: DefaultEntity(serviceType: .featureFlag, id: 200))?.id) == 200
                expect(sut.result(entity: DefaultEntity(serviceType: .remoteConfig, id: 300))?.id) == 300
                expect(sut.result(entity: DefaultEntity(serviceType: .inAppMessage, id: 400))?.id) == 400
                expect(sut.result(entity: DefaultEntity(serviceType: .abTest, id: 999))).to(beNil())
            }
        }

        describe("매핑 상세") {
            it("experiment result의 variation·reason을 매핑한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().full!, fullEvaluatedAt: 0)
                let result = sut.getExperimentResultOrNil(experimentKey: 10)!

                expect(result.variation.key) == "B"
                expect(result.reason) == "TRAFFIC_ALLOCATED"
                expect(result.references.count) == 1 // UNKNOWN_TYPE reference는 skip
            }

            it("config가 오면 parameterConfigurationId와 무관하게 variation에 직접 부착한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().full!, fullEvaluatedAt: 0)
                let result = sut.getExperimentResultOrNil(experimentKey: 10)!

                // 픽스처의 variation.parameterConfigurationId는 null — pcid 조회 방식이면 config가 유실된다
                expect(result.variation.parameterConfiguration?.id) == 9001
            }

            it("in-app message result의 period·evaluateContext·layout을 매핑한다") {
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().full!, fullEvaluatedAt: 0)
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
                let sut = DefaultWorkspaceEvaluation.from(dto: decodeResponse().full!, fullEvaluatedAt: 0)
                let properties = sut.toProperties()

                expect(properties["config_modified_at"] as? String) == "Thu, 10 Jul 2026 00:00:00 GMT"
                expect(properties["remote_evaluated_at"] as? Int64) == 1720000000000
            }

            it("fullEvaluatedAt이 있으면 remote_full_evaluated_at 프로퍼티를 노출한다") {
                let evaluation = DefaultWorkspaceEvaluation.from(dto: decodeResponse().full!, fullEvaluatedAt: 1720000000000)
                expect(evaluation.toProperties()["remote_full_evaluated_at"] as? Int64) == 1720000000000
            }

            it("EntityEvaluationDto로 만들면 remote_full_evaluated_at을 생략한다 (fullEvaluatedAt nil)") {
                let evaluation = DefaultWorkspaceEvaluation.from(dto: entityEvaluationDto())
                expect(evaluation.toProperties()["remote_full_evaluated_at"]).to(beNil())
            }
        }
    }
}
