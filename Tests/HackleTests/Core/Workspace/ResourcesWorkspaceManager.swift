//
//  ResourcesWorkspaceManager.swift
//  HackleTests
//

import Foundation
@testable import Hackle


class ResourcesWorkspaceManager: WorkspaceManager {

    let workspaceConfig: WorkspaceConfig

    init(fileName: String) {
        let path = Bundle(for: ResourcesWorkspaceManager.self).path(forResource: fileName, ofType: "json")!
        let json = try! String(contentsOfFile: path)

        let dto = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
        workspaceConfig = DefaultWorkspaceConfig.from(dto: dto, modifiedAt: nil)
    }

    func initialize() {
    }

    func metadata() -> WorkspaceMetadata? {
        workspaceConfig.metadata
    }

    func workspace(user: HackleUser) -> Workspace? {
        workspaceConfig
    }
}

/// Adapts a ResourcesWorkspaceManager into a WorkspaceConfigFetcher for local decision processing tests.
class ResourcesWorkspaceConfigFetcher: WorkspaceConfigFetcher {
    private let workspaceConfig: WorkspaceConfig
    init(_ manager: ResourcesWorkspaceManager) {
        self.workspaceConfig = manager.workspaceConfig
    }
    func workspace(user: HackleUser) -> WorkspaceConfig? {
        workspaceConfig
    }
}
