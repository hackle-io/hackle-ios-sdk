//
//  Container.swift
//  Hackle
//
//  Created by yong on 2022/07/21.
//

import Foundation

protocol Container {
    typealias Id = Int64

    var id: Id { get }
    var bucketId: Bucket.Id { get }
    var groups: [ContainerGroup] { get }

    func getGroupOrNil(containerGroupId: ContainerGroup.Id) -> ContainerGroup?
}


class ContainerEntity: Container {

    let id: Id
    let bucketId: Bucket.Id
    let groups: [ContainerGroup]

    init(id: Id, bucketId: Bucket.Id, groups: [ContainerGroup]) {
        self.id = id
        self.bucketId = bucketId
        self.groups = groups
    }

    func getGroupOrNil(containerGroupId: ContainerGroup.Id) -> ContainerGroup? {
        groups.first { it in
            it.id == containerGroupId
        }
    }
}
