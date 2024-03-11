import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class NotificationManagerSpec: QuickSpec {
    override func spec() {
        let dispatchQueue = DispatchQueue(label: "test")
        var core: HackleCoreStub!
        var workspaceFetcher: MockWorkspaceFetcher!
        var userManager: MockUserManager!
        var repository: MockNotificationRepository!

        beforeEach {
            core = HackleCoreStub()
            workspaceFetcher = MockWorkspaceFetcher()
            userManager = MockUserManager()
            repository = MockNotificationRepository()
        }

        it("track push click event when notification data received") {
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                repository: repository
            )
            every(workspaceFetcher.fetchMock)
                .returns(WorkspaceEntity(
                    id: 123,
                    environmentId: 456,
                    experiments: [],
                    featureFlags: [],
                    buckets: [],
                    eventTypes: [],
                    segments: [],
                    containers: [],
                    parameterConfigurations: [],
                    remoteConfigParameters: [],
                    inAppMessages: []
                ))
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)

            let timestamp = Date()
            manager.onNotificationDataReceived(
                data: NotificationData(
                    workspaceId: 123,
                    environmentId: 456,
                    pushMessageId: 1,
                    pushMessageKey: 2,
                    pushMessageExecutionId: 3,
                    pushMessageDeliveryId: 4,
                    showForeground: true,
                    imageUrl: "https://foo.com/bar.png",
                    clickAction: .deepLink,
                    link: "foo://bar",
                    debug: true
                ),
                timestamp: timestamp
            )

            dispatchQueue.sync {
                expect(core.tracked.count) == 1
                expect(core.tracked[0].0.key) == "$push_click"
                expect(core.tracked[0].0.properties?["push_message_id"].asIntOrNil()) == 1
                expect(core.tracked[0].0.properties?["push_message_key"].asIntOrNil()) == 2
                expect(core.tracked[0].0.properties?["push_message_execution_id"].asIntOrNil()) == 3
                expect(core.tracked[0].0.properties?["push_message_delivery_id"].asIntOrNil()) == 4
                expect(core.tracked[0].0.properties?["debug"] as? Bool) == true
                expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970
            }
        }

        it("save notification data if environment is not same") {
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                repository: repository
            )
            every(workspaceFetcher.fetchMock)
                .returns(WorkspaceEntity(
                    id: 123,
                    environmentId: 456,
                    experiments: [],
                    featureFlags: [],
                    buckets: [],
                    eventTypes: [],
                    segments: [],
                    containers: [],
                    parameterConfigurations: [],
                    remoteConfigParameters: [],
                    inAppMessages: []
                ))
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)

            let timestamp = Date()
            let matchData = NotificationData(
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
                debug: true
            )
            manager.onNotificationDataReceived(data: matchData, timestamp: timestamp)

            let diffWorkspaceData = NotificationData(
                workspaceId: 111,
                environmentId: 456,
                pushMessageId: 1,
                pushMessageKey: 2,
                pushMessageExecutionId: 3,
                pushMessageDeliveryId: 4,
                showForeground: true,
                imageUrl: nil,
                clickAction: .appOpen,
                link: "",
                debug: true
            )
            manager.onNotificationDataReceived(data: diffWorkspaceData, timestamp: Date())

            let diffEnvironmentData = NotificationData(
                workspaceId: 123,
                environmentId: 222,
                pushMessageId: 1,
                pushMessageKey: 2,
                pushMessageExecutionId: 3,
                pushMessageDeliveryId: 4,
                showForeground: true,
                imageUrl: nil,
                clickAction: .appOpen,
                link: "",
                debug: true
            )
            manager.onNotificationDataReceived(data: diffEnvironmentData, timestamp: Date())

            let diffBothData = NotificationData(
                workspaceId: 111,
                environmentId: 222,
                pushMessageId: 1,
                pushMessageKey: 2,
                pushMessageExecutionId: 3,
                pushMessageDeliveryId: 4,
                showForeground: true,
                imageUrl: nil,
                clickAction: .appOpen,
                link: "",
                debug: true
            )
            manager.onNotificationDataReceived(data: diffBothData, timestamp: Date())

            dispatchQueue.sync {
                expect(core.tracked.count) == 1
                expect(core.tracked[0].0.key) == "$push_click"
                expect(core.tracked[0].0.properties?["push_message_id"].asIntOrNil()) == 1
                expect(core.tracked[0].0.properties?["push_message_key"].asIntOrNil()) == 2
                expect(core.tracked[0].0.properties?["push_message_execution_id"].asIntOrNil()) == 3
                expect(core.tracked[0].0.properties?["push_message_delivery_id"].asIntOrNil()) == 4
                expect(core.tracked[0].0.properties?["debug"] as? Bool) == true
                expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970

                expect(repository.count(workspaceId: 123, environmentId: 456)) == 0
                expect(repository.count(workspaceId: 111, environmentId: 456)) == 1
                expect(repository.count(workspaceId: 123, environmentId: 222)) == 1
                expect(repository.count(workspaceId: 111, environmentId: 222)) == 1
            }
        }

        it("save notification data if workspace fetcher returns null") {
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                repository: repository
            )
            every(workspaceFetcher.fetchMock).returns(nil)
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)

            manager.onNotificationDataReceived(
                data: NotificationData(
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
                    debug: true
                ),
                timestamp: Date()
            )

            dispatchQueue.sync {
                expect(core.tracked.count) == 0
                expect(repository.count(workspaceId: 123, environmentId: 456)) == 1
            }
        }

        it("flush data until empty") {
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                repository: repository
            )
            every(workspaceFetcher.fetchMock)
                .returns(WorkspaceEntity(
                    id: 1,
                    environmentId: 2,
                    experiments: [],
                    featureFlags: [],
                    buckets: [],
                    eventTypes: [],
                    segments: [],
                    containers: [],
                    parameterConfigurations: [],
                    remoteConfigParameters: [],
                    inAppMessages: []
                ))
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            repository.putAll(entities: [
                NotificationHistoryEntity(
                    historyId: 0,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                ),
                NotificationHistoryEntity(
                    historyId: 1,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                ),
                NotificationHistoryEntity(
                    historyId: 2,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                )
            ])

            manager.flush()

            dispatchQueue.sync {
                expect(core.tracked.count) == 3
                expect(repository.count(workspaceId: 1, environmentId: 2)) == 0
            }
        }

        it("flush only same environment data") {
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                repository: repository
            )
            every(workspaceFetcher.fetchMock)
                .returns(WorkspaceEntity(
                    id: 3,
                    environmentId: 3,
                    experiments: [],
                    featureFlags: [],
                    buckets: [],
                    eventTypes: [],
                    segments: [],
                    containers: [],
                    parameterConfigurations: [],
                    remoteConfigParameters: [],
                    inAppMessages: []
                ))
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            repository.putAll(entities: [
                NotificationHistoryEntity(
                    historyId: 0,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                ),
                NotificationHistoryEntity(
                    historyId: 1,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                ),
                NotificationHistoryEntity(
                    historyId: 2,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                )
            ])

            manager.flush()

            dispatchQueue.sync {
                expect(core.tracked.count) == 0
                expect(repository.count(workspaceId: 1, environmentId: 2)) == 3
            }
        }

        it("flush only same environment data") {
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                repository: repository
            )
            every(workspaceFetcher.fetchMock)
                .returns(nil)
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            repository.putAll(entities: [
                NotificationHistoryEntity(
                    historyId: 0,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                ),
                NotificationHistoryEntity(
                    historyId: 1,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                ),
                NotificationHistoryEntity(
                    historyId: 2,
                    workspaceId: 1,
                    environmentId: 2,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true
                )
            ])

            manager.flush()

            dispatchQueue.sync {
                expect(core.tracked.count) == 0
                expect(repository.count(workspaceId: 1, environmentId: 2)) == 3
            }
        }
    }
}
