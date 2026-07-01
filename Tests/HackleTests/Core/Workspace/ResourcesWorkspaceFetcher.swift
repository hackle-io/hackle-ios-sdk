//
//  ResourcesWorkspaceFetcher.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
@testable import Hackle


class ResourcesWorkspaceFetcher: WorkspaceFetcher {

    let workspaceConfig: WorkspaceConfig

    init(fileName: String) {
        let path = Bundle(for: ResourcesWorkspaceFetcher.self).path(forResource: fileName, ofType: "json")!
        let json = try! String(contentsOfFile: path)

        let dto = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
        workspaceConfig = WorkspaceEntity.from(dto: dto) as! WorkspaceConfig
    }

    func fetch() -> Workspace? {
        workspaceConfig
    }

    func initialize(completion: @escaping () -> ()) {
    }
}

/// Adapts a ResourcesWorkspaceFetcher into a WorkspaceConfigFetcher for local decision processing tests.
class ResourcesWorkspaceConfigFetcher: WorkspaceConfigFetcher {
    private let workspaceConfig: WorkspaceConfig
    init(_ fetcher: ResourcesWorkspaceFetcher) {
        self.workspaceConfig = fetcher.workspaceConfig
    }
    func fetch() -> WorkspaceConfig? {
        workspaceConfig
    }
}
