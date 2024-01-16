//
//  WorkspaceManager.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation


class WorkspaceManager: WorkspaceFetcher, Synchronizer {

    private let httpWorkspaceFetcher: HttpWorkspaceFetcher
    private let workspaceFile: FileReadWriter?
    
    private var lastModified: String? = nil
    private var workspace: Workspace? = nil

    init(httpWorkspaceFetcher: HttpWorkspaceFetcher, workspaceFile: FileReadWriter?) {
        self.httpWorkspaceFetcher = httpWorkspaceFetcher
        self.workspaceFile = workspaceFile
        
        readWorkspaceConfigFromLocal()
    }

    func fetch() -> Workspace? {
        workspace
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        httpWorkspaceFetcher.fetchIfModified(lastModified: lastModified) { result in
            self.handle(result: result, completion: completion)
        }
    }
    
    private func setWorkspaceConfig(_ config: WorkspaceConfig) {
        lastModified = config.lastModified
        workspace = WorkspaceEntity.from(dto: config.config)
    }
    
    private func readWorkspaceConfigFromLocal() {
        if let data = try? workspaceFile?.read(),
           let config = try? JSONDecoder().decode(WorkspaceConfig.self, from: data) {
            setWorkspaceConfig(config)
            Log.debug("Found workspace config: [last modified: \(lastModified ?? "nil")]")
        }
    }
    
    private func saveWorkspaceConfigInLocal(_ config: WorkspaceConfig) {
        if let data = try? JSONEncoder().encode(config) {
            try? workspaceFile?.write(data: data)
        }
    }

    private func handle(result: Result<WorkspaceConfig?, Error>, completion: @escaping (Result<(), Error>) -> ()) {
        switch result {
        case .success(let config):
            if let config {
                setWorkspaceConfig(config)
                saveWorkspaceConfigInLocal(config)
            }
            completion(.success(()))
            return
        case .failure(let error):
            completion(.failure(error))
            return
        }
    }
}
