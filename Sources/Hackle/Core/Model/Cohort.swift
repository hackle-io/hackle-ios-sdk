import Foundation


class Cohort: CustomStringConvertible {

    typealias Id = Int64

    let id: Id

    init(id: Id) {
        self.id = id
    }

    var description: String {
        "Cohort(id: \(id))"
    }
}
