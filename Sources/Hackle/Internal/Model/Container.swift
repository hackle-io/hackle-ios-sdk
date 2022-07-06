import Foundation

protocol Container {
    var id: Int64 {get}
    var bucketId: Int64 {get}
    var groups: [ContainerGroup] {get}

    func findGroup(containerGroupId: Int64) -> ContainerGroup?
}

class ContainerEntity: Container {
    let id: Int64
    let bucketId: Int64
    let groups: [ContainerGroup]

    init(id: Int64, bucketId: Int64, groups: [ContainerGroup]) {
        self.id = id
        self.bucketId = bucketId
        self.groups = groups
    }

    func findGroup(containerGroupId: Int64) -> ContainerGroup? {
        groups.filter({ (groupId: Int64) -> Bool in (groupId == containerGroupId) })
    }
}
