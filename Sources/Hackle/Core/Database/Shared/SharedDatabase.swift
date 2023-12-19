import Foundation

class SharedDatabase: Database {
    init() {
        super.init(
            label: "io.hackle.SharedDatabase",
            filename: "shared_hackle.sqlite"
        )
        createTable()
    }
    
    private func createTable() {
        do {
            try execute { database in
                try database.execute(
                    sql: NotificationEntity.CREATE_TABLE
                )
            }
        } catch {
            Log.error("Failed to create tables: \(error)")
        }
    }
}
