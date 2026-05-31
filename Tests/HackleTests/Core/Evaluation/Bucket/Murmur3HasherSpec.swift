//
// Created by yong on 2020/12/17.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class Murmur3HasherSpec: QuickSpec {
    override class func spec() {

        let sut = Murmur3Hasher()

        it("murmur3") {
            func check(csv: [[String]]) {
                for line in csv {
                    let expected = Int32(line[2])!
                    let actual = sut.hash(data: line[0], seed: Int32(line[1])!)
                    expect(actual) == expected
                }
            }

            func loadCsv(fileName: String) -> [[String]] {
                let filePath = Bundle(for: Murmur3HasherSpec.self).path(forResource: fileName, ofType: "csv")!
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
                "murmur_all",
                "murmur_alphabetic",
                "murmur_alphanumeric",
                "murmur_numeric",
                "murmur_uuid",
            ]

            for fileName in fileNames {
                let csv = loadCsv(fileName: fileName)
                check(csv: csv)
            }
        }

        it("does not crash on the boundary hash value 0x80000000") {
            let actual = sut.hash(data: "user_6601597700", seed: 0)
            expect(actual) == Int32.min
        }

        it("maps the full UInt32 hash range without trapping") {
            let identifiers = (0..<100_000).map { "id_\($0)" }
            for identifier in identifiers {
                _ = sut.hash(data: identifier, seed: 0)
            }
        }
    }
}
