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

    func sync(completion: @escaping () -> ()) {
        httpWorkspaceFetcher.fetchIfModified { [weak self] workspace, error in
            self?.handle(workspace: workspace, error: error)
        }
    }

    private func handle(workspace: Workspace?, error: Error?) {
        if let error {
            Log.error("Failed to fetch Workspace: \(error)")
            return
        }
        guard let workspace else {
            Log.error("Failed to fetch Workspace: workspace is nil")
            return
        }
        self.workspace = workspace
    }
}
