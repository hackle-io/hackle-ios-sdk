import Foundation

class WorkspaceEvaluationManager: WorkspaceManager, WorkspaceEvaluationFetcher, @unchecked Sendable {

    private let evaluateProcessor: WorkspaceEvaluateProcessor
    private let repository: WorkspaceEvaluationRepository
    private let cache: WorkspaceEvaluationCache

    init(
        evaluateProcessor: WorkspaceEvaluateProcessor,
        repository: WorkspaceEvaluationRepository,
        cache: WorkspaceEvaluationCache
    ) {
        self.evaluateProcessor = evaluateProcessor
        self.repository = repository
        self.cache = cache
    }

    func initialize() {
        load()
    }

    func metadata() -> WorkspaceMetadata? {
        cache.latest()?.workspace.metadata
    }

    func workspace(user: HackleUser) -> Workspace? {
        let workspace: WorkspaceEvaluation? = self.workspace(user: user)
        return workspace
    }

    func workspace(user: HackleUser) -> WorkspaceEvaluation? {
        let key = WorkspaceEvaluationContext.keyOf(user: user)
        return cache.get(key: key)?.workspace
    }

    func sync(context: RemoteEvaluateContext) async {
        do {
            let record = cache.get(key: context.key)
            let request = AllWorkspaceEvaluateRequest(context: context, record: record)
            let response = try await evaluateProcessor.process(request: request)
            let resolved = try resolveResponse(request: request, response: response)
            store(record: resolved)
        } catch {
            Log.error("Failed to sync WorkspaceEvaluation: \(error)")
        }
    }

    func evaluate(context: RemoteEvaluateContext, entities: [Entity]) async throws -> WorkspaceEvaluation {
        let request = SpecificWorkspaceEvaluateRequest(context: context, targets: entities)
        let response = try await evaluateProcessor.process(request: request)
        guard let evaluation = response.evaluation else {
            throw HackleError.error("evaluation")
        }
        return DefaultWorkspaceEvaluation.from(dto: evaluation)
    }

    private func resolveResponse(
        request: AllWorkspaceEvaluateRequest,
        response: WorkspaceEvaluateResponse
    ) throws -> WorkspaceEvaluationContext {
        switch response.status {
        case .full:
            guard let evaluation = response.evaluation else {
                throw HackleError.error("response evaluation")
            }
            return WorkspaceEvaluationContext.of(key: request.context.key, dto: evaluation)
        case .delta, .notModified: // DELTA는 evaluator가 FULL로 변환하므로 실제 발생하지 않지만 방어 로직
            guard let record = request.record else {
                throw HackleError.error("current record")
            }
            return record
        }
    }

    private func store(record: WorkspaceEvaluationContext) {
        let snapshots = cache.put(record: record)
        repository.set(records: snapshots)
    }

    private func load() {
        let records = repository.get()
        cache.restore(records: records)
    }
}
