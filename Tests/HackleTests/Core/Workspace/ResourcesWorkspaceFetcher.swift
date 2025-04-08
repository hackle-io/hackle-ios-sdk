//
//  ResourcesWorkspaceFetcher.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
@testable import Hackle


class ResourcesWorkspaceFetcher: WorkspaceFetcher {
    var lastModified: String? = nil

    private let workspace: Workspace

    init(fileName: String) {
        let path = Bundle(for: ResourcesWorkspaceFetcher.self).path(forResource: fileName, ofType: "json")!
        let json = try! String(contentsOfFile: path)

        let dto = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
        workspace = WorkspaceEntity.from(dto: dto)
    }

    func fetch() -> Workspace? {
        workspace
    }

    func initialize(completion: @escaping () -> ()) {
    }
}
