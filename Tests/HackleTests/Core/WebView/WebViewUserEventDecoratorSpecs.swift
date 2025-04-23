//
//  WebViewUserEventDecoratorSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class WebViewUserEventDecoratorSpecs: QuickSpec {
    override func spec() {
        describe("WebViewWrapperUserEventDecorator") {
            var sut: WebViewWrapperUserEventDecorator!
            var originalUser: HackleUser!
            var originalEvent: UserEvent!
            
            beforeEach {
                sut = WebViewWrapperUserEventDecorator()
                // 가상의 User/Builder, UserEvent 생성 (실제 프로젝트에 맞게 수정)
                originalUser = HackleUser.builder()
                    .identifier(IdentifierType.id.rawValue, "user")
                    .property("age", 30)
                    .property("country", "KR")
                    .build()
                
                originalEvent = UserEvents.track("test-event", user: originalUser)
            }
            
            it("decorate(event:)는 user의 properties를 모두 clear한다") {
                let decoratedEvent = sut.decorate(event: originalEvent)
                expect(decoratedEvent.user.properties).to(beEmpty())
            }
            
            it("decorate(event:)는 user id 등 기본 정보는 유지한다") {
                let decoratedEvent = sut.decorate(event: originalEvent)
                expect(decoratedEvent.user.id).to(equal(originalUser.id))
            }
            
            it("decorate(event:)는 새로운 user 객체를 반환한다") {
                let decoratedEvent = sut.decorate(event: originalEvent)
                // user 객체 자체가 새로 생성됐는지 확인
                expect(decoratedEvent.user).toNot(beIdenticalTo(originalUser))
            }
        }
    }
}
