import Foundation

protocol ContainerGroup {
    var id: Int64 {get}
    var experiments: [Int64] {get}
}

class ContainerGroupEntity: ContainerGroup {
    let id: Int64
    let experiments: [Int64]

    init(id: Int64, experiments: [Int64]) {
        self.id = id
        self.experiments = experiments
    }
}
