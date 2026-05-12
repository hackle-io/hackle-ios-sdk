import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageViewJavascriptBridgeSpecs: QuickSpec {
    override class func spec() {
        let sdkKey = "test_sdk_key"
        let viewId = "view-id-1"

        func bridge(event: Event) -> InAppMessageViewJavascriptBridge {
            let invocator = DefaultHackleInvocator(processor: MockInvocationProcessor())
            return InAppMessageViewJavascriptBridge(
                invocator: invocator,
                sdkKey: sdkKey,
                viewId: viewId,
                triggerEvent: event
            )
        }

        describe("getInAppMessageTriggerEvent property in source") {
            it("emits key-only JSON when value and properties are nil") {
                let event = Event.builder("hello").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("getInAppMessageTriggerEvent: function() { return '{\"key\":\"hello\"}' }"))
            }

            it("includes value when present and finite") {
                let event = Event.builder("price").value(1.5).build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("\"value\":1.5"))
            }

            it("includes properties when present") {
                let event = Event.builder("buy").property("plan", "premium").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("\"properties\":"))
                expect(sut.source).to(contain("\"plan\":\"premium\""))
            }

            it("omits value key when value is nil") {
                let event = Event.builder("hello").build()
                let sut = bridge(event: event)
                expect(sut.source).toNot(contain("\"value\""))
            }

            it("omits value key when value is NaN") {
                let event = Event.builder("hello").value(Double.nan).build()
                let sut = bridge(event: event)
                expect(sut.source).toNot(contain("\"value\""))
            }

            it("omits value key when value is +Infinity") {
                let event = Event.builder("hello").value(Double.infinity).build()
                let sut = bridge(event: event)
                expect(sut.source).toNot(contain("\"value\""))
            }

            it("omits value key when value is -Infinity") {
                let event = Event.builder("hello").value(-Double.infinity).build()
                let sut = bridge(event: event)
                expect(sut.source).toNot(contain("\"value\""))
            }

            it("omits properties key when properties dict is nil") {
                let event = Event.builder("hello").build()
                let sut = bridge(event: event)
                expect(sut.source).toNot(contain("\"properties\""))
            }

            it("escapes single quote in property value as backslash-quote") {
                let event = Event.builder("hello").property("name", "John's").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("John\\'s"))
            }

            it("escapes backslash in property value as double-backslash") {
                let event = Event.builder("hello").property("path", "C:\\Users").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("C:\\\\\\\\Users"))
            }

            it("returns empty string when JSON serialization fails") {
                let event = Event(key: "hello", value: nil, properties: ["badDate": Date()])
                let sut = bridge(event: event)
                expect(sut.source).to(contain("getInAppMessageTriggerEvent: function() { return '' }"))
                expect(sut.source).toNot(contain("getInAppMessageTriggerEvent: function() { return '{"))
            }

            it("preserves Unicode characters in property value") {
                let event = Event.builder("hello").property("name", "안녕😀").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("\"name\":\"안녕😀\""))
            }

            it("emits empty event key as JSON string") {
                let event = Event.builder("").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("getInAppMessageTriggerEvent: function() { return '{\"key\":\"\"}' }"))
            }

            it("escapes single quote in property key") {
                let event = Event.builder("hello").property("it's", "x").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("\"it\\'s\""))
            }

            it("escapes backslash in property key") {
                let event = Event.builder("hello").property("a\\b", "x").build()
                let sut = bridge(event: event)
                expect(sut.source).to(contain("\"a\\\\\\\\b\""))
            }

            it("emits integer-valued Double without decimal point") {
                let event = Event.builder("count").value(1.0).build()
                let sut = bridge(event: event)
                expect(sut.source).toNot(contain("\"value\":1.0"))
                expect(sut.source).to(contain("\"value\":1"))
            }
        }
    }
}
