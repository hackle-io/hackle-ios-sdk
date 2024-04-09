import Foundation
import Quick
import Nimble
@testable import Hackle

class DelegatingUserEventDedupDeterminerSpecs: QuickSpec {
    override func spec() {
        it("determiner") {
            // given
            let sut = DelegatingUserEventDedupDeterminer(determiners: [
                RemoteConfigDeterminerStub(dedupTarget: false),
                ExposureDeterminerStub(dedupTarget: true),
                RemoteConfigDeterminerStub(dedupTarget: false)
            ])

            let event = UserEvents.Exposure(
                insertId: "insertId",
                timestamp: Date(),
                user: HackleUser.builder().build(),
                experiment: MockExperiment(),
                variationId: 14,
                variationKey: "A",
                decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                properties: [:]
            )


            // when
            let actual = sut.isDedupTarget(event: event)

            // then
            expect(actual).to(equal(true))
        }

        it("empty") {
            // given
            let sut = DelegatingUserEventDedupDeterminer(determiners: [])

            let event = UserEvents.Exposure(
                insertId: "insertId",
                timestamp: Date(),
                user: HackleUser.builder().build(),
                experiment: MockExperiment(),
                variationId: 14,
                variationKey: "A",
                decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                properties: [:]
            )


            // when
            let actual = sut.isDedupTarget(event: event)

            // then
            expect(actual).to(equal(false))
        }

        it("not supported") {
            // given
            let sut = DelegatingUserEventDedupDeterminer(determiners: [
                RemoteConfigDeterminerStub(dedupTarget: true),
                RemoteConfigDeterminerStub(dedupTarget: true)
            ])

            let event = UserEvents.Exposure(
                insertId: "insertId",
                timestamp: Date(),
                user: HackleUser.builder().build(),
                experiment: MockExperiment(),
                variationId: 14,
                variationKey: "A",
                decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                properties: [:]
            )


            // when
            let actual = sut.isDedupTarget(event: event)

            // then
            expect(actual).to(equal(false))
        }
    }
}

private class ExposureDeterminerStub: CachedUserEventDedupDeterminer {
    typealias Event = UserEvents.Exposure

    private let dedupTarget: Bool

    init(dedupTarget: Bool) {
        self.dedupTarget = dedupTarget
    }

    func isDedupTarget(event: UserEvent) -> Bool {
        dedupTarget
    }

    func cache() -> UserEventDedupCache {
        fatalError("cache() has not been implemented")
    }

    func cacheKey(event: Event) -> String {
        fatalError("cacheKey(event:) has not been implemented")
    }
}

private class RemoteConfigDeterminerStub: CachedUserEventDedupDeterminer {
    typealias Event = UserEvents.RemoteConfig

    private let dedupTarget: Bool

    init(dedupTarget: Bool) {
        self.dedupTarget = dedupTarget
    }

    func isDedupTarget(event: UserEvent) -> Bool {
        dedupTarget
    }

    func cache() -> UserEventDedupCache {
        fatalError("cache() has not been implemented")
    }

    func cacheKey(event: Event) -> String {
        fatalError("cacheKey(event:) has not been implemented")
    }
}