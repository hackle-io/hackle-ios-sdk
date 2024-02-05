import Foundation
import Nimble
import Quick
@testable import Hackle

class WorkspaceSpecs: QuickSpec {
    override func spec() {

        it("parse") {
            let file = Bundle(for: WorkspaceSpecs.self).path(forResource: "workspace_response", ofType: "json")!
            let json = try! String(contentsOfFile: file)
            let data = json.data(using: .utf8)!
            let dto = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: data)
            let workspace = WorkspaceEntity.from(dto: dto)
            expect(workspace.experiments.count).to(beGreaterThan(1))

            let experiment = workspace.getExperimentOrNil(experimentKey: 42)
            expect(experiment).toNot(beNil())

            let config = workspace.getParameterConfigurationOrNil(parameterConfigurationId: 100538)
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
    }
}
