//
// Created by yong on 2020/12/17.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultSlotNumberCalculatorSpec: QuickSpec {
    override func spec() {
        let sut = DefaultSlotNumberCalculator(hasher: Murmur3Hasher())

        it("calculate") {
            func check(csv: [[String]]) {
                for line in csv {

                    let seed = Int32(line[0])!
                    let slotSize = Int32(line[1])!
                    let userId = line[2]
                    let slotNumber = Int(line[3])!

                    let actual = sut.calculate(seed: seed, slotSize: slotSize, userId: userId)

                    expect(actual) == slotNumber
                }
            }

            func loadCsv(fileName: String) -> [[String]] {
                let filePath = Bundle(for: DefaultSlotNumberCalculatorSpec.self).path(forResource: fileName, ofType: "csv")!
                let data = try! String(contentsOfFile: filePath)
                var result: [[String]] = []
                let rows = data.components(separatedBy: "\n")
                for row in rows {
                    let columns = row.components(separatedBy: ",")
                    result.append(columns)
                }
                return result
            }

            let fileNames = [
                "bucketing_all",
                "bucketing_alphabetic",
                "bucketing_alphanumeric",
                "bucketing_numeric",
                "bucketing_uuid",
            ]

            for fileName in fileNames {
                let csv = loadCsv(fileName: fileName)
                check(csv: csv)
            }
        }
    }
}
