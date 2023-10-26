//
//  WorkspaceManager.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation


class WorkspaceManager: WorkspaceFetcher, Synchronizer {

    private let httpWorkspaceFetcher: HttpWorkspaceFetcher
    private var workspace: Workspace? = nil

    init(httpWorkspaceFetcher: HttpWorkspaceFetcher) {
        self.httpWorkspaceFetcher = httpWorkspaceFetcher
    }

    func fetch() -> Workspace? {
        workspace
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        httpWorkspaceFetcher.fetchIfModified { result in
            self.handle(result: result, completion: completion)
        }
    }

    private func handle(result: Result<Workspace?, Error>, completion: @escaping (Result<(), Error>) -> ()) {
        switch result {
        case .success(let workspace):
            if let workspace {
                self.workspace = workspace
            }
            completion(.success(()))
            return
        case .failure(let error):
            completion(.failure(error))
            return
        }
    }
}
