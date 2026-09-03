import Foundation
@testable import Hackle
import Nimble
import Quick

class InvocationHandlerSpecs: QuickSpec {
    override class func spec() {
        var core: MockHackleAppCore!
        
        beforeEach {
            core = MockHackleAppCore()
        }
        
        func reqest(command: InvocationCommand, parameters: [String: Any] = [:]) -> InvocationRequest {
            return InvocationRequest(command: command, parameters: parameters, browserProperties: [:])
        }
        
        describe("mutation 핸들러의 완료 Task") {
            it("user mutation 핸들러는 core의 완료 Task를 응답에 싣는다") {
                let cases: [(String, any InvocationHandler, InvocationRequest)] = [
                    ("setUser", SetUserInvocationHandler(core: core), reqest(command: .setUser, parameters: ["user": ["id": "42"]])),
                    ("setUserId", SetUserIdInvocationHandler(core: core), reqest(command: .setUserId, parameters: ["userId": "42"])),
                    ("setDeviceId", SetDeviceIdInvocationHandler(core: core), reqest(command: .setDeviceId, parameters: ["deviceId": "42"])),
                    ("resetUser", ResetUserInvocationHandler(core: core), reqest(command: .resetUser)),
                    ("setUserProperty", SetUserPropertyInvocationHandler(core: core), reqest(command: .setUserProperty, parameters: ["key": "age", "value": 42])),
                    // `as [String: Any]`는 필수다 — PropertyOperationsDto([String: [String: Any]])로 캐스팅되어야 한다
                    ("updateUserProperties", UpdateUserPropertiesInvocationHandler(core: core), reqest(command: .updateUserProperties, parameters: ["operations": ["$set": ["age": 42] as [String: Any]]])),
                ]

                for (name, handler, request) in cases {
                    let response = try handler.handle(request: request)
                    expect(response.isSuccess).to(equal(true), description: name)
                    expect(response.task).toNot(beNil(), description: name)
                }
            }

            it("mutation이 아닌 핸들러의 응답에는 완료 Task가 없다") {
                let track = try TrackInvocationHandler(core: core).handle(request: reqest(command: .track, parameters: ["event": "test_event"]))
                expect(track.isSuccess) == true
                expect(track.task).to(beNil())

                let screen = try SetCurrentScreenInvocationHandler(core: core).handle(
                    request: reqest(command: .setCurrentScreen, parameters: ["screenName": "home", "className": "HomeVC"])
                )
                expect(screen.isSuccess) == true
                expect(screen.task).to(beNil())
            }
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
                    expect(actual.data?["id"] as? String).to(equal("42"))
                }

                it("when current view exists then serializes to success json") {
                    // given
                    let view = MockInAppMessageView(id: "42")
                    core.currentInAppMessageView = view
                    let request = reqest(command: .getCurrentInAppMessageView)

                    // when
                    let actual = try sut.handle(request: request).toJsonString()

                    // then
                    expect(actual).to(contain("\"success\":true"))
                    expect(actual).to(contain("\"id\":\"42\""))
                    expect(actual).to(contain("\"inAppMessage\""))
                    expect(actual).toNot(contain("Error occurs while parsing response."))
                }
            }
        }
        
        describe("CloseInAppMessageViewInvocationHandler") {
            MainActor.assumeIsolated {
                var sut: CloseInAppMessageViewInvocationHandler!
                
                beforeEach {
                    sut = CloseInAppMessageViewInvocationHandler(core: core)
                }
                
                it("when parameters viewId is null then throws") {
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
                    let context = InAppMessageEntity.context()
                    let view = MockInAppMessageView(id: "42", context: context, presented: true)
                    every(core.getInAppMessageViewRef).returns(view)
                    
                    let eventProcessor = MockInAppMessageViewEventProcessor()
                    let ui = HackleInAppMessageUI(clock: SystemClock.shared, eventProcessor: eventProcessor, htmlContentResolverFactory: MockInAppMessageHtmlContentResolverFactory())
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
                    let context = InAppMessageEntity.context()
                    let view = MockInAppMessageView(id: "42", context: context, presented: true)
                    every(core.getInAppMessageViewRef).returns(view)
                    
                    let eventProcessor = MockInAppMessageViewEventProcessor()
                    let ui = HackleInAppMessageUI(clock: SystemClock.shared, eventProcessor: eventProcessor, htmlContentResolverFactory: MockInAppMessageHtmlContentResolverFactory())
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
