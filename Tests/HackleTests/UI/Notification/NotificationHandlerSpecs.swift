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
    override func spec() {
        describe("NotificationHandler") {
            var handler: NotificationHandler!
            var mockReceiver: MockNotificationDataReceiver!

            beforeEach {
                handler = NotificationHandler(dispatchQueue: DispatchQueue(label: "test.queue"))
                mockReceiver = MockNotificationDataReceiver()
                handler.setNotificationDataReceiver(receiver: mockReceiver)
            }

            it("trackPushClickEvent가 receiver.onNotificationDataReceived를 호출한다") {
                let testData = NotificationData(
                    workspaceId: 123,
                    environmentId: 456,
                    pushMessageId: 1,
                    pushMessageKey: 2,
                    pushMessageExecutionId: 3,
                    pushMessageDeliveryId: 4,
                    showForeground: true,
                    imageUrl: nil,
                    clickAction: .appOpen,
                    link: "",
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "JOURNEY",
                    debug: true
                )
                let testTimestamp = Date()

                handler.trackPushClickEvent(notificationData: testData, timestamp: testTimestamp)

                expect(mockReceiver.receivedData?.pushMessageId).to(equal(1))
                expect(mockReceiver.receivedTimestamp).to(equal(testTimestamp))
            }
            
            context("when handling a push image") {
                it("should return a nil attachment on download failure") {
                    let imageUrl = "https://faketest/notfound.jpg"

                    let notificationData = NotificationData(
                        workspaceId: 123,
                        environmentId: 456,
                        pushMessageId: 1,
                        pushMessageKey: 2,
                        pushMessageExecutionId: 3,
                        pushMessageDeliveryId: 4,
                        showForeground: true,
                        imageUrl: imageUrl,
                        clickAction: .appOpen,
                        link: "",
                        journeyId: nil,
                        journeyKey: nil,
                        journeyNodeId: nil,
                        campaignType: "JOURNEY",
                        debug: true
                    )
                    var resultAttachment: UNNotificationAttachment?
                    
                    // Act & Assert
                    waitUntil(timeout: .seconds(10)) { done in
                        handler.handlePushImage(notificationData: notificationData) { attachment in
                            resultAttachment = attachment
                            done()
                        }
                    }
                    
                    expect(resultAttachment).to(beNil())
                }
                
                it("should return a nil attachment for an invalid URL") {
                    let notificationData = NotificationData(
                        workspaceId: 123,
                        environmentId: 456,
                        pushMessageId: 1,
                        pushMessageKey: 2,
                        pushMessageExecutionId: 3,
                        pushMessageDeliveryId: 4,
                        showForeground: true,
                        imageUrl: nil,
                        clickAction: .appOpen,
                        link: "",
                        journeyId: nil,
                        journeyKey: nil,
                        journeyNodeId: nil,
                        campaignType: "JOURNEY",
                        debug: true
                    )
                    var resultAttachment: UNNotificationAttachment?
                    
                    waitUntil { done in
                        handler.handlePushImage(notificationData: notificationData) { attachment in
                            resultAttachment = attachment
                            done()
                        }
                    }
                    
                    expect(resultAttachment).to(beNil())
                }
            }
        }
    }
}
