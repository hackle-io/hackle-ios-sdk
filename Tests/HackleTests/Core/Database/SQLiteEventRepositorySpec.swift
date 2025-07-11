//
//  SQLiteEventRepositorySpec.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/11/25.
//

import Foundation
import Nimble
import Quick
@testable import Hackle

class SQLiteEventRepositorySpec: QuickSpec {
    override func spec() {
        var sut: MockSQLiteEventRepository!

        beforeEach {
            sut = MockSQLiteEventRepository()
            sut.deleteAll()
        }

        describe("count") {
            context("DB에 이벤트가 없을 때") {
                it("0을 반환해야 한다") {
                    expect(sut.count()).to(equal(0))
                }
            }
            context("DB에 이벤트가 있을 때") {
                it("전체 이벤트 개수를 반환해야 한다") {
                    // Given: 3개의 이벤트 저장
                    sut.save(event: UserEvents.track(UUID().uuidString))
                    sut.save(event: UserEvents.track(UUID().uuidString))
                    sut.save(event: UserEvents.track(UUID().uuidString))
                    
                    // Then
                    expect(sut.count()).to(equal(3))
                }
            }
        }

        describe("countBy(status:)") {
            it("특정 상태의 이벤트 개수를 정확히 반환해야 한다") {
                // Given: pending 2개, flushing 1개 이벤트 저장
                sut.save(event: UserEvents.track(UUID().uuidString))
                sut.save(event: UserEvents.track(UUID().uuidString))
                _ = sut.getEventToFlush(limit: 1) // 1개를 flushing 상태로 변경
                
                // Then
                expect(sut.countBy(status: .pending)).to(equal(1))
                expect(sut.countBy(status: .flushing)).to(equal(1))
            }
        }

        describe("save(event:)") {
            it("이벤트를 DB에 저장하고, status는 pending으로 설정해야 한다") {
                // Given
                let uuid = UUID().uuidString
                let event = UserEvents.track(uuid)

                // When
                sut.save(event: event)

                // Then
                let savedEvents = sut.findAllBy(status: .pending)
                expect(savedEvents.count).to(equal(1))
                expect(savedEvents.first?.status).to(equal(.pending))
                expect(savedEvents.first?.body).to(contain(uuid))
            }
        }

        describe("getEventToFlush(limit:)") {
            beforeEach {
                for _ in 1...5 {
                    sut.save(event: UserEvents.track(UUID().uuidString))
                }
            }
            
            it("pending 상태의 이벤트를 가져오고, 상태를 flushing으로 변경해야 한다") {
                // When
                let events = sut.getEventToFlush(limit: 3)
                
                // Then
                expect(events.count).to(equal(3))
                expect(sut.countBy(status: .pending)).to(equal(2))
                expect(sut.countBy(status: .flushing)).to(equal(3))
            }
        }

        describe("findAllBy(status:)") {
            it("지정된 상태의 모든 이벤트를 반환해야 한다") {
                // Given
                sut.save(event: UserEvents.track(UUID().uuidString))
                _ = sut.getEventToFlush(limit: 1) // 1개를 flushing으로
                
                // Then
                expect(sut.findAllBy(status: .pending).count).to(equal(0))
                expect(sut.findAllBy(status: .flushing).count).to(equal(1))
            }
        }

        describe("update(events:status:)") {
            it("지정된 이벤트들의 상태를 올바르게 변경해야 한다") {
                // Given
                sut.save(event: UserEvents.track(UUID().uuidString))
                sut.save(event: UserEvents.track(UUID().uuidString))
                let events = sut.findAllBy(status: .pending)
                
                // When
                sut.update(events: events, status: .flushing)
                
                // Then
                expect(sut.countBy(status: .pending)).to(equal(0))
                expect(sut.countBy(status: .flushing)).to(equal(2))
            }
        }

        describe("delete(events:)") {
            it("지정된 이벤트들만 정확히 삭제해야 한다") {
                // Given
                sut.save(event: UserEvents.track(UUID().uuidString))
                sut.save(event: UserEvents.track(UUID().uuidString))
                let allEvents = sut.findAllBy(status: .pending)
                let eventsToDelete = [allEvents[0]]
                
                // When
                sut.delete(events: eventsToDelete)
                
                // Then
                expect(sut.count()).to(equal(1))
                expect(sut.findAllBy(status: .pending).first?.id).to(equal(allEvents[1].id))
            }
        }

        describe("deleteOldEvents(count:)") {
            beforeEach {
                for _ in 1...10 {
                    sut.save(event: UserEvents.track(UUID().uuidString))
                }
            }
            
            context("DB의 총 이벤트 수가 count보다 클 때") {
                it("가장 오래된 이벤트를 삭제하여 count 개수만큼 남겨야 한다") {
                    // When: 7개만 남기도록 삭제
                    sut.deleteOldEvents(count: 3)
                    
                    // Then
                    expect(sut.count()).to(equal(7))
                }
            }
            
            context("DB의 총 이벤트 수가 count보다 작거나 같을 때") {
                it("아무것도 삭제하지 않아야 한다") {
                    // When
                    sut.deleteOldEvents(count: 15)
                    
                    // Then
                    expect(sut.count()).to(equal(10))
                }
            }
        }

        describe("deleteExpiredEvents(currentMillis:)") {
            let now = Date()
            beforeEach {
                // 만료된 이벤트 1000개 저장
                for _ in 1...1000 {
                    sut.save(event: UserEvents.track(UUID().uuidString, timestamp: (now.timeIntervalSince1970 - Double(userEventExpiredInterval) * 0.001) - 1000.0))
                }
            }
            it("만료된 pending 상태의 이벤트만 삭제해야 한다") {
                // 만료되지 않은 이벤트
                sut.save(event: UserEvents.track(UUID().uuidString))
                
                let events = sut.findAllBy(status: .pending)
                expect(events.count).to(equal(1001)) // 만료된 이벤트 1000개 + 만료되지 않은 이벤트 1개

                // When
                sut.deleteExpiredEvents(currentMillis: now.epochMillis)

                // Then
                expect(sut.count()).to(equal(1))
            }
        }
    }
}
