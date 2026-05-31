//
//  WorkspaceManager.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation


class WorkspaceManager: WorkspaceFetcher, Synchronizer {
    private let httpWorkspaceFetcher: HttpWorkspaceFetcher
    private let repository: WorkspaceConfigRepository

    private let lastModified: AtomicReference<String?> = AtomicReference(value: nil)
    private let workspace: AtomicReference<Workspace?> = AtomicReference(value: nil)

    init(httpWorkspaceFetcher: HttpWorkspaceFetcher, repository: WorkspaceConfigRepository) {
        self.httpWorkspaceFetcher = httpWorkspaceFetcher
        self.repository = repository
    }

    func initialize() {
        readWorkspaceConfigFromLocal()
    }

    func fetch() -> Workspace? {
        workspace.get()
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        httpWorkspaceFetcher.fetchIfModified(lastModified: lastModified.get()) { [weak self] result in
            guard let self = self else {
                completion(.failure(HackleError.error("Failed to workspace sync: instance deallocated")))
                return
            }
            self.handle(result: result, completion: completion)
        }
    }

    private func setWorkspaceConfig(_ config: WorkspaceConfig) {
        let workspace = WorkspaceEntity.from(dto: config.config)
        lastModified.set(newValue: config.lastModified)
        self.workspace.set(newValue: workspace)
    }

    private func readWorkspaceConfigFromLocal() {
        if let config = repository.get() {
            setWorkspaceConfig(config)
            Log.debug("Workspace config loaded: [last modified: \(config.lastModified ?? "nil")]")
        }
    }

    private func handle(result: Result<WorkspaceConfig?, Error>, completion: @escaping (Result<(), Error>) -> ()) {
        switch result {
        case .success(let config):
            if let config {
                setWorkspaceConfig(config)
                repository.set(value: config)
            }
            completion(.success(()))
            return
        case .failure(let error):
            completion(.failure(error))
            return
        }
    }
}
