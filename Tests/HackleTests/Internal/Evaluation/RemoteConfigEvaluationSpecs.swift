import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class RemoteConfigEvaluationSpecs: QuickSpec {
    override func spec() {

        it("of") {
            let propertiesBuilder = PropertiesBuilder()
            propertiesBuilder.add("hello", "world")
            let actual = RemoteConfigEvaluation.of(
                valueId: 42,
                value: HackleValue.string("remote"),
                reason: DecisionReason.DEFAULT_RULE,
                propertiesBuilder: propertiesBuilder
            )

            expect(actual.valueId) == 42
            expect(actual.value) == HackleValue.string("remote")
            expect(actual.reason) == "DEFAULT_RULE"
            expect(actual.properties["hello"] as? String) == "world"
            expect(actual.properties["returnValue"] as? String) == "remote"
        }
    }
}