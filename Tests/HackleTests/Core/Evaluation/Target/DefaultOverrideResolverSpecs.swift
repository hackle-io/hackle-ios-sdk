import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class DefaultOverrideResolverSpecs: QuickSpec {
    override func spec() {

        var manualOverrideStorage: ManualOverrideStorageStub!
        var targetMatcher: TargetMatcherStub!
        var actionResolver: MockActionResolver!
        var sut: DefaultOverrideResolver!

        var context: EvaluatorContext!

        beforeEach {
            targetMatcher = TargetMatcherStub()
            actionResolver = MockActionResolver()
            manualOverrideStorage = ManualOverrideStorageStub()
            sut = DefaultOverrideResolver(manualOverrideStorage: manualOverrideStorage, targetMatcher: targetMatcher, actionResolver: actionResolver)
            context = Evaluators.context()
        }

        it("manual override 를 가장 먼저 확인한다") {
            let variation = MockVariation()
            manualOverrideStorage.returns = variation
            let request = experimentRequest()

            let actual = try sut.resolveOrNil(request: request, context: context)

            expect(actual).to(beIdenticalTo(variation))
        }

        it("identifierType에 해당하는 식별자가 없으면 segmentOverride를 평가한다") {
            // given
            let experiment = MockExperiment(
                identifierType: "customId",
                userOverrides: ["test_id": 42],
                segmentOverrides: [userSegment(isMatch: true)]
            )
            let variationByUserOverride = MockVariation()
            every(experiment.getVariationByIdOrNilMock).returns(variationByUserOverride)

            let variationBySegmentOverride = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variationBySegmentOverride)

            let user = HackleUser.of(
                user: Hackle.user(id: "test_id"),
                hackleProperties: [String: Any]()
            )

            let request = experimentRequest(user: user, experiment: experiment)

            // when
            let actual = try sut.resolveOrNil(request: request, context: context)

            // then
            expect(actual).to(beIdenticalTo(variationBySegmentOverride))
        }

        it("identifierType에 해당하는 식별자가 override되어 있지않으면 segmentOverride를 평가한다") {
            // given
            let experiment = MockExperiment(
                identifierType: "$id",
                userOverrides: ["test_id_123456789": 42],
                segmentOverrides: [userSegment(isMatch: true)]
            )
            let variationByUserOverride = MockVariation()
            every(experiment.getVariationByIdOrNilMock).returns(variationByUserOverride)

            let variationBySegmentOverride = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variationBySegmentOverride)

            let user = HackleUser.of(
                user: Hackle.user(id: "test_id"),
                hackleProperties: [String: Any]()
            )

            let request = experimentRequest(user: user, experiment: experiment)

            // when
            let actual = try sut.resolveOrNil(request: request, context: context)

            // then
            expect(actual).to(beIdenticalTo(variationBySegmentOverride))
        }

        it("identifierType에 해당하는 식별자로 override되어있는 variation을 리턴한다") {
            // given
            let experiment = MockExperiment(
                identifierType: "$id",
                userOverrides: ["test_id": 42],
                segmentOverrides: [userSegment(isMatch: true)]
            )
            let variationByUserOverride = MockVariation()
            every(experiment.getVariationByIdOrNilMock).returns(variationByUserOverride)

            let variationBySegmentOverride = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variationBySegmentOverride)

            let user = HackleUser.of(
                user: Hackle.user(id: "test_id"),
                hackleProperties: [String: Any]()
            )

            let request = experimentRequest(user: user, experiment: experiment)

            // when
            let actual = try sut.resolveOrNil(request: request, context: context)

            // then
            expect(actual).to(beIdenticalTo(variationByUserOverride))
        }

        it("userOverride도 되어있지않고 segmentOverride도 되어있지 않으면 nil 리턴") {
            // given
            let experiment = MockExperiment(
                identifierType: "$id",
                userOverrides: ["test_id_123456789": 42],
                segmentOverrides: [userSegment(isMatch: false)]
            )
            let variationByUserOverride = MockVariation()
            every(experiment.getVariationByIdOrNilMock).returns(variationByUserOverride)

            let variationBySegmentOverride = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variationBySegmentOverride)

            let user = HackleUser.of(
                user: Hackle.user(id: "test_id"),
                hackleProperties: [String: Any]()
            )

            let request = experimentRequest(user: user, experiment: experiment)

            // when
            let actual = try sut.resolveOrNil(request: request, context: context)

            // then
            expect(actual).to(beNil())
        }


        it("userOverride 가 없으면 segmentOverride 를 확인한다") {
            // given
            let experiment = MockExperiment(
                identifierType: "$id",
                userOverrides: ["test_id_123456789": 42],
                segmentOverrides: [userSegment(isMatch: true)]
            )
            let variationByUserOverride = MockVariation()
            every(experiment.getVariationByIdOrNilMock).returns(variationByUserOverride)

            let variationBySegmentOverride = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variationBySegmentOverride)

            let user = HackleUser.of(
                user: Hackle.user(id: "test_id"),
                hackleProperties: [String: Any]()
            )

            let request = experimentRequest(user: user, experiment: experiment)

            // when
            let actual = try sut.resolveOrNil(request: request, context: context)

            // then
            expect(actual).to(beIdenticalTo(variationBySegmentOverride))
        }

        it("userOverride 는 첫번째로 매칭된 rule 로 평가한다") {
            // given
            let experiment = MockExperiment(
                segmentOverrides: [
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: true),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                ]
            )
            let variation = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variation)

            let user = HackleUser.of(userId: "user_01")

            let request = experimentRequest(user: user, experiment: experiment)

            // when
            let actual = try sut.resolveOrNil(request: request, context: context)

            // then
            expect(actual).to(beIdenticalTo(variation))
            expect(targetMatcher.callCount) == 4
        }

        it("override 되어 있지 않으면 nil 을 리턴한다") {
            // given
            let experiment = MockExperiment(
                userOverrides: [
                    "user_01": 42
                ],
                segmentOverrides: [
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                ]
            )

            let user = HackleUser.of(userId: "user_02")

            let request = experimentRequest(user: user, experiment: experiment)

            // when
            let actual = try sut.resolveOrNil(request: request, context: context)

            // then
            expect(actual).to(beNil())
        }

        func userSegment(isMatch: Bool) -> TargetRule {
            let targetRule = MockTargetRule()
            targetMatcher.addResult(target: targetRule.target, isMatch: isMatch)
            return targetRule
        }
    }

    private class TargetMatcherStub: TargetMatcher {

        private var matches = [(Target, Bool)]()
        var callCount = 0

        func matches(request: EvaluatorRequest, context: EvaluatorContext, target: Target) throws -> Bool {
            callCount = callCount + 1
            guard let match = matches.first(where: { $0.0 === target }) else {
                throw HackleError.error("error")
            }
            return match.1
        }

        func addResult(target: Target, isMatch: Bool) {
            matches.append((target, isMatch))
        }
    }

    private class ManualOverrideStorageStub: ManualOverrideStorage {

        var returns: Variation? = nil

        func get(experiment: Experiment, user: HackleUser) -> Variation? {
            returns
        }
    }
}
