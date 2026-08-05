import Foundation
import MockingKit
@testable import Hackle

class MockEvaluationEventRecorder: EvaluationEventRecorder {

    private(set) var records: [EvaluateResponse] = []

    var recordCount: Int {
        records.count
    }

    init() {
        super.init(
            eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
            eventProcessor: MockUserEventProcessor()
        )
    }

    override func record(response: EvaluateResponse) {
        records.append(response)
    }

    func evaluation(_ index: Int = 0) -> Evaluation? {
        guard index < records.count else {
            return nil
        }
        return records[index].evaluation
    }
}
