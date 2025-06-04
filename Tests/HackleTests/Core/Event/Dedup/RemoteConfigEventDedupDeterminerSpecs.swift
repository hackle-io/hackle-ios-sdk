import Foundation
import Quick
import Nimble
@testable import Hackle


class RemoteConfigEventDedupDeterminerSpecs: QuickSpec {
    override func spec() {
        it("cacheKey") {
            let repository = UserDefaultsKeyValueRepository.of(suiteName: "unittest_rc_repo_abcd1234")
            let sut = RemoteConfigEventDedupDeterminer(repository: repository, dedupInterval: -1)

            let event = UserEvents.RemoteConfig(
                insertId: "insert_id",
                timestamp: Date(),
                user: HackleUser.builder().build(),
                parameter: RemoteConfigParameter(
                    id: 42,
                    key: "rc",
                    type: .string,
                    identifierType: "id",
                    targetRules: [],
                    defaultValue: RemoteConfigParameter.Value(
                        id: 32,
                        rawValue: HackleValue(value: "default")
                    )
                ),
                valueId: 320,
                decisionReason: DecisionReason.DEFAULT_RULE,
                properties: [:],
                internalProperties: [:]
            )

            let key = sut.cacheKey(event: event)
            expect(key).to(equal("42-320-DEFAULT_RULE"))
        }
    }
}
