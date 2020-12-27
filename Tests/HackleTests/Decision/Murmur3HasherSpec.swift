//
// Created by yong on 2020/12/17.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class Murmur3HasherSpec: QuickSpec {
    override func spec() {

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
    }
}
