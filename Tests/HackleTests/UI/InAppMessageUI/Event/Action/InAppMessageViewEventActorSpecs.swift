import Foundation
@testable import Hackle
import Nimble
import Quick

class InAppMessageViewEventActorSpecs: QuickSpec {
    override class func spec() {
        describe("InAppMessageViewImpressionEventActor") {
            var sut: InAppMessageViewImpressionEventActor!
            
            beforeEach {
                sut = InAppMessageViewImpressionEventActor()
            }
            
            it("supports") {
                for type in InAppMessageViewEventType.allCases {
                    expect(sut.supports(type: type)).to(equal(type == .impression))
                }
            }
            
            describe("action") {
                it("do nothing") {
                    // given
                    let view = MockInAppMessageView()
                    let event = MockInAppMessageViewEvent(type: .impression)
                    
                    // when
                    MainActor.assumeIsolated {
                        sut.action(view: view, event: event)
                    }
                }
            }
        }
        
        describe("InAppMessageViewActionEventActor") {
            var actionHandler: MockInAppMessageActionHandler!
            var actionHandlerFactory: MockInAppMessageActionHandlerFactory!
            var sut: InAppMessageViewActionEventActor!
            
            beforeEach {
                actionHandler = MockInAppMessageActionHandler()
                actionHandlerFactory = MockInAppMessageActionHandlerFactory()
                every(actionHandlerFactory.getMock).returns(actionHandler)
                sut = InAppMessageViewActionEventActor(actionHandlerFactory: actionHandlerFactory)
            }
            
            it("supports") {
                for type in InAppMessageViewEventType.allCases {
                    expect(sut.supports(type: type)).to(equal(type == .action))
                }
            }
            
            describe("action") {
                it("when not action event then do nothing") {
                    // given
                    let view = MockInAppMessageView()
                    let event = InAppMessageViewImpressionEvent(timestamp: Date())
                    
                    // when
                    MainActor.assumeIsolated {
                        sut.action(view: view, event: event)
                    }
                    
                    // then
                    verify(exactly: 0) {
                        actionHandler.handleMock
                    }
                }
                
                it("when cannot found action handler then do nothing") {
                    // given
                    let view = MockInAppMessageView()
                    let event = InAppMessageViewActionEvent.action(timestamp: Date(), action: InAppMessage.action(), area: nil)
                    
                    // when
                    MainActor.assumeIsolated {
                        sut.action(view: view, event: event)
                    }
                    
                    // then
                    verify(exactly: 0) {
                        actionHandler.handleMock
                    }
                }
                
                it("when view is closed then do nothing") {
                    // given
                    let view = MockInAppMessageView(presented: false)
                    let event = InAppMessageViewActionEvent.action(timestamp: Date(), action: InAppMessage.action(), area: nil)
                    
                    // when
                    MainActor.assumeIsolated {
                        sut.action(view: view, event: event)
                    }
                    
                    // then
                    verify(exactly: 0) {
                        actionHandler.handleMock
                    }
                }
                
                it("when view is opened then handle event") {
                    // given
                    let view = MockInAppMessageView(presented: true)
                    let event = InAppMessageViewActionEvent.action(timestamp: Date(), action: InAppMessage.action(), area: nil)
                    
                    // when
                    MainActor.assumeIsolated {
                        sut.action(view: view, event: event)
                    }
                    
                    // then
                    verify(exactly: 1) {
                        actionHandler.handleMock
                    }
                }
            }
        }
        
        describe("InAppMessageViewCloseEventActor") {
            var sut: InAppMessageViewCloseEventActor!
            
            beforeEach {
                sut = InAppMessageViewCloseEventActor()
            }
            
            it("supports") {
                for type in InAppMessageViewEventType.allCases {
                    expect(sut.supports(type: type)).to(equal(type == .close))
                }
            }
            
            describe("action") {
                it("do nothing") {
                    // given
                    let view = MockInAppMessageView()
                    let event = MockInAppMessageViewEvent(type: .close)
                    
                    // when
                    MainActor.assumeIsolated {
                        sut.action(view: view, event: event)
                    }
                }
            }
        }
      }
}
