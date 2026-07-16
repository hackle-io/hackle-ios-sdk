import Foundation
import Nimble
import Quick
@testable import Hackle

class WorkspaceSpecs: QuickSpec {
    override class func spec() {

        it("parse") {
            let file = Bundle(for: WorkspaceSpecs.self).path(forResource: "workspace_response", ofType: "json")!
            let json = try! String(contentsOfFile: file)
            let data = json.data(using: .utf8)!
            let dto = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: data)
            let workspace = DefaultWorkspaceConfig.from(dto: dto, modifiedAt: nil)
            expect(workspace.experiments.count).to(beGreaterThan(1))

            let experiment = workspace.getExperimentOrNil(experimentKey: 42)
            expect(experiment).toNot(beNil())

            // pcid 100538은 fixture상 어떤 featureFlag의 variation에 parse-time 부착되어 있으며,
            // 아래 검증은 parse된 그래프 전체(featureFlags의 모든 variation)를 훑어 해당 parameterConfiguration을 찾아낸다
            let config = workspace.featureFlags
                .flatMap { ($0 as? ExperimentConfig)?.variations ?? [] }
                .compactMap { $0.parameterConfiguration }
                .first { $0.id == 100538 }
            expect(config).toNot(beNil())

            expect(config?.getInt(forKey: "int1", defaultValue: 42)) == 1
            expect(config?.getDouble(forKey: "int1", defaultValue: 42.42)) == 1.0

            expect(config?.getInt(forKey: "int0", defaultValue: 42)) == 0
            expect(config?.getDouble(forKey: "int0", defaultValue: 42.42)) == 0.0

            expect(config?.getInt(forKey: "doube320.42", defaultValue: 42)) == 320
            expect(config?.getDouble(forKey: "doube320.42", defaultValue: 42.42)) == 320.42


            expect(config?.getBool(forKey: "boolean_true", defaultValue: false)) == true
            expect(config?.getBool(forKey: "boolean_false", defaultValue: true)) == false

            expect(config?.getString(forKey: "string", defaultValue: "42")) == "string_value"
        }

        // 회귀 가드: variation.parameterConfiguration 은 parameterConfigurationId 로 resolve 되어야 한다 (variation.id 로 오조회하면 안 된다).
        it("variation 의 parameterConfiguration 은 parameterConfigurationId 로 resolve 된다 (variation.id 아님)") {
            let file = Bundle(for: WorkspaceSpecs.self).path(forResource: "workspace_response", ofType: "json")!
            let json = try! String(contentsOfFile: file)
            let data = json.data(using: .utf8)!
            let dto = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: data)
            let workspace = DefaultWorkspaceConfig.from(dto: dto, modifiedAt: nil)

            let experiment = workspace.experiments.first { exp in
                ((exp as? ExperimentConfig)?.variations ?? []).contains { $0.parameterConfiguration != nil }
            }!
            let variation = ((experiment as? ExperimentConfig)?.variations ?? []).first { $0.parameterConfiguration != nil }!

            // parse-time resolve 된 객체는 dto의 parameterConfigurationId(100550)여야 한다 (variation.id 223310로 오조회 금지)
            expect(variation.parameterConfiguration?.id) == 100550
            expect(variation.parameterConfiguration?.id) != variation.id
        }

        it("experiments와 featureFlags를 order 오름차순으로 정렬한다") {
            func experimentJson(id: Int64, order: Int64) -> String {
                """
                {"id": \(id), "key": \(id), "order": \(order), "name": null, "identifierType": "$id", "status": "RUNNING", "version": 1, "bucketId": 1, "variations": [], "execution": {"status": "RUNNING", "version": 1, "userOverrides": [], "segmentOverrides": [], "targetAudiences": [], "targetRules": [], "defaultRule": {"type": "VARIATION", "variationId": 1}}, "winnerVariationId": null, "containerId": null}
                """
            }

            let json = """
            {
              "workspace": {"id": 1, "environment": {"id": 1}},
              "experiments": [
                \(experimentJson(id: 1, order: 3)),
                \(experimentJson(id: 2, order: 1)),
                \(experimentJson(id: 3, order: 2))
              ],
              "featureFlags": [
                \(experimentJson(id: 11, order: 3)),
                \(experimentJson(id: 12, order: 1)),
                \(experimentJson(id: 13, order: 2))
              ],
              "buckets": [],
              "events": [],
              "segments": [],
              "containers": [],
              "parameterConfigurations": [],
              "remoteConfigParameters": [],
              "inAppMessages": []
            }
            """
            let data = json.data(using: .utf8)!
            let dto = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: data)
            let workspace = DefaultWorkspaceConfig.from(dto: dto, modifiedAt: nil)
            expect(workspace.experiments.map { ($0 as! ExperimentEntity).order }) == [1, 2, 3]
            expect(workspace.featureFlags.map { ($0 as! ExperimentEntity).order }) == [1, 2, 3]
        }
    }
}
