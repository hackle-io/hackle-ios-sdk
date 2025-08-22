//
//  UserDefaultKeyValueRepositorySpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/20/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class UserDefaultsKeyValueRepositorySpecs: QuickSpec {
    override func spec() {
        describe("UserDefaultsKeyValueRepository") {
            var repository: UserDefaultsKeyValueRepository!
            let testSuiteName = "com.test.userDefaultsRepositorySpec"

            beforeEach {
                
                repository = UserDefaultsKeyValueRepository.of(suiteName: testSuiteName)
            }

            afterEach {
                repository.clear()
                repository = nil
                UserDefaults().removePersistentDomain(forName: testSuiteName)
            }

            context("when saving and retrieving values") {

                it("should save and retrieve a String correctly") {
                    let key = "testStringKey"
                    let value = "Hello, Nimble!"

                    repository.putString(key: key, value: value)
                    let retrievedValue = repository.getString(key: key)

                    expect(retrievedValue).to(equal(value))
                }

                it("should save and retrieve an Integer correctly") {
                    let key = "testIntKey"
                    let value = 12345

                    repository.putInteger(key: key, value: value)
                    let retrievedValue = repository.getInteger(key: key)

                    expect(retrievedValue).to(equal(value))
                }

                it("should save and retrieve a Double correctly") {
                    let key = "testDoubleKey"
                    let value = 3.14159

                    repository.putDouble(key: key, value: value)
                    let retrievedValue = repository.getDouble(key: key)

                    expect(retrievedValue).to(beCloseTo(value))
                }

                it("should save and retrieve Data correctly") {
                    let key = "testDataKey"
                    let value = "test data".data(using: .utf8)

                    repository.putData(key: key, value: value!)
                    let retrievedValue = repository.getData(key: key)

                    expect(retrievedValue).to(equal(value))
                }
                
                it("should return nil for a non-existent String key") {
                    expect(repository.getString(key: "nonExistentKey")).to(beNil())
                }

                it("should return 0 for a non-existent Integer key") {
                    expect(repository.getInteger(key: "nonExistentKey")).to(equal(0))
                }
            }

            context("when managing all values") {

                it("should retrieve all stored values with getAll") {
                    repository.putString(key: "name", value: "value")
                    repository.putInteger(key: "version", value: 1)

                    let allValues = repository.getAll()

                    expect(allValues["name"] as? String).to(equal("value"))
                    expect(allValues["version"] as? Int).to(equal(1))
                    expect(allValues.keys).to(contain("name", "version"))
                }
            }
            
            context("when removing values") {

                it("should remove a specific value for a key") {
                    let key = "removableKey"
                    repository.putString(key: key, value: "I will be removed")
                    
                    repository.remove(key: key)
                    let retrievedValue = repository.getString(key: key)
                    
                    expect(retrievedValue).to(beNil())
                }

                it("should clear all values from the suite") {
                    repository.putString(key: "key1", value: "value1")
                    repository.putInteger(key: "key2", value: 100)
                    
                    repository.clear()
                    
                    expect(repository.getString(key: "key1")).to(beNil())
                    expect(repository.getInteger(key: "key2")).to(equal(0)) // Int는 없으면 0 반환
                }
            }
        }
    }
}
