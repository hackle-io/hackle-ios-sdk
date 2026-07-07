//
//  WorkspaceConfigManager.swift
//  Hackle
//

import Foundation


class WorkspaceConfigManager: WorkspaceFetcher, WorkspaceConfigFetcher, Synchronizer, @unchecked Sendable {
    // ↑ 이 시점에서는 아직 WorkspaceFetcher — Task 2.5에서 WorkspaceManager로 교체
    private let httpWorkspaceConfigFetcher: HttpWorkspaceConfigFetcher
    private let repository: WorkspaceConfigRepository

    private var context: WorkspaceConfigContext? = nil

    init(httpWorkspaceConfigFetcher: HttpWorkspaceConfigFetcher, repository: WorkspaceConfigRepository) {
        self.httpWorkspaceConfigFetcher = httpWorkspaceConfigFetcher
        self.repository = repository
    }

    func initialize() {
        load()
    }

    func fetch() -> Workspace? {
        context?.workspace
    }

    func fetch() -> WorkspaceConfig? {
        context?.workspace
    }

    func sync() async throws {
        let context = try await httpWorkspaceConfigFetcher.fetchIfModified(lastModified: self.context?.modifiedAt)
        store(context: context)
    }

    private func store(context: WorkspaceConfigContext?) {
        guard let context else {
            return
        }
        self.context = context
        repository.set(value: context)
    }

    private func load() {
        if let context = repository.get() {
            self.context = context
            Log.debug("WorkspaceConfig loaded: [modifiedAt: \(context.modifiedAt ?? "nil")]")
        }
    }
}
