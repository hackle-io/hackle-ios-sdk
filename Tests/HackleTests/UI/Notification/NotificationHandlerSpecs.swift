//
//  NotificationHandlerSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Quick
import Nimble
@testable import Hackle
import Foundation
import UIKit

// Mock 객체
class MockNotificationDataReceiver: NotificationDataReceiver {
    var receivedData: NotificationData?
    var receivedTimestamp: Date?
    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        receivedData = data
        receivedTimestamp = timestamp
    }
}

// NotificationHandler 테스트
class NotificationHandlerSpecs: QuickSpec {
    override class func spec() {
        describe("NotificationHandler") {
            var handler: NotificationHandler!
            var mockReceiver: MockNotificationDataReceiver!
            var mockUrlHandler: MockUrlHandler!

            beforeEach {
                mockUrlHandler = MockUrlHandler()
                mockUrlHandler.reset()
                handler = NotificationHandler(
                    dispatchQueue: DispatchQueue(label: "test.queue"),
                    urlHandler: HackleUrlHandler(handler: mockUrlHandler)
                )
                mockReceiver = MockNotificationDataReceiver()
                handler.setNotificationDataReceiver(receiver: mockReceiver)
            }

            it("trackPushClickEvent가 receiver.onNotificationDataReceived를 호출한다") {
                let testData = mockNotificationData()
                let testTimestamp = Date()

                handler.trackPushClickEvent(notificationData: testData, timestamp: testTimestamp)

                expect(mockReceiver.receivedData?.pushMessageId).to(equal(1))
                expect(mockReceiver.receivedTimestamp).to(equal(testTimestamp))
            }

            it("handlePushClickAction이 deepLink이고 https scheme이면 urlHandler.open을 호출한다") {
                let testData = mockNotificationData(
                    clickAction: .deepLink,
                    link: "https://www.hackle.io"
                )

                handler.handlePushClickAction(notificationData: testData)

                // toEventually로 비동기 Task 완료 대기
                expect(mockUrlHandler.openCallCount).toEventually(equal(1), timeout: .seconds(5))
                expect(mockUrlHandler.lastOpenedUrl?.absoluteString).to(equal("https://www.hackle.io"))
            }

            it("handlePushClickAction이 deepLink이고 custom scheme이면 urlHandler.open을 호출한다") {
                let testData = mockNotificationData(
                    clickAction: .deepLink,
                    link: "hackleapp://www.hackle.io"
                )

                handler.handlePushClickAction(notificationData: testData)

                // toEventually로 비동기 Task 완료 대기
                expect(mockUrlHandler.openCallCount).toEventually(equal(1), timeout: .seconds(5))
                expect(mockUrlHandler.lastOpenedUrl?.absoluteString).to(equal("hackleapp://www.hackle.io"))
            }

            it("handlePushClickAction이 appOpen일 때 urlHandler.open을 호출하지 않는다") {
                let testData = mockNotificationData(
                    clickAction: .appOpen,
                    link: ""
                )

                handler.handlePushClickAction(notificationData: testData)

                // 비동기 작업이 실행될 시간을 준 후 호출되지 않음을 확인
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                expect(mockUrlHandler.openCallCount).to(equal(0))
            }

            it("handlePushClickAction에서 link가 비어있으면 urlHandler.open을 호출하지 않는다") {
                let testData = mockNotificationData(
                    clickAction: .deepLink,
                    link: ""
                )

                handler.handlePushClickAction(notificationData: testData)

                // 비동기 작업이 실행될 시간을 준 후 호출되지 않음을 확인
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                expect(mockUrlHandler.openCallCount).to(equal(0))
            }
            
            it("delegate가 있으면 deepLink 클릭 시 delegate만 호출한다") {
                let localUrlHandler = MockUrlHandler()
                let hackleUrlHandler = HackleUrlHandler(handler: localUrlHandler)
                let delegate = MockHackleDelegate()
                hackleUrlHandler.setDelegate(delegate)
                let delegateHandler = NotificationHandler(
                    dispatchQueue: DispatchQueue(label: "test.delegate.queue"),
                    urlHandler: hackleUrlHandler
                )

                delegateHandler.handlePushClickAction(
                    notificationData: mockNotificationData(clickAction: .deepLink, link: "myapp://home")
                )

                expect(delegate.contexts.count).toEventually(equal(1), timeout: .seconds(5))
                expect(delegate.contexts[0].url.absoluteString).to(equal("myapp://home"))
                expect(delegate.contexts[0].channel).to(equal(.push))
                expect(localUrlHandler.openCallCount).to(equal(0))
            }

            it("delegate가 있어도 appOpen이면 호출하지 않는다") {
                let localUrlHandler = MockUrlHandler()
                let hackleUrlHandler = HackleUrlHandler(handler: localUrlHandler)
                let delegate = MockHackleDelegate()
                hackleUrlHandler.setDelegate(delegate)
                let delegateHandler = NotificationHandler(
                    dispatchQueue: DispatchQueue(label: "test.delegate.appopen.queue"),
                    urlHandler: hackleUrlHandler
                )

                delegateHandler.handlePushClickAction(
                    notificationData: mockNotificationData(clickAction: .appOpen, link: "")
                )

                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                expect(delegate.contexts.isEmpty).to(beTrue())
            }

            func mockNotificationData(
                imageUrl: String? = nil,
                clickAction: NotificationClickAction = .appOpen,
                link: String = ""
            ) -> NotificationData {
                NotificationData(
                    workspaceId: 123,
                    environmentId: 456,
                    pushMessageId: 1,
                    pushMessageKey: 2,
                    pushMessageExecutionId: 3,
                    pushMessageDeliveryId: 4,
                    showForeground: true,
                    imageUrl: imageUrl,
                    clickAction: clickAction,
                    link: link,
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "JOURNEY",
                    debug: true
                )
            }
        }
    }
}
