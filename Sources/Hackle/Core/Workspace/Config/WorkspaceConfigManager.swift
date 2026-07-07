//
//  WorkspaceConfigManager.swift
//  Hackle
//

import Foundation


class WorkspaceConfigManager: WorkspaceManager, WorkspaceConfigFetcher, Synchronizer, @unchecked Sendable {
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

    func metadata() -> WorkspaceMetadata? {
        context?.workspace.metadata
    }

    func workspace(user: HackleUser) -> Workspace? {
        context?.workspace
    }

    func workspace(user: HackleUser) -> WorkspaceConfig? {
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
