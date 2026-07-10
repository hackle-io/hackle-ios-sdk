import Foundation

struct RemoteUserContext: UserContext {

    let user: User // only identifiers

    private init(user: User) {
        self.user = user
    }

    static func from(user: User) -> RemoteUserContext {
        RemoteUserContext(user: sanitize(user: user))
    }

    // `User.toBuilder().properties([:])`는 HackleUserBuilder.properties(_:)가 내부적으로
    // PropertiesBuilder.add(merge)를 호출하는 "추가" 방식이라 빈 dict를 넘겨도 기존 properties가
    // 지워지지 않는다 (android toBuilder().properties(emptyMap())의 replace semantics와 다름 — Read로 확인됨).
    // 그래서 fresh builder에 id/userId/deviceId/identifiers만 이관해 properties를 비운다.
    private static func sanitize(user: User) -> User {
        if user.properties.isEmpty {
            return user
        }
        return HackleUserBuilder()
            .id(user.id)
            .userId(user.userId)
            .deviceId(user.deviceId)
            .identifiers(user.identifiers)
            .build()
    }
}

extension RemoteUserContext {
    var evaluationKey: WorkspaceEvaluationContext.Key {
        WorkspaceEvaluationContext.keyOf(user: user)
    }
}
