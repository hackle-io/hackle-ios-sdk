import Foundation

protocol Container {
    var id: Int64 {get}
    var bucketId: Int64 {get}
    var groups: [ContainerGroup] {get}

    func findGroupOrNil(containerGroupId: Int64) -> ContainerGroup?
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

    func findGroupOrNil(containerGroupId: Int64) -> ContainerGroup? {
        groups.filter({ (id: Int64) -> Bool in return id == containerGroupId })
    }
}

