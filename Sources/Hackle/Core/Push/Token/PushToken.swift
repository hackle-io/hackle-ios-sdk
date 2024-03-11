import Foundation

struct PushToken: Equatable {
    let platformType: PushPlatformType
    let providerType: PushProviderType
    let value: String
}

extension PushToken {
    static func of(value: Data) -> PushToken {
        PushToken(platformType: .ios, providerType: .apn, value: value.hexString())
    }
}
