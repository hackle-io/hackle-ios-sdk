import Foundation

class WorkspaceEvaluationManager: WorkspaceManager, WorkspaceEvaluationFetcher, @unchecked Sendable {

    private let fullEvaluator: FullWorkspaceRemoteEvaluator
    private let partialEvaluator: PartialWorkspaceRemoteEvaluator
    private let repository: WorkspaceEvaluationRepository
    private let cache: WorkspaceEvaluationCache

    init(
        fullEvaluator: FullWorkspaceRemoteEvaluator,
        partialEvaluator: PartialWorkspaceRemoteEvaluator,
        repository: WorkspaceEvaluationRepository,
        cache: WorkspaceEvaluationCache
    ) {
        self.fullEvaluator = fullEvaluator
        self.partialEvaluator = partialEvaluator
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
            let base = cache.get(key: context.key)
            let request = FullWorkspaceEvaluateRequest.of(context: context, base: base)
            let response = try await fullEvaluator.evaluate(request: request)
            store(context: response.context)
        } catch {
            Log.error("Failed to sync WorkspaceEvaluation: \(error)")
        }
    }

    func evaluate(context: RemoteEvaluateContext, entities: [Entity]) async throws -> WorkspaceEvaluation {
        let request = PartialWorkspaceEvaluateRequest(context: context, entities: entities)
        let response = try await partialEvaluator.evaluate(request: request)
        return response.evaluation
    }

    private func store(context: WorkspaceEvaluationContext) {
        let snapshots = cache.put(context: context)
        repository.set(contexts: snapshots)
    }

    private func load() {
        let contexts = repository.get()
        cache.restore(contexts: contexts)
    }
}
