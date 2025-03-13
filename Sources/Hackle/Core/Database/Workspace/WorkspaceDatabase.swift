import Foundation

class WorkspaceDatabase: Database {
    static let DATABASE_VERSION = 1

    init(sdkKey: String) {
        super.init(
            label: "io.hackle.WorkspaceDatabase",
            filename: "\(sdkKey)_hackle.sqlite",
            version: WorkspaceDatabase.DATABASE_VERSION
        )
        createTable()
    }
    
    override func onCreate() {
        super.onCreate()
        createTable()
    }
    
    override func onUpdate(oldVersion: Int, newVersion: Int) {
        super.onUpdate(oldVersion: oldVersion, newVersion: newVersion)
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
