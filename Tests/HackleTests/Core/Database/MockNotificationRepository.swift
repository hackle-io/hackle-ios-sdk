import Foundation
@testable import Hackle

class MockNotificationRepository: DefaultNotificationRepository {
    private let reservedWorkspaceIdList: [Int64] = [123, 111]
    private let reservedEnvironmentIdList: [Int64] = [456, 222]
    
    init() {
        super.init(sharedDatabase: SharedDatabase())
    }

    func putAll(entities: [NotificationHistoryEntity]) {
        entities.forEach { entity in
            save(
                data: NotificationData(
                    workspaceId: entity.workspaceId,
                    environmentId: entity.environmentId,
                    pushMessageId: entity.pushMessageId,
                    pushMessageKey: entity.pushMessageKey,
                    pushMessageExecutionId: entity.pushMessageExecutionId,
                    pushMessageDeliveryId: entity.pushMessageDeliveryId,
                    showForeground: true,
                    imageUrl: nil,
                    clickAction: .appOpen,
                    link: nil,
                    journeyId: entity.journeyId,
                    journeyKey: entity.journeyKey,
                    journeyNodeId: entity.journeyNodeId,
                    campaignType: entity.campaignType,
                    debug: entity.debug
                ),
                timestamp: entity.timestamp
            )
        }
    }
    
    func deleteAll() {
        for workspaceId in reservedWorkspaceIdList {
            for environmentId in reservedEnvironmentIdList {
                let entities = getEntities(workspaceId: workspaceId, environmentId: environmentId)
                delete(entities: entities)
            }
        }

    }
}
