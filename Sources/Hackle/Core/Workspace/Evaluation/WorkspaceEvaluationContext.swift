import Foundation

struct WorkspaceEvaluationContext: WorkspaceContext {

    let workspace: WorkspaceEvaluation
    let key: Key
    let dto: WorkspaceEvaluationDto // delta 병합·재직렬화용 원본 보존
    let fullEvaluatedAt: Int64

    struct Key: Hashable {
        let identifiers: [String: String]
    }
}

extension WorkspaceEvaluationContext {

    private static let EXCLUDED: Set<String> = [IdentifierType.session.rawValue, IdentifierType.hackleDevice.rawValue]

    static func of(key: Key, dto: WorkspaceEvaluationDto, fullEvaluatedAt: Int64) -> WorkspaceEvaluationContext {
        WorkspaceEvaluationContext(
            workspace: DefaultWorkspaceEvaluation.from(dto: dto, fullEvaluatedAt: fullEvaluatedAt),
            key: key,
            dto: dto,
            fullEvaluatedAt: fullEvaluatedAt
        )
    }

    static func from(dto: WorkspaceEvaluationContextDto) -> WorkspaceEvaluationContext {
        of(key: Key(identifiers: dto.key), dto: dto.evaluation, fullEvaluatedAt: dto.fullEvaluatedAt)
    }

    static func keyOf(user: HackleUser) -> Key {
        Key(identifiers: user.identifiers.filter { it in
            !EXCLUDED.contains(it.key)
        })
    }

    static func keyOf(user: User) -> Key {
        Key(identifiers: Identifiers.from(user: user).filter { it in
            !EXCLUDED.contains(it.key)
        })
    }
}

extension WorkspaceEvaluationContext {
    func toDto() -> BaseEvaluationDto {
        BaseEvaluationDto(
            fullEvaluatedAt: fullEvaluatedAt,
            metadata: dto.metadata,
            entities: dto.results.map { it in
                EvaluateEntityDto(type: it.type, id: it.id, hash: it.hash)
            }
        )
    }
}
