//
//  DefaultExposureEventDedupDeterminerSpec.swift
//  HackleTests
//
//  Created by yong on 2022/08/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class ExposureEventDedupDeterminerSpec: QuickSpec {
    override func spec() {
        var repository: UserDefaultsKeyValueRepository!
        var exposureEventDedupDeterminerSut: ExposureEventDedupDeterminer!
        
        beforeEach {
            repository = UserDefaultsKeyValueRepository.of(suiteName: "unittest_exposure_repo_abcd1234")
            exposureEventDedupDeterminerSut = ExposureEventDedupDeterminer(repository: repository, dedupInterval: 1)
        }
        
        describe("isDedupTarget") {
            it("dedupInterval 이 -1 이면 중복제거 하지 않는다") {
                // given
                let sut = ExposureEventDedupDeterminer(repository: repository, dedupInterval: -1)
                // when
                let actual = sut.isDedupTarget(event: MockUserEvent(user: HackleUser.of(userId: "test_id")))
                // then
                expect(actual) == false
            }

            it("ExposureEvent 가 아니면 중복제거 하지 않는다") {
                // when
                let actual = exposureEventDedupDeterminerSut.isDedupTarget(event: MockUserEvent(user: HackleUser.of(userId: "test_id")))

                // then
                expect(actual) == false
            }

            it("첫 번째 노출이벤트면 중복제거 하지 않는다") {
                let event = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: HackleUser.of(userId: "test_id"),
                    experiment: MockExperiment(),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                // when
                let actual = exposureEventDedupDeterminerSut.isDedupTarget(event: event)

                // then
                expect(actual) == false
            }

            it("같은 사용자의 같은 노출이벤트에 대해 중복제거 기간 이내에 들어온 이벤트는 중복제거 한다") {
                let user = HackleUser.of(userId: "test_id")
                let experiment = MockExperiment()

                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: secondEvent)) == true
            }

            it("같은 사용자의 같은 노출이벤트지만 중복제거 기간 이후에 들어오면 중복제거 하지 않는다") {
                let user = HackleUser.of(userId: "test_id")
                let experiment = MockExperiment()

                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
                sleep(2)
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: secondEvent)) == false
            }

            it("중복제거 기간 이내지만 사용자가 달라지면 중복제거 하지 않는다") {
                let experiment = MockExperiment()

                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: HackleUser.of(userId: "test_id_01"),
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: HackleUser.of(userId: "test_id_02"),
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: secondEvent)) == false
            }

            it("같은 사용자의 중복제거 기간 이내지만 다른 실험에 대한 분배면 중복제거 하지 않는다") {
                let user = HackleUser.of(userId: "test_id_01")

                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: MockExperiment(id: 1),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: MockExperiment(id: 2),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: secondEvent)) == false
            }

            it("같은 사용자의 중복제거 기간 이내지만 분배사유가 변경되면 중복제거 하지 않는다") {
                let user = HackleUser.of(userId: "test_id_01")

                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: MockExperiment(id: 1),
                    variationId: 14,
                    variationKey: "B",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: MockExperiment(id: 1),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.EXPERIMENT_PAUSED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: secondEvent)) == false
            }

            it("사용자의 속성이 변경되어도 식별자만 같으면 같은 사용자로 판단하고 중복제거한다") {
                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: HackleUser(identifiers: ["id": "test_id_01"], properties: [:], hackleProperties: [:]),
                    experiment: MockExperiment(id: 1),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: HackleUser(identifiers: ["id": "test_id_01"], properties: ["age": 30], hackleProperties: [:]),
                    experiment: MockExperiment(id: 1),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: secondEvent)) == true
            }
            
            it("UserDefaults에 저장 후 중복제거 기간 이후에 불러오면 필터링됨. 따라서 중복제거 하지 않는다") {
                let user = HackleUser.of(userId: "test_id_02")
                let experiment = MockExperiment()

                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: secondEvent)) == true
                exposureEventDedupDeterminerSut.cache().saveToRepository()
                sleep(2)
                exposureEventDedupDeterminerSut.cache().loadFromRepository()
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: firstEvent)) == false
            }
            
            it("제한 용량 초과시 UserDefaults에 저장하지 않는다. 불러오면 저장된 값이 없어 중복제거 하지 않는다") {
                let sut = ExposureEventDedupDeterminer(repository: repository, dedupInterval: 100)
                let user = HackleUser.of(userId: "test_id_03")
                let firstEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: MockExperiment(id: 1),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let secondEvent = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: user,
                    experiment: MockExperiment(id: 1),
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )
                
                expect(sut.isDedupTarget(event: firstEvent)) == false
                expect(sut.isDedupTarget(event: secondEvent)) == true
                
                for i in 0..<100000 {
                    let event = UserEvents.Exposure(
                        insertId: "insertId",
                        timestamp: Date(),
                        user: user,
                        experiment: MockExperiment(id: Int64(i+2)),
                        variationId: 14,
                        variationKey: "A",
                        decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                        properties: [:]
                    )
                    let result = sut.isDedupTarget(event: event)
                }
                
                sut.cache().saveToRepository()
                sut.cache().loadFromRepository()
                expect(sut.isDedupTarget(event: firstEvent)) == false
            }

            it("TC1") {
                let userA = HackleUser.of(userId: "a")
                let userB = HackleUser.of(userId: "b")

                let experiment = MockExperiment()

                let event1 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event2 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event3 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userB,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event4 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event1)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event2)) == true
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event3)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event4)) == false
            }

            it("TC2") {
                let userA = HackleUser(identifiers: ["id": "a"], properties: [:], hackleProperties: [:])
                let userAA = HackleUser(identifiers: ["id": "a", "userId": "aa"], properties: [:], hackleProperties: [:])

                let experiment = MockExperiment()

                let event1 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event2 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event3 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userAA,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event4 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event1)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event2)) == true
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event3)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event4)) == false
            }

            it("TC3") {
                let userA = HackleUser.of(userId: "a")

                let experiment1 = MockExperiment(id: 1)
                let experiment2 = MockExperiment(id: 2)

                let event1 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment1,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event2 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment2,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event3 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment1,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                let event4 = UserEvents.Exposure(
                    insertId: "insertId",
                    timestamp: Date(),
                    user: userA,
                    experiment: experiment2,
                    variationId: 14,
                    variationKey: "A",
                    decisionReason: DecisionReason.TRAFFIC_ALLOCATED,
                    properties: [:]
                )

                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event1)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event2)) == false
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event3)) == true
                expect(exposureEventDedupDeterminerSut.isDedupTarget(event: event4)) == true
            }
        }
    }
}
