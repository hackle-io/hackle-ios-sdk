import Foundation

protocol Entity {
    var serviceType: ServiceType { get }
    var id: Int64 { get }
}

struct EntityKey: Hashable {
    let serviceType: ServiceType
    let id: Int64
}

extension Entity {
    var entityKey: EntityKey {
        EntityKey(serviceType: serviceType, id: id)
    }
}

struct DefaultEntity: Entity {
    let serviceType: ServiceType
    let id: Int64
}
