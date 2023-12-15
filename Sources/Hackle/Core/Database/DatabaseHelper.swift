import Foundation
import SQLite3

class DatabaseHelper {
    private static var sharedDatabase: SharedDatabase? = nil
    private static var workspaceDatabases = [String: WorkspaceDatabase]()
    
    static func getSharedDatabase() -> SharedDatabase {
        if let sharedDatabase = sharedDatabase {
            return sharedDatabase
        } else {
            let sharedDatabase = SharedDatabase()
            self.sharedDatabase = sharedDatabase
            return sharedDatabase
        }
    }
    
    static func getWorkspaceDatabase(sdkKey: String) -> WorkspaceDatabase {
        if let workspaceDatabase = workspaceDatabases[sdkKey] {
            return workspaceDatabase
        } else {
            let workspaceDatabase = WorkspaceDatabase(sdkKey: sdkKey)
            workspaceDatabases[sdkKey] = workspaceDatabase
            return workspaceDatabase
        }
    }
}
