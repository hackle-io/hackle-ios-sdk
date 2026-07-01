import Foundation
@testable import Hackle

struct StubEvaluateResult: EvaluateResult {
    let reason: String

    init(reason: String = DecisionReason.DEFAULT_RULE) {
        self.reason = reason
    }
}

struct StubEvaluation: Evaluation {
    let entity: Entity
    let result: EvaluateResult

    init(
        entity: Entity = DefaultEntity(serviceType: .abTest, id: 1),
        result: EvaluateResult = StubEvaluateResult()
    ) {
        self.entity = entity
        self.result = result
    }
}

struct StubEvaluateRequest: EvaluateRequest {
    let user: HackleUser
    let workspace: Workspace
    let entity: Entity
    let record: Bool

    init(
        user: HackleUser = HackleUser.builder().build(),
        workspace: Workspace = MockWorkspace(),
        entity: Entity = DefaultEntity(serviceType: .abTest, id: 1),
        record: Bool = false
    ) {
        self.user = user
        self.workspace = workspace
        self.entity = entity
        self.record = record
    }
}

struct StubEvaluateResponse: EvaluateResponse {
    let user: HackleUser
    let workspace: Workspace
    let evaluation: Evaluation
    let references: [Evaluation]

    init(
        user: HackleUser = HackleUser.builder().build(),
        workspace: Workspace = MockWorkspace(),
        evaluation: Evaluation = StubEvaluation(),
        references: [Evaluation] = []
    ) {
        self.user = user
        self.workspace = workspace
        self.evaluation = evaluation
        self.references = references
    }
}
