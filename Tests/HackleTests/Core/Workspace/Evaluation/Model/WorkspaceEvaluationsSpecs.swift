import Foundation
import Quick
import Nimble
@testable import Hackle

/// 원격 평가 응답 Dto→Domain 매핑(WorkspaceEvaluations.swift)의 폴백/드랍 분기 스펙.
/// 옵셔널 필드 누락은 기본값(.always/.all/Delay.default)으로 폴백되고,
/// 해석 불가능한 값(신규 enum 등)은 해당 결과만 드랍되어야 한다(워크스페이스 전체 실패 금지).
class WorkspaceEvaluationsSpecs: QuickSpec {

    private static func fixture() -> [String: Any] {
        let path = Bundle(for: WorkspaceEvaluationsSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    /// fixture에서 resultType 결과의 field 페이로드를 꺼내 변형 후 디코드한다
    private static func decodePayload<T: Decodable>(
        _ type: T.Type,
        resultType: String,
        field: String,
        mutate: ((inout [String: Any]) -> Void)? = nil
    ) -> T {
        let full = fixture()["full"] as! [String: Any]
        let results = full["results"] as! [[String: Any]]
        var payload = results.first { ($0["type"] as? String) == resultType }![field] as! [String: Any]
        mutate?(&payload)
        let data = try! JSONSerialization.data(withJSONObject: payload)
        return try! JSONDecoder().decode(type, from: data)
    }

    private static func fullDto(mutateResults: ((inout [[String: Any]]) -> Void)? = nil) -> WorkspaceEvaluationDto {
        var full = fixture()["full"] as! [String: Any]
        var results = full["results"] as! [[String: Any]]
        mutateResults?(&results)
        full["results"] = results
        let data = try! JSONSerialization.data(withJSONObject: full)
        return try! JSONDecoder().decode(WorkspaceEvaluationDto.self, from: data)
    }

    override class func spec() {

        describe("ExperimentEvaluateResultDto.toResultOrNil") {
            it("config가 없으면 parameterConfiguration 없이 매핑한다") {
                let dto = decodePayload(ExperimentEvaluateResultDto.self, resultType: "AB_TEST", field: "experiment") { it in
                    it["config"] = NSNull()
                }
                let result = dto.toResultOrNil(type: .abTest)
                expect(result).toNot(beNil())
                expect(result?.key) == 10
                expect(result?.variation.parameterConfiguration).to(beNil())
            }

            it("미지의 reference 타입은 그 reference만 제외하고 결과는 유지한다") {
                let dto = decodePayload(ExperimentEvaluateResultDto.self, resultType: "AB_TEST", field: "experiment")
                expect(dto.references.count) == 2 // AB_TEST + UNKNOWN_TYPE

                let result = dto.toResultOrNil(type: .abTest)
                expect(result).toNot(beNil())
                expect(result?.references.count) == 1
                expect(result?.references[0].serviceType) == ServiceType.abTest
            }

            it("execution.status가 매핑 불가 값이면 결과를 드랍한다") {
                let dto = decodePayload(ExperimentEvaluateResultDto.self, resultType: "AB_TEST", field: "experiment") { it in
                    it["execution"] = ["status": "UNKNOWN", "version": 1]
                }
                expect(dto.toResultOrNil(type: .abTest)).to(beNil())
            }
        }

        describe("RemoteConfigParameterEvaluateResultDto.toResultOrNil") {
            it("미지의 valueType이면 결과를 드랍한다") {
                let dto = decodePayload(RemoteConfigParameterEvaluateResultDto.self, resultType: "REMOTE_CONFIG", field: "remoteConfig") { it in
                    it["valueType"] = "UNKNOWN_VALUE_TYPE"
                }
                expect(dto.toResultOrNil()).to(beNil())
            }

            it("value가 없으면 value nil로 매핑한다") {
                let dto = decodePayload(RemoteConfigParameterEvaluateResultDto.self, resultType: "REMOTE_CONFIG", field: "remoteConfig") { it in
                    it["value"] = NSNull()
                }
                let result = dto.toResultOrNil()
                expect(result).toNot(beNil())
                expect(result?.value).to(beNil())
            }
        }

        describe("InAppMessageEligibilityEvaluateResultDto.toResultOrNil") {
            func iamResult(_ mutate: ((inout [String: Any]) -> Void)? = nil) -> InAppMessageEligibilityRemoteEvaluateResult? {
                decodePayload(InAppMessageEligibilityEvaluateResultDto.self, resultType: "IN_APP_MESSAGE", field: "inAppMessage", mutate: mutate)
                    .toResultOrNil()
            }

            context("옵셔널 누락은 기본값으로 폴백한다") {
                it("period 누락 → .always") {
                    let result = iamResult { it in
                        it["period"] = NSNull()
                    }
                    expect(result).toNot(beNil())
                    guard case .always = result!.period else {
                        fail("expected .always, got \(result!.period)")
                        return
                    }
                }

                it("timetable 누락 → .all (fixture 원본이 null)") {
                    let result = iamResult()
                    expect(result).toNot(beNil())
                    guard case .all = result!.timetable else {
                        fail("expected .all, got \(result!.timetable)")
                        return
                    }
                }

                it("eventTriggerDelay 누락 → Delay.default (fixture 원본이 null)") {
                    let result = iamResult()
                    expect(result?.eventTrigger.delay.type) == InAppMessage.DelayType.immediate
                    expect(result?.eventTrigger.delay.afterCondition).to(beNil())
                }

                it("evaluateContext가 없으면 atDeliverTime=false로 폴백한다") {
                    let dto = decodePayload(InAppMessageEligibilityEvaluateResultDto.self, resultType: "IN_APP_MESSAGE", field: "inAppMessage") { it in
                        it.removeValue(forKey: "evaluateContext")
                    }
                    let result = dto.toResultOrNil()
                    expect(result).toNot(beNil())
                    expect(result?.evaluateContext.atDeliverTime) == false
                }
            }

            context("해석 불가능한 값은 결과를 드랍한다") {
                it("CUSTOM period에 경계 누락 → nil") {
                    let result = iamResult { it in
                        it["period"] = ["type": "CUSTOM", "startMillisInclusive": 42000]
                    }
                    expect(result).to(beNil())
                }

                it("미지의 period type → nil") {
                    let result = iamResult { it in
                        it["period"] = ["type": "UNKNOWN_PERIOD"]
                    }
                    expect(result).to(beNil())
                }

                it("미지의 timetable type → nil") {
                    let result = iamResult { it in
                        it["timetable"] = ["type": "UNKNOWN_TIMETABLE", "slots": []]
                    }
                    expect(result).to(beNil())
                }

                it("messageContext 파싱 실패(미지 platformType) → nil") {
                    let result = iamResult { it in
                        var messageContext = it["messageContext"] as! [String: Any]
                        messageContext["platformTypes"] = ["UNKNOWN_PLATFORM"]
                        it["messageContext"] = messageContext
                    }
                    expect(result).to(beNil())
                }

                it("layout.message 파싱 실패(미지 displayType) → nil") {
                    let result = iamResult { it in
                        var layout = it["layout"] as! [String: Any]
                        var message = layout["message"] as! [String: Any]
                        var messageLayout = message["layout"] as! [String: Any]
                        messageLayout["displayType"] = "UNKNOWN_DISPLAY"
                        message["layout"] = messageLayout
                        layout["message"] = message
                        it["layout"] = layout
                    }
                    expect(result).to(beNil())
                }
            }

            it("CUSTOM period를 range로 매핑한다 (fixture 원본, ms→s 변환)") {
                let result = iamResult()
                guard case .range(let start, let end) = result!.period else {
                    fail("expected .range, got \(result!.period)")
                    return
                }
                expect(start) == Date(timeIntervalSince1970: 42)
                expect(end) == Date(timeIntervalSince1970: 4_102_444_800)
            }

            it("CUSTOM period의 밀리초를 절삭 없이 보존한다") {
                let result = iamResult { it in
                    it["period"] = ["type": "CUSTOM", "startMillisInclusive": 42500, "endMillisExclusive": 43500]
                }
                guard case .range(let start, let end) = result!.period else {
                    fail("expected .range, got \(result!.period)")
                    return
                }
                expect(start.timeIntervalSince1970) == 42.5
                expect(end.timeIntervalSince1970) == 43.5
            }
        }

        describe("DefaultWorkspaceEvaluation.from") {
            it("해석 불가능한 결과는 드랍하고 나머지 결과를 유지한다") {
                let evaluation = DefaultWorkspaceEvaluation.from(dto: fullDto(), fullEvaluatedAt: 123)

                // fixture: AB_TEST 1, FEATURE_FLAG 1, REMOTE_CONFIG 2(유효 1 + NOT_A_VALUE_TYPE 1), IN_APP_MESSAGE 1, UNKNOWN_SERVICE 1
                expect(evaluation.experimentResults.count) == 1
                expect(evaluation.featureFlagResults.count) == 1
                expect(evaluation.remoteConfigParameterResults.count) == 1
                expect(evaluation.remoteConfigParameterResults[0].key) == "rc_key" // rc_invalid는 드랍
                expect(evaluation.inAppMessageResults.count) == 1
                expect(evaluation.fullEvaluatedAt) == 123
            }

            it("선언된 타입의 페이로드가 없으면 그 결과만 드랍한다") {
                let dto = fullDto { results in
                    for i in results.indices where (results[i]["type"] as? String) == "AB_TEST" {
                        results[i]["experiment"] = NSNull()
                    }
                }
                let evaluation = DefaultWorkspaceEvaluation.from(dto: dto, fullEvaluatedAt: 456)

                expect(evaluation.experimentResults.count) == 0
                expect(evaluation.featureFlagResults.count) == 1
                expect(evaluation.remoteConfigParameterResults.count) == 1
                expect(evaluation.inAppMessageResults.count) == 1
            }
        }
    }
}
