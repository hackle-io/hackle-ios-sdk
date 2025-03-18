//
//  DatabaseSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/18/25.
//

import Quick
import Nimble
@testable import Hackle
import Foundation

class DatabaseSpec: QuickSpec {
    override func spec() {
        describe("Database") {
            var mockDB: MockDatabase!
            let testLabel = "TestDatabase"
            
            beforeEach {
                UserDefaults.standard.removeObject(forKey: testLabel)
            }
            
            context("처음 초기화 시") {
                it("onCreate가 호출되어야 함") {
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: 1)
                    expect(mockDB.onCreateCalled).toEventually(beTrue())
                }
                
                it("버전이 최신으로 설정되고 onCreate, onMigration이 호출되어야 함") {
                    let version = MockDatabase.MAX_DATABASE_VERSION
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: version)
                    expect(mockDB.onCreateCalled).toEventually(beTrue())
                    expect(mockDB.onMigrationCalled).to(beTrue())
                    expect(mockDB.getVersion(label: testLabel)).toEventually(equal(version))
                }
            }
            
            context("버전이 UserDefault에 저장되어야 함") {
                it("버전이 저장되어야 함") {
                    let version = 2
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: version)
                    expect(mockDB.getVersion(label: testLabel)).to(equal(version))
                }
            }
            
            context("버전 업그레이드 시") {
                beforeEach {
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: 2)
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: 3)
                }
                
                it("onCreate 호출되어야 함") {
                    expect(mockDB.onCreateCalled).to(beTrue())
                }
                
                it("onMigration이 호출되어야 함") {
                    expect(mockDB.onMigrationCalled).to(beTrue())
                }
                
                it("새 버전이 저장되어야 함") {
                    expect(mockDB.getVersion(label: testLabel)).to(equal(3))
                }
            }
            
            context("에러 발생 시") {
                beforeEach {
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: 2)
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: MockDatabase.MAX_DATABASE_VERSION + 1)
                }
                
                it("onMigration이 호출되어야 함") {
                    expect(mockDB.onMigrationCalled).to(beTrue())
                }
                
                it("onDrop이 호출되어야 함") {
                    expect(mockDB.onDropCalled).to(beTrue())
                }
                
                it("onCreateLatest가 호출되어야 함") {
                    expect(mockDB.onCreateLatestCalled).to(beTrue())
                }
            }
            
            context("execute 메서드") {
                it("잠금이 정상 작동해야 함") {
                    mockDB = MockDatabase(label: testLabel, filename: "test.db", version: 2)
                    var result = 0
                    
                    
                    let result2 = mockDB.execute { db in
                        result = 42
                        return result
                    }
                    
                    expect(result2).to(equal(result))
                    expect(result).to(equal(42))
                }
            }
        }
    }
    
    class MockDatabase: Database {
        static let MAX_DATABASE_VERSION = 5
        
        var onCreateCalled = false
        var onMigrationCalled = false
        var onDropCalled = false
        var onCreateLatestCalled = false
        
        override init(label: String, filename: String, version: Int) {
            super.init(label: label, filename: filename, version: version)
        }
        
        override func onCreate() throws {
            onCreateCalled = true
        }
        
        override func onMigration(oldVersion: Int, newVersion: Int) throws {
            onMigrationCalled = true
            
            guard newVersion <= MockDatabase.MAX_DATABASE_VERSION else {
                throw HackleError.error("Unsupported database version: \(newVersion)")
            }
        }
        
        override func onDrop() {
            onDropCalled = true
        }
        
        override func onCreateLatest() {
            onCreateLatestCalled = true
        }
    }
}
