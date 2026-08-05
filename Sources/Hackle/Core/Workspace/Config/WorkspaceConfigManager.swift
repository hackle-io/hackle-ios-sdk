//
//  WorkspaceConfigManager.swift
//  Hackle
//

import Foundation


class WorkspaceConfigManager: WorkspaceManager, WorkspaceConfigFetcher, Synchronizer, @unchecked Sendable {
    private let httpWorkspaceConfigFetcher: HttpWorkspaceConfigFetcher
    private let repository: WorkspaceConfigRepository

    private let context = AtomicReference<WorkspaceConfigContext?>(value: nil)

    init(httpWorkspaceConfigFetcher: HttpWorkspaceConfigFetcher, repository: WorkspaceConfigRepository) {
        self.httpWorkspaceConfigFetcher = httpWorkspaceConfigFetcher
        self.repository = repository
    }

    func initialize() {
        load()
    }

    func metadata() -> WorkspaceMetadata? {
        context.get()?.workspace.metadata
    }

    func workspace(user: HackleUser) -> Workspace? {
        context.get()?.workspace
    }

    func workspace(user: HackleUser) -> WorkspaceConfig? {
        context.get()?.workspace
    }

    func sync() async throws {
        let lastModified = context.get()?.modifiedAt
        let context = try await httpWorkspaceConfigFetcher.fetchIfModified(lastModified: lastModified)
        store(context: context)
    }

    private func store(context: WorkspaceConfigContext?) {
        guard let context else {
            return
        }
        self.context.set(newValue: context)
        repository.set(value: context)
    }

    private func load() {
        if let context = repository.get() {
            self.context.set(newValue: context)
            Log.debug("WorkspaceConfig loaded: [modifiedAt: \(context.modifiedAt ?? "nil")]")
        }
    }
}
