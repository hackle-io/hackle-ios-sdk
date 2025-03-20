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
        
        beforeSuite {
            // 최초에 버전값을 초기화 해서 강제로 최신테이블 재생성
            UserDefaultsKeyValueRepository.of(suiteName: storageSuiteNameDatabaseVersion).remove(key: "shared_hackle.sqlite")
        }

        beforeEach {
            core = HackleCoreStub()
            workspaceFetcher = MockWorkspaceFetcher()
            userManager = MockUserManager()
            repository = MockNotificationRepository()
            repository.deleteAll()
        }

        it("track push click event when notification data received") {
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
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: nil,
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
                journeyId: 0,
                journeyKey: 1,
                journeyNodeId: 2,
                campaignType: "JOURNEY",
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
                journeyId: nil,
                journeyKey: nil,
                journeyNodeId: nil,
                campaignType: "PUSH_MESSAGE",
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
                journeyId: 3,
                journeyKey: 4,
                journeyNodeId: 5,
                campaignType: "JOURNEY",
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
                journeyId: 0,
                journeyKey: 1,
                journeyNodeId: 2,
                campaignType: "JOURNEY",
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
                expect(core.tracked[0].0.properties?["journey_id"].asIntOrNil()) == 0
                expect(core.tracked[0].0.properties?["journey_key"].asIntOrNil()) == 1
                expect(core.tracked[0].0.properties?["journey_node_id"].asIntOrNil()) == 2
                expect(core.tracked[0].0.properties?["campaign_type"] as? String) == "JOURNEY"
                expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970
                

                expect(repository.count(workspaceId: 123, environmentId: 456)) == 0
                expect(repository.count(workspaceId: 111, environmentId: 456)) == 1
                expect(repository.count(workspaceId: 123, environmentId: 222)) == 1
                expect(repository.count(workspaceId: 111, environmentId: 222)) == 1
            }
        }

        it("save notification data if workspace fetcher returns null") {
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
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "JOURNEY",
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
                    environmentId: 222,
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
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: 7,
                    journeyKey: 8,
                    journeyNodeId: 9,
                    campaignType: "JOURNEY"
                ),
                NotificationHistoryEntity(
                    historyId: 1,
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "PUSH_MESSAGE"
                ),
                NotificationHistoryEntity(
                    historyId: 2,
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: 1,
                    journeyKey: 2,
                    journeyNodeId: 3,
                    campaignType: "JOURNEY"
                )
            ])

            manager.flush()

            dispatchQueue.sync {
                expect(core.tracked.count) == 3
                expect(repository.count(workspaceId: 123, environmentId: 222)) == 0
            }
        }

        it("flush only same environment data") {
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
            repository.putAll(entities: [
                NotificationHistoryEntity(
                    historyId: 0,
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: 7,
                    journeyKey: 8,
                    journeyNodeId: 9,
                    campaignType: "JOURNEY"
                ),
                NotificationHistoryEntity(
                    historyId: 1,
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "PUSH_MESSAGE"
                ),
                NotificationHistoryEntity(
                    historyId: 2,
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: 17,
                    journeyKey: 18,
                    journeyNodeId: 19,
                    campaignType: "JOURNEY"
                )
            ])

            manager.flush()

            dispatchQueue.sync {
                expect(core.tracked.count) == 0
                expect(repository.count(workspaceId: 123, environmentId: 222)) == 3
            }
        }

        it("flush only same environment data") {
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
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "PUSH_MESSAGE"
                ),
                NotificationHistoryEntity(
                    historyId: 1,
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "PUSH_MESSAGE"
                ),
                NotificationHistoryEntity(
                    historyId: 2,
                    workspaceId: 123,
                    environmentId: 222,
                    pushMessageId: 3,
                    pushMessageKey: 4,
                    pushMessageExecutionId: 5,
                    pushMessageDeliveryId: 6,
                    timestamp: Date(),
                    debug: true,
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: "PUSH_MESSAGE"
                )
            ])

            manager.flush()

            dispatchQueue.sync {
                expect(core.tracked.count) == 0
                expect(repository.count(workspaceId: 123, environmentId: 222)) == 3
            }
        }
        
        it("check null column") {
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

            let timeStamp = Date()
            manager.onNotificationDataReceived(
                data: NotificationData(
                    workspaceId: 123,
                    environmentId: 456,
                    pushMessageId: nil,
                    pushMessageKey: nil,
                    pushMessageExecutionId: nil,
                    pushMessageDeliveryId: nil,
                    showForeground: true,
                    imageUrl: nil,
                    clickAction: .appOpen,
                    link: nil,
                    journeyId: nil,
                    journeyKey: nil,
                    journeyNodeId: nil,
                    campaignType: nil,
                    debug: true
                ),
                timestamp: timeStamp
            )
            manager.onNotificationDataReceived(
                data: NotificationData(
                    workspaceId: 123,
                    environmentId: 456,
                    pushMessageId: 2222,
                    pushMessageKey: 3333,
                    pushMessageExecutionId: 4444,
                    pushMessageDeliveryId: 5555,
                    showForeground: true,
                    imageUrl: "https://foo",
                    clickAction: .appOpen,
                    link: "https://foo",
                    journeyId: 6666,
                    journeyKey: 7777,
                    journeyNodeId: 8888,
                    campaignType: "type",
                    debug: false
                ),
                timestamp: timeStamp
            )
            
            

            dispatchQueue.sync {
                expect(core.tracked.count) == 0
                expect(repository.count(workspaceId: 123, environmentId: 456)) == 2
                let entities = repository.getEntities(workspaceId: 123, environmentId: 456)
                
                let entity = entities[0]
                expect(entity.pushMessageId).to(beNil())
                expect(entity.pushMessageKey).to(beNil())
                expect(entity.pushMessageExecutionId).to(beNil())
                expect(entity.pushMessageDeliveryId).to(beNil())
                expect(entity.journeyId).to(beNil())
                expect(entity.journeyKey).to(beNil())
                expect(entity.journeyNodeId).to(beNil())
                expect(entity.campaignType).to(beNil())
                expect(entity.debug) == true
                expect(entity.workspaceId) == 123
                expect(entity.environmentId) == 456
                expect(entity.timestamp.timeIntervalSince1970) == timeStamp.timeIntervalSince1970
                
                let entity2 = entities[1]
                expect(entity2.pushMessageId) == 2222
                expect(entity2.pushMessageKey) == 3333
                expect(entity2.pushMessageExecutionId) == 4444
                expect(entity2.pushMessageDeliveryId) == 5555
                expect(entity2.journeyId) == 6666
                expect(entity2.journeyKey) == 7777
                expect(entity2.journeyNodeId) == 8888
                expect(entity2.campaignType) == "type"
                expect(entity2.debug) == false
                expect(entity2.workspaceId) == 123
                expect(entity2.environmentId) == 456
                expect(entity2.timestamp.timeIntervalSince1970) == timeStamp.timeIntervalSince1970
            }
        }
    }
}
