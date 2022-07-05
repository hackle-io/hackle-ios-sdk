import Foundation

protocol ContainerGroup {
    var containerGroupId: Int64 {get}
    var experiments: [Int64] {get}
}

class ContainerGroupEntity: ContainerGroup {
    let containerGroupId: Int64
    let experiments: [Int64]

    init(containerGroupId: Int64, experiments: [Int64]) {
        self.containerGroupId = containerGroupId
        self.experiments = experiments
    }
}