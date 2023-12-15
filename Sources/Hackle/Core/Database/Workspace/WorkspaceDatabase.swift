import Foundation

class WorkspaceDatabase : Database {
    init(sdkKey: String) {
        super.init(
            label: "io.hackle.WorkspaceDatabase",
            filename: "\(sdkKey)_hackle.sqlite"
        )
        createTable()
    }
    
    private func createTable() {
        do {
            try execute { database in
                try database.execute(
                    sql: EventEntity.CREATE_TABLE
                )
            }
        } catch {
            Log.error("Failed to create tables: \(error)")
        }
    }
}
