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
            let fileName = "test.db"
            
            beforeEach {
                UserDefaultsKeyValueRepository.of(suiteName: storageSuiteNameDatabaseVersion).remove(key: fileName)
                mockDB = MockDatabase(
                    label: testLabel,
                    filename: fileName,
                    version: 1,
                    ddl: [
                        DatabaseDDL(
                            version: 1,
                            statements: [
                                "DROP TABLE IF EXISTS Users",
                            ])
                    ]
                )
            }
            
            context("신규 데이터베이스 생성 시") {
                it("DDL 순차 실행 및 스키마 업데이트") {
                    mockDB = MockDatabase(
                        label: testLabel,
                        filename: fileName,
                        version: 3,
                        ddl: [
                            DatabaseDDL(
                                version: 2,
                                statements: [
                                    "CREATE TABLE Users(id INTEGER PRIMARY KEY)",
                                ]
                            ),
                            DatabaseDDL(
                                version: 3,
                                statements: [
                                    "CREATE INDEX user_index ON Users(id)"
                                ]
                            )
                        ]
                    )
                    
                    expect(mockDB.getVersion(key: fileName)).toEventually(equal(3))
                    
                    // ddl 리스트 갯수 검증
                    let ddlCount = mockDB.ddl.filter { $0.version > 1 && $0.version <= 3 }
                    expect(ddlCount.count).to(equal(2))
                    
                    // 테이블 존재 여부 검증
                    var tableExists = false
                    try mockDB.execute { db in
                        try db.execute(sql: "SELECT * FROM Users")
                        tableExists = true
                    }
                    expect(tableExists).to(beTrue())
                }
            }
            
            context("버전 업데이트 필요 시") {
                it("DDL 순차 실행 및 스키마 업데이트") {
                    mockDB = MockDatabase(
                        label: testLabel,
                        filename: fileName,
                        version: 0
                    )
                    
                    
                    mockDB = MockDatabase(
                        label: testLabel,
                        filename: fileName,
                        version: 2,
                        ddl: [
                            DatabaseDDL(
                                version: 2,
                                statements: [
                                    "CREATE TABLE Users(id INTEGER PRIMARY KEY)",
                                ]
                            ),
                            DatabaseDDL(
                                version: 3,
                                statements: [
                                    "CREATE INDEX user_index ON Users(id)"
                                ]
                            )
                        ]
                    )

                    // ddl 리스트 갯수 검증
                    let ddlCount = mockDB.ddl.filter { $0.version > 0 && $0.version <= 2 }
                    expect(ddlCount.count).to(equal(1))
                    
                    // 테이블 존재 여부 검증
                    var tableExists = false
                    try mockDB.execute { db in
                        try db.execute(sql: "SELECT * FROM Users")
                        tableExists = true
                    }
                    expect(tableExists).to(beTrue())
                }
            }
            
            context("마이그레이션 실패 시") {
                it("onDrop 호출") {
                    mockDB = MockDatabase(
                        label: testLabel,
                        filename: fileName,
                        version: 2
                    )
                    
                    
                    mockDB = MockDatabase(
                        label: testLabel,
                        filename: fileName,
                        version: 3,
                        ddl: [
                            DatabaseDDL(
                                version: 3,
                                statements: ["INVALID SQL"]
                            )
                        ]
                    )
                    
                    expect(mockDB.onDropCalled).toEventually(beTrue())
                    expect(mockDB.getVersion(key: fileName)).to(equal(0))
                }
            }

            context("execute 메서드") {
                it("잠금이 정상 작동해야 함") {
                    mockDB = MockDatabase(label: testLabel, filename: fileName, version: 2)
                    var result = 0
                    
                    
                    let result2 = mockDB.execute { db in
                        result = 42
                        return result
                    }
                    
                    expect(result2).to(equal(result))
                    expect(result).to(equal(42))
                }
            }
            
            it("배타적 락 획득") {
                mockDB = MockDatabase(label: testLabel, filename: fileName, version: 1)
                
                let concurrentQueue = DispatchQueue(
                    label: "test.concurrent",
                    attributes: .concurrent
                )
                
                var executionLog = [Int]()
                
                concurrentQueue.async {
                    mockDB.execute { _ in
                        executionLog.append(1)
                        sleep(1)
                        executionLog.append(2)
                    }
                }
                
                concurrentQueue.async {
                    mockDB.execute { _ in
                        executionLog.append(3)
                    }
                }
                

                expect(executionLog).toEventually(
                    equal([1,2,3]),
                    timeout: .seconds(2)
                )
            }
        }
    }
    
    class MockDatabase: Database {
        var onDropCalled = false
        var ddl: [DatabaseDDL]
        
        init(label: String, filename: String, version: Int, ddl: [DatabaseDDL] = []) {
            self.ddl = ddl
            super.init(label: label, filename: filename, version: version)
        }
        
        override func getDDLs() -> [DatabaseDDL] {
            return ddl
        }

        override func onDrop() throws {
            onDropCalled = true
        }
    }
}
