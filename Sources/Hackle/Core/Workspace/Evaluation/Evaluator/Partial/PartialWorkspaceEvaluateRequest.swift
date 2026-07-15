import Foundation

class PartialWorkspaceEvaluateRequest: WorkspaceEvaluateRequest {

    let context: RemoteEvaluateContext
    let entities: [Entity]

    init(context: RemoteEvaluateContext, entities: [Entity]) {
        self.context = context
        self.entities = entities
    }
}

extension PartialWorkspaceEvaluateRequest {
    func toDto() -> EntityEvaluateRequestDto {
        EntityEvaluateRequestDto(
            context: context.toDto(),
            entities: entities.map { it in
                EntityDto(type: it.serviceType.rawValue, id: it.id)
            }
        )
    }
}
