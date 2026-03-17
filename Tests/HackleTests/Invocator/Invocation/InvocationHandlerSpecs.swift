import Foundation
@testable import Hackle
import Nimble
import Quick

class InvocationHandlerSpecs: QuickSpec {
    override func spec() {
        var core: MockHackleAppCore!
        
        beforeEach {
            core = MockHackleAppCore()
        }
        
        func reqest(command: InvocationCommand, parameters: [String: Any] = [:]) -> InvocationRequest {
            return InvocationRequest(command: command, parameters: parameters, browserProperties: [:])
        }
        
        describe("GetCurrentInAppMessageViewInvocationHandler") {
            MainActor.assumeIsolated {
                var sut: GetCurrentInAppMessageViewInvocationHandler!
                
                beforeEach {
                    sut = GetCurrentInAppMessageViewInvocationHandler(core: core)
                }
                
                it("when current view does not exists then returns null") {
                    // given
                    core.currentInAppMessageView = nil
                    let request = reqest(command: .getCurrentInAppMessageView)
                    
                    // when
                    let actual = try sut.invoke(request: request)
                    
                    // then
                    expect(actual.isSuccess).to(equal(true))
                    expect(actual.data).to(beNil())
                }
                
                it("when current view exists then return that view") {
                    // given
                    let view = MockInAppMessageView(id: "42")
                    core.currentInAppMessageView = view
                    let request = reqest(command: .getCurrentInAppMessageView)
                    
                    // when
                    let actual = try sut.invoke(request: request)
                    
                    // then
                    expect(actual.isSuccess).to(equal(true))
                    expect(actual.data).toNot(beNil())
                    expect(actual.data?.id).to(equal("42"))
                }
            }
        }
        
        describe("CloseInAppMessageViewInvocationHandler") {
            MainActor.assumeIsolated {
                var sut: CloseInAppMessageViewInvocationHandler!
                
                beforeEach {
                    sut = CloseInAppMessageViewInvocationHandler(core: core)
                }
                
                it("when parameters viewId is null then throws error") {
                    let request = reqest(command: .closeInAppMessageView, parameters: [:])
                    expect(try sut.invoke(request: request)).to(throwError())
                }
                
                it("when not found view for view Id then do nothing") {
                    // given
                    every(core.getInAppMessageViewRef).returns(nil)
                    let request = reqest(command: .closeInAppMessageView, parameters: ["viewId": "view-id"])
                    
                    // when
                    let actual = try sut.invoke(request: request)
                    
                    // then
                    expect(actual.isSuccess).to(equal(true))
                    expect(actual.data).to(beNil())
                }
                
                it("when view is exists then close that view") {
                    // given
                    let view = MockInAppMessageView(presented: true)
                    every(core.getInAppMessageViewRef).returns(view)
                    
                    let request = reqest(command: .closeInAppMessageView, parameters: ["viewId": "view-id"])
                    
                    // when
                    let actual = try sut.invoke(request: request)
                    
                    // then
                    expect(actual.isSuccess).to(equal(true))
                    expect(actual.data).to(beNil())
                    expect(view.presented).to(equal(false))
                }
            }
        }
        
        describe("HandleInAppMessageViewInvocationHandler") {
            MainActor.assumeIsolated {
                var sut: HandleInAppMessageViewInvocationHandler!
                
                beforeEach {
                    sut = HandleInAppMessageViewInvocationHandler(core: core)
                }
                
                it("when not found view for viewId then do nothing") {
                    // given
                    every(core.getInAppMessageViewRef).returns(nil)
                    let request = reqest(command: .closeInAppMessageView, parameters: parameters(viewId: "view-id"))
                    
                    // when
                    let actual = try sut.invoke(request: request)
                    
                    // then
                    expect(actual.isSuccess).to(equal(true))
                    expect(actual.data).to(beNil())
                }
                
                it("when view is exists then handle event") {
                    // given
                    let context = InAppMessage.context()
                    let view = MockInAppMessageView(id: "42", context: context, presented: true)
                    every(core.getInAppMessageViewRef).returns(view)
                    
                    let eventProcessor = MockInAppMessageViewEventProcessor()
                    let ui = HackleInAppMessageUI(clock: SystemClock.shared, eventProcessor: eventProcessor)
                    let controller = HackleInAppMessageUI.ViewController(ui: ui, context: context, messageView: view)
                    controller.viewDidAppear(false)
                    
                    let request = reqest(command: .closeInAppMessageView, parameters: parameters(viewId: "view-id"))
                    
                    // when
                    let actual = try sut.invoke(request: request)
                    
                    // then
                    expect(actual.isSuccess).to(equal(true))
                    expect(actual.data).to(beNil())
                
                    verify(exactly: 1) {
                        eventProcessor.processMock
                    }
                    expect(eventProcessor.processMock.firstInvokation().arguments.0).to(beIdenticalTo(view))
                    expect(eventProcessor.processMock.firstInvokation().arguments.2).to(equal([.track, .action]))
                }
                
                it("unsupported InAppMessageViewEventType") {
                    let context = InAppMessage.context()
                    let view = MockInAppMessageView(id: "42", context: context, presented: true)
                    every(core.getInAppMessageViewRef).returns(view)
                    
                    let eventProcessor = MockInAppMessageViewEventProcessor()
                    let ui = HackleInAppMessageUI(clock: SystemClock.shared, eventProcessor: eventProcessor)
                    let controller = HackleInAppMessageUI.ViewController(ui: ui, context: context, messageView: view)
                    controller.viewDidAppear(false)
                    
                    for eventType in InAppMessageViewEventType.allCases.filter({ $0 != .action }) {
                        let request = reqest(command: .closeInAppMessageView, parameters: parameters(viewId: "view-id", eventType: eventType.rawValue))
                        
                        expect(try sut.invoke(request: request)).to(throwError())
                    }
                }
            }
            
            func parameters(
                viewId: String,
                handleTypes: [String] = ["TRACK", "ACTION"],
                eventType: String = "ACTION",
                action: InAppMessageActionDto? = InAppMessageActionDto(
                    behavior: "CLICK",
                    type: "LINK_AND_CLOSE",
                    value: "https://hackle.io"
                ),
                element: InAppMessageElementDto? = InAppMessageElementDto(
                    elementId: "element-id",
                    area: nil
                )
            ) -> [String: Any] {
                let dto = HandleInAppMessageViewInvocationDto(
                    viewId: viewId,
                    handleTypes: handleTypes,
                    event: InAppMessageViewEventDto(
                        type: eventType,
                        action: action,
                        element: element
                    )
                )
                let json = String(data: try! JSONEncoder().encode(dto), encoding: .utf8)!
                return json.jsonObject()!
            }
        }
    }
}
