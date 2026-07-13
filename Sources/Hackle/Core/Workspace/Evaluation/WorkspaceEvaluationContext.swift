import Foundation

struct WorkspaceEvaluationContext: WorkspaceContext {

    let workspace: WorkspaceEvaluation
    let key: Key
    let dto: WorkspaceEvaluationDto // delta 병합·재직렬화용 원본 보존

    struct Key: Hashable {
        let identifiers: [String: String]
    }
}

extension WorkspaceEvaluationContext {

    private static let EXCLUDED: Set<String> = [IdentifierType.session.rawValue, IdentifierType.hackleDevice.rawValue]

    static func of(key: Key, dto: WorkspaceEvaluationDto) -> WorkspaceEvaluationContext {
        WorkspaceEvaluationContext(
            workspace: DefaultWorkspaceEvaluation.from(dto: dto),
            key: key,
            dto: dto
        )
    }

    static func from(dto: WorkspaceEvaluationRecordDto) -> WorkspaceEvaluationContext {
        of(key: Key(identifiers: dto.key), dto: dto.evaluation)
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
