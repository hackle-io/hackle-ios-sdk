import Foundation

struct RemoteEvaluateContext {

    let user: HackleUser
    let operations: PropertyOperations

    var key: WorkspaceEvaluationContext.Key {
        WorkspaceEvaluationContext.keyOf(user: user)
    }

    static func of(user: HackleUser, operations: PropertyOperations) -> RemoteEvaluateContext {
        RemoteEvaluateContext(user: user, operations: operations)
    }

    static func of(user: HackleUser) -> RemoteEvaluateContext {
        of(user: user, operations: PropertyOperations.empty())
    }

    func toDto() -> RemoteEvaluateContextDto {
        RemoteEvaluateContextDto(
            user: HackleUserDto(
                identifiers: user.identifiers,
                userProperties: user.properties,
                hackleProperties: user.hackleProperties
            ),
            operations: operations.asDictionary().reduce(into: [String: [String: Any]]()) { acc, entry in
                acc[entry.key.rawValue] = entry.value
            }
        )
    }
}
