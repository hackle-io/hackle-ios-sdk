import Foundation

protocol Container {
    var containerId: Int64 {get}
    var bucketId: Int64 {get}
    var groups: [ContainerGroup] {get}
    
    func findGroup(containerGroupId: Int64) -> ContainerGroup?
}

class ContainerEntity: Container {
    let containerId: Int64
    let bucketId: Int64
    let groups: [ContainerGroup]
    
    init(containerId: Int64, bucketId: Int64, groups: [ContainerGroup]) {
        self.containerId = containerId
        self.bucketId = bucketId
        self.groups = groups
    }
    
    func findGroup(containerGroupId: Int64) -> ContainerGroup? {
        groups.filter({ (groupId: Int64) -> Bool in (groupId == containerGroupId) })
    }
}
