import Foundation
import Quick
import Nimble
@testable import Hackle

class NotificationHistoryEntitySpec: QuickSpec {
    override class func spec() {
        let filename = "notification_history_test.db"

        beforeEach {
            UserDefaultsKeyValueRepository.of(suiteName: storageSuiteNameDatabaseVersion).remove(key: filename)
            let database = DatabaseSpec.MockDatabase(label: "NotificationHistoryTest", filename: filename, version: 0)
            try database.execute { db in
                try db.execute(sql: NotificationHistoryEntity.DROP_TABLE)
            }
        }

        it("migrates v2 rows to v3 with null action columns") {
            let v2 = DatabaseSpec.MockDatabase(
                label: "NotificationHistoryTest",
                filename: filename,
                version: 2,
                ddl: NotificationHistoryEntity.DDL_LIST
            )
            try v2.execute { db in
                try db.execute(
                    sql: "INSERT INTO \(NotificationHistoryEntity.TABLE_NAME) " +
                        "(workspace_id, environment_id, campaign_type) VALUES (1, 2, 'PUSH_MESSAGE')"
                )
            }

            let v3 = DatabaseSpec.MockDatabase(
                label: "NotificationHistoryTest",
                filename: filename,
                version: 3,
                ddl: NotificationHistoryEntity.DDL_LIST
            )
            let entities = try v3.execute { db -> [NotificationHistoryEntity] in
                try db.query(sql: "SELECT * FROM \(NotificationHistoryEntity.TABLE_NAME)")
                    .use { cursor in
                        var entities = [NotificationHistoryEntity]()
                        while cursor.moveToNext() {
                            entities.append(NotificationHistoryEntity.from(cursor: cursor))
                        }
                        return entities
                    }
            }

            expect(entities.count) == 1
            expect(entities[0].workspaceId) == 1
            expect(entities[0].campaignType) == "PUSH_MESSAGE"
            expect(entities[0].actionType).to(beNil())
            expect(entities[0].actionValue).to(beNil())
            expect(v3.getVersion(key: filename)) == 3
        }

        it("ddl list and shared database version are 3") {
            expect(NotificationHistoryEntity.DDL_LIST.last?.version) == 3
            expect(SharedDatabase.DATABASE_VERSION) == 3
        }
    }
}
