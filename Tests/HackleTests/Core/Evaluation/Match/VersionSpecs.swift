import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class VersionSpecs: QuickSpec {
    override func spec() {

        describe("parse") {

            it("string 타입이 아니면 nil") {
                expect(Version.tryParse(value: nil)).to(beNil())
                expect(Version.tryParse(value: 1.0)).to(beNil())
            }

            it("invalid format") {
                expect(Version.tryParse(value: "01.0.0")).to(beNil())
                expect(Version.tryParse(value: "1.01.0")).to(beNil())
                expect(Version.tryParse(value: "1.0.01")).to(beNil())
                expect(Version.tryParse(value: "2.x")).to(beNil())
                expect(Version.tryParse(value: "2.3.x")).to(beNil())
                expect(Version.tryParse(value: "2.3.1.4")).to(beNil())
                expect(Version.tryParse(value: "1.0.0*beta")).to(beNil())
                expect(Version.tryParse(value: "1.0.0-beta*")).to(beNil())
                expect(Version.tryParse(value: "1.0.0-beta_4")).to(beNil())
            }

            it("semantic core version") {
                self.verify("1.0.0", 1, 0, 0)
                self.verify("14.165.14", 14, 165, 14)
            }

            it("semantic version with prerelease") {
                self.verify("1.0.0-beta1", 1, 0, 0, prerelease: ["beta1"])
                self.verify("1.0.0-beta.1", 1, 0, 0, prerelease: ["beta", "1"])
                self.verify("1.0.0-x.y.z", 1, 0, 0, prerelease: ["x", "y", "z"])
            }

            it("semantic version with build") {
                self.verify("1.0.0+beta1", 1, 0, 0, build: ["beta1"])
                self.verify("1.0.0+beta.1", 1, 0, 0, build: ["beta1", "1"])
                self.verify("1.0.0+x.y.z", 1, 0, 0, build: ["x", "y", "z"])
            }

            it("semantic version with prerelease and build") {
                self.verify("1.0.0-beta.1+build.2", 1, 0, 0, prerelease: ["beta", "1"], build: ["build", "2"])
            }

            it("minor, patch 가 없는 경우 0 으로 채워준다") {
                self.verify("15", 15, 0, 0)
                self.verify("15.143", 15, 143, 0)
                self.verify("15-x.y.z", 15, 0, 0, prerelease: ["x", "y", "z"])
                self.verify("15-x.y.z+a.b.c", 15, 0, 0, prerelease: ["x", "y", "z"], build: ["a", "b", "c"])
            }
        }

        func v(_ version: String) -> Version {
            Version.tryParse(value: version)!
        }

        describe("compare") {
            it("core 버전만 있는 경우 core 버전이 같으면 같은 버전이다") {
                expect(v("2.3.4")).to(equal(v("2.3.4")))
            }

            it("core + prerelease 버전이 모두 같아야 같은 버전이다") {
                expect(v("2.3.4-beta.1")).to(equal(v("2.3.4-beta.1")))
            }

            it("prerelease 버전이 다르면 다른버전이다") {
                expect(v("2.3.4-beta.1")).toNot(equal(v("2.3.4-beta.2")))
            }

            it("build 가 달라도 나머지가 같으면 같은 버전이다") {
                expect(v("2.3.4+build.111")).to(equal(v("2.3.4+build.222")))
                expect(v("2.3.4-beta.1+build.111")).to(equal(v("2.3.4-beta.1+build.222")))
            }

            it("major를 제일 먼저 비교한다") {
                expect(v("4.5.7") > v("3.5.7")).to(beTrue())
                expect(v("2.5.7") < v("3.5.7")).to(beTrue())
            }

            it("major 가 같으면 minor 를 다음으로 비교한다") {
                expect(v("3.6.7") > v("3.5.7")).to(beTrue())
                expect(v("3.4.7") < v("3.5.7")).to(beTrue())
            }

            it("minor 까지 같으면 patch를 비교한다") {
                expect(v("3.5.8") > v("3.5.7")).to(beTrue())
                expect(v("3.5.6") < v("3.5.7")).to(beTrue())
            }

            it("prerelease 숫자로만 구성된 식별자는 수의 크기로 비교한다") {
                expect(v("3.5.7-1") < v("3.5.7-2")).to(beTrue())
                expect(v("3.5.7-1.1") < v("3.5.7-1.2")).to(beTrue())
                expect(v("3.5.7-11") > v("3.5.7-1")).to(beTrue())
            }

            it("prerelease 알파벳이 포함된 경우에는 아스키 문자열 정렬을 한다") {
                expect(v("3.5.7-a") == v("3.5.7-a")).to(beTrue())
                expect(v("3.5.7-a") < v("3.5.7-b")).to(beTrue())
                expect(v("3.5.7-az") > v("3.5.7-ab")).to(beTrue())
            }

            it("prerelease 숫자로만 구성된 식별자는 어떤 경우에도 문자와 붙임표가 있는 식별자보다 낮은 우선순위로 여긴다") {
                expect(v("3.5.7-9") < v("3.5.7-a")).to(beTrue())
                expect(v("3.5.7-9") < v("3.5.7-a-9")).to(beTrue())
                expect(v("3.5.7-beta") > v("3.5.7-1")).to(beTrue())
            }

            it("prerelease 앞선 식별자가 모두 같은 배포 전 버전의 경우에는 필드 수가 많은 쪽이 더 높은 우선순위를 가진다") {
                expect(v("3.5.7-alpha") < v("3.5.7-alpha.1")).to(beTrue())
                expect(v("3.5.7-1.2.3") < v("3.5.7-1.2.3.4")).to(beTrue())
            }
        }
    }

    private func verify(_ version: String, _ major: Int, _ minor: Int, _ patch: Int, prerelease: [String] = [], build: [String] = []) {
        expect(Version.tryParse(value: version))
            .to(equal(Version(
                coreVersion: CoreVersion(major: major, minor: minor, patch: patch),
                prerelease: MetadataVersion(identifiers: prerelease),
                build: MetadataVersion(identifiers: build)
            )))
    }
}
