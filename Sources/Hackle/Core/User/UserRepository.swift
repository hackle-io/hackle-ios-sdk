import Foundation

class UserRepository {

    private static let USER_KEY = "user"

    private let repository: KeyValueRepository

    init(repository: KeyValueRepository) {
        self.repository = repository
    }

    func get() -> User? {
        guard let data = repository.getData(key: UserRepository.USER_KEY) else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any?] else {
            Log.error("Failed to deserialize User")
            return nil
        }

        let user = User.from(json: json)
        Log.debug("User loaded: \(user)")
        return user
    }

    func set(user: User) {
        guard let data = user.toData() else {
            Log.error("Failed to serialize User.")
            return
        }
        repository.putData(key: UserRepository.USER_KEY, value: data)
        Log.debug("User saved: \(user)")
    }
}

fileprivate extension User {

    func toData() -> Data? {
        let dict: [String: Any?] = [
            "id": id,
            "userId": userId,
            "deviceId": deviceId,
            "identifiers": identifiers,
            "properties": properties
        ]
        return Json.serialize(dict)
    }

    static func from(json: [String: Any?]) -> User {
        User(
            id: json["id"] as? String,
            userId: json["userId"] as? String,
            deviceId: json["deviceId"] as? String,
            identifiers: json["identifiers"] as? [String: String] ?? [:],
            properties: json["properties"] as? [String: Any] ?? [:]
        )
    }
}
