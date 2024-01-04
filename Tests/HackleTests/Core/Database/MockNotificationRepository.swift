import Foundation
@testable import Hackle

class MockNotificationRepository: NotificationRepository {
    private var incrementKey: Int64 = 0
    private var entityDict: [String: NotificationHistoryEntity] = [:]
    
    private func getDictKey(workspaceId: Int64, environmentId: Int64, historyId: Int64) -> String {
        return "\(workspaceId):\(environmentId):\(historyId)"
    }
    
    func count(workspaceId: Int64, environmentId: Int64) -> Int {
        var count = 0
        self.entityDict.forEach { (key: String, value: NotificationHistoryEntity) in
            if value.workspaceId == workspaceId &&
               value.environmentId == environmentId {
                count += 1
            }
        }
        return count
    }
    
    func save(data: NotificationData, timestamp: Date) {
        let entity = NotificationHistoryEntity(
            historyId: incrementKey,
            workspaceId: data.workspaceId,
            environmentId: data.environmentId,
            pushMessageId: data.pushMessageId,
            pushMessageKey: data.pushMessageKey,
            pushMessageExecutionId: data.pushMessageExecutionId,
            pushMessageDeliveryId: data.pushMessageDeliveryId,
            timestamp: timestamp,
            debug: data.debug
        )
        incrementKey += 1
        let key = getDictKey(workspaceId: data.workspaceId, environmentId: data.environmentId, historyId: entity.historyId)
        self.entityDict[key] = entity
    }
    
    func getEntities(workspaceId: Int64, environmentId: Int64, limit: Int?) -> [NotificationHistoryEntity] {
        var list: [NotificationHistoryEntity] = []
        entityDict.forEach { (key: String, value: NotificationHistoryEntity) in
            if value.workspaceId == workspaceId &&
               value.environmentId == environmentId {
                list.append(value)
            }
        }
        if let limit = limit,
           list.count > limit {
            return Array(list[0..<limit])
        } else {
            return list
        }
    }
    
    func delete(entities: [NotificationHistoryEntity]) {
        entities.forEach { entity in
            let key = getDictKey(workspaceId: entity.workspaceId, environmentId: entity.environmentId, historyId: entity.historyId)
            self.entityDict.removeValue(forKey: key)
        }
    }
}
