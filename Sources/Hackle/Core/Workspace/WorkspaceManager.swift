//
//  WorkspaceManager.swift
//  Hackle
//

import Foundation


class WorkspaceManager: WorkspaceFetcher, WorkspaceConfigFetcher, Synchronizer {
    private let httpWorkspaceFetcher: HttpWorkspaceFetcher
    private let repository: WorkspaceConfigRepository

    private var lastModified: String? = nil
    private var workspace: WorkspaceConfig? = nil

    init(httpWorkspaceFetcher: HttpWorkspaceFetcher, repository: WorkspaceConfigRepository) {
        self.httpWorkspaceFetcher = httpWorkspaceFetcher
        self.repository = repository
    }

    func initialize() {
        readWorkspaceConfigFromLocal()
    }

    func fetch() -> Workspace? {
        workspace
    }

    func fetch() -> WorkspaceConfig? {
        workspace
    }

    func sync() async throws {
        let response = try await httpWorkspaceFetcher.fetchIfModified(lastModified: lastModified)
        handle(response: response)
    }

    private func handle(response: WorkspaceConfigResponse?) {
        if let response {
            setWorkspaceConfig(response)
            repository.set(value: response)
        }
    }

    private func setWorkspaceConfig(_ config: WorkspaceConfigResponse) {
        lastModified = config.lastModified
        workspace = WorkspaceEntity.from(dto: config.config) as? WorkspaceConfig
    }

    private func readWorkspaceConfigFromLocal() {
        if let config = repository.get() {
            setWorkspaceConfig(config)
            Log.debug("Workspace config loaded: [last modified: \(config.lastModified ?? "nil")]")
        }
    }

}
