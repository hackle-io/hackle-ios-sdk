//
//  NotificationDataReceiverSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Quick
import Nimble
@testable import Hackle
import Foundation

class DefaultNotificationDataReceiverSpecs: QuickSpec {
    override func spec() {
        var mockRepository: MockNotificationRepository!
        var dispatchQueue: DispatchQueue!
        var receiver: DefaultNotificationDataReceiver!
        var testData: NotificationData!
        var testTimestamp: Date!

        beforeEach {
            mockRepository = MockNotificationRepository()
            mockRepository.deleteAll()
            dispatchQueue = DispatchQueue(label: "DefaultNotificationDataReceiverSpecs")
            receiver = DefaultNotificationDataReceiver(dispatchQueue: dispatchQueue, repository: mockRepository)
            testData = NotificationData(
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
            testTimestamp = Date()
        }

        it("onNotificationDataReceived 호출 시 저장이 비동기로 실행된다") {
            receiver.onNotificationDataReceived(data: testData, timestamp: testTimestamp)

            dispatchQueue.sync {
                expect(mockRepository.getEntities(workspaceId: 123, environmentId: 456).count).to(equal(1))
                let entity = mockRepository.getEntities(workspaceId: 123, environmentId: 456).first
                expect(entity?.pushMessageId).to(equal(1))
                expect(entity?.pushMessageKey).to(equal(2))
                expect(entity?.pushMessageExecutionId).to(equal(3))
                expect(entity?.pushMessageDeliveryId).to(equal(4))
                expect(entity?.journeyId).to(beNil())
                expect(entity?.journeyKey).to(beNil())
                expect(entity?.journeyNodeId).to(beNil())
                expect(entity?.campaignType).to(equal("JOURNEY"))
                expect(entity?.debug).to(equal(true))
            }
        }
    }
}
