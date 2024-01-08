import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class NotificationManagerSpec: QuickSpec {
    override func spec() {
        let dispatchQueue = DispatchQueue(label: "test")
        var core: HackleCoreStub!
        var preferences: MemoryKeyValueRepository!
        var workspaceFetcher: MockWorkspaceFetcher!
        var userManager: MockUserManager!
        var repository: MockNotificationRepository!
        
        beforeEach {
            core = HackleCoreStub()
            preferences = MemoryKeyValueRepository()
            workspaceFetcher = MockWorkspaceFetcher()
            userManager = MockUserManager()
            repository = MockNotificationRepository()
        }
        
        it("fresh new push token") {
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                preferences: preferences,
                repository: repository
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let data = Data([1, 2, 3, 4])
            let hexString = data.hexString()
            let timestamp = Date()
            manager.setAPNSToken(
                deviceToken: data,
                timestamp: timestamp
            )
            
            dispatchQueue.sync {
                expect(core.tracked.count) == 1
                expect(core.tracked[0].0.key) == "$push_token"
                expect(core.tracked[0].0.properties?["provider_type"] as? String) == "APN"
                expect(core.tracked[0].0.properties?["token"] as? String) == hexString
                expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970
            }
        }
        
        it("set another push token") {
            preferences.putString(key: "apns_device_token", value: Data([1, 2, 3, 4]).hexString())
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                preferences: preferences,
                repository: repository
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let data = Data([5, 6, 7, 8])
            let timestamp = Date()
            manager.setAPNSToken(
                deviceToken: data,
                timestamp: timestamp
            )
            
            dispatchQueue.sync {
                expect(core.tracked.count) == 1
                expect(core.tracked[0].0.key) == "$push_token"
                expect(core.tracked[0].0.properties?["provider_type"] as? String) == "APN"
                expect(core.tracked[0].0.properties?["token"] as? String) == data.hexString()
                expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970
                
                expect(preferences.getString(key: "apns_device_token")) == data.hexString()
            }
        }
        
        it("set same push token") {
            let data = Data([1, 2, 3, 4])
            let hexString = data.hexString()
            preferences.putString(key: "apns_device_token", value: hexString)
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                preferences: preferences,
                repository: repository
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let timestamp = Date()
            manager.setAPNSToken(
                deviceToken: data,
                timestamp: timestamp
            )
            
            dispatchQueue.sync {
                expect(core.tracked.count) == 0
                expect(preferences.getString(key: "apns_device_token")) == hexString
            }
        }
        
        it("resend push token when user updated called") {
            let data = Data([1, 2, 3, 4])
            let hexString = data.hexString()
            preferences.putString(key: "apns_device_token", value: hexString)
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                preferences: preferences,
                repository: repository
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let timestamp = Date()
            manager.onUserUpdated(
                oldUser: User.builder().build(),
                newUser: User.builder().build(),
                timestamp: timestamp
            )
            
            dispatchQueue.sync {
                expect(core.tracked.count) == 1
                expect(core.tracked[0].0.key) == "$push_token"
                expect(core.tracked[0].0.properties?["provider_type"] as? String) == "APN"
                expect(core.tracked[0].0.properties?["token"] as? String) == data.hexString()
                expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970
            }
        }
        
        it("track push click event when notification data received") {
            let userManager = MockUserManager()
            let manager = DefaultNotificationManager(
                core: core,
                dispatchQueue: dispatchQueue,
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                preferences: preferences,
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
                    clickAction: .DEEP_LINK,
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
                preferences: preferences,
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
                clickAction: .APP_OPEN,
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
                clickAction: .APP_OPEN,
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
                clickAction: .APP_OPEN,
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
                clickAction: .APP_OPEN,
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
                preferences: preferences,
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
                    clickAction: .APP_OPEN,
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
    }
}
