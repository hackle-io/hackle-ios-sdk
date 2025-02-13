import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultConditionMatcherFactorySpecs: QuickSpec {
    override func spec() {
        let sut = DefaultConditionMatcherFactory(evaluator: MockEvaluator(), clock: SystemClock.shared)
        it("getMatcher") {
            expect(sut.getMatcher(.userId)).to(beAnInstanceOf(UserConditionMatcher.self))
            expect(sut.getMatcher(.userProperty)).to(beAnInstanceOf(UserConditionMatcher.self))
            expect(sut.getMatcher(.hackleProperty)).to(beAnInstanceOf(UserConditionMatcher.self))
            expect(sut.getMatcher(.eventProperty)).to(beAnInstanceOf(EventConditionMatcher.self))
            expect(sut.getMatcher(.segment)).to(beAnInstanceOf(SegmentConditionMatcher.self))
            expect(sut.getMatcher(.abTest)).to(beAnInstanceOf(ExperimentConditionMatcher.self))
            expect(sut.getMatcher(.featureFlag)).to(beAnInstanceOf(ExperimentConditionMatcher.self))
            expect(sut.getMatcher(.cohort)).to(beAnInstanceOf(CohortConditionMatcher.self))
            expect(sut.getMatcher(.numberOfEventsInDays)).to(beAnInstanceOf(TargetEventConditionMatcher.self))
            expect(sut.getMatcher(.numberOfEventsWithPropertyInDays)).to(beAnInstanceOf(TargetEventConditionMatcher.self))
        }
    }
}
