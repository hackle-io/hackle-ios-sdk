import Foundation

struct WorkspaceEvaluateContext {

    let platformType: PlatformType
    let user: HackleUser
    let operations: PropertyOperations

    var key: WorkspaceEvaluationContext.Key {
        WorkspaceEvaluationContext.keyOf(user: user)
    }

    static func of(user: HackleUser, operations: PropertyOperations) -> WorkspaceEvaluateContext {
        WorkspaceEvaluateContext(platformType: .ios, user: user, operations: operations)
    }

    // Kotlin 기본 인자 대응 (D7)
    static func of(user: HackleUser) -> WorkspaceEvaluateContext {
        of(user: user, operations: PropertyOperations.empty())
    }

    func toDto() -> WorkspaceEvaluateContextDto {
        WorkspaceEvaluateContextDto(
            platformType: platformType.rawValue,
            user: HackleUserDto(
                identifiers: user.identifiers,
                userProperties: user.properties,
                hackleProperties: user.hackleProperties
            ),
            operations: operations.asDictionary().reduce(into: [String: Any]()) { acc, entry in
                acc[entry.key.rawValue] = entry.value
            }
        )
    }
}
