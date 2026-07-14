import Foundation
import Quick
import Nimble
@testable import Hackle

class WorkspaceEvaluationSpecs: QuickSpec {
    override class func spec() {
        it("base Workspace accessors delegate to typed results") {
            let experiment = experimentRemoteResult(id: 1, key: 10)
            let workspace = MockWorkspaceEvaluation()
            workspace.experimentResults = [experiment]

            expect(workspace.experiments.count).to(equal(1))
            expect(workspace.getExperimentOrNil(experimentKey: 10)?.entityKey).to(equal(experiment.entityKey))
            expect(workspace.getExperimentOrNil(experimentKey: 11)).to(beNil())
        }

        it("result(entity:) matches by entityKey") {
            let experiment = experimentRemoteResult(id: 1, key: 10)
            let workspace = MockWorkspaceEvaluation()
            workspace.experimentResults = [experiment]

            let found = workspace.result(entity: DefaultEntity(serviceType: .abTest, id: 1))
            expect(found?.entityKey).to(equal(experiment.entityKey))
            expect(workspace.result(entity: DefaultEntity(serviceType: .abTest, id: 2))).to(beNil())
        }
    }
}
