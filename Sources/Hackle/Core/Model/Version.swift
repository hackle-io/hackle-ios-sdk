import Foundation

struct Version: Comparable, CustomStringConvertible {

    let coreVersion: CoreVersion
    let prerelease: MetadataVersion
    let build: MetadataVersion

    private static let pattern = "^(?<major>0|[1-9]\\d*)" +
        "(?:\\.(?<minor>0|[1-9]\\d*))?" +
        "(?:\\.(?<patch>0|[1-9]\\d*))?" +
        "(?:-(?<prerelease>(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?" +
        "(?:\\+(?<build>[0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"


    private static let regex = try! NSRegularExpression(pattern: pattern)

    static func tryParse(value: Any?) -> Version? {
        guard let value = value, let text = Objects.asStringOrNil(value) else {
            return nil
        }

        return tryParse(value: text)
    }

    static func tryParse(value: String) -> Version? {
        guard let match = Version.regex.match(value) else {
            return nil
        }

        let major = Int(match[0]!)!
        let minor = Int(match[1] ?? "0")!
        let patch = Int(match[2] ?? "0")!

        let coreVersion = CoreVersion(major: major, minor: minor, patch: patch)
        let prerelease = MetadataVersion.parse(match[3])
        let build = MetadataVersion.parse(match[4])

        return Version(coreVersion: coreVersion, prerelease: prerelease, build: build)
    }

    func compare(_ other: Version) -> ComparisonResult {
        let result = compareValues(coreVersion, other.coreVersion)
        if result != .orderedSame {
            return result
        }
        return prerelease.compare(other.prerelease)
    }

    var description: String {
        var version = coreVersion.description
        if prerelease.isNotEmpty {
            version += "-"
            version += prerelease.description
        }
        if build.isNotEmpty {
            version += "+"
            version += build.description
        }
        return version
    }

    static func ==(lhs: Version, rhs: Version) -> Bool {
        lhs.compare(rhs).rawValue == 0
    }

    static func >(lhs: Version, rhs: Version) -> Bool {
        lhs.compare(rhs).rawValue > 0
    }

    static func >=(lhs: Version, rhs: Version) -> Bool {
        lhs.compare(rhs).rawValue >= 0
    }

    static func <(lhs: Version, rhs: Version) -> Bool {
        lhs.compare(rhs).rawValue < 0
    }

    static func <=(lhs: Version, rhs: Version) -> Bool {
        lhs.compare(rhs).rawValue <= 0
    }
}

struct CoreVersion: Comparable, CustomStringConvertible {

    let major: Int
    let minor: Int
    let patch: Int

    func compare(_ other: CoreVersion) -> ComparisonResult {
        compareValuesBy(self, other, { $0.major }, { $0.minor }, { $0.patch })
    }

    var description: String {
        "\(major).\(minor).\(patch)"
    }

    static func ==(lhs: CoreVersion, rhs: CoreVersion) -> Bool {
        lhs.compare(rhs).rawValue == 0
    }

    static func <(lhs: CoreVersion, rhs: CoreVersion) -> Bool {
        lhs.compare(rhs).rawValue < 0
    }

    static func <=(lhs: CoreVersion, rhs: CoreVersion) -> Bool {
        lhs.compare(rhs).rawValue <= 0
    }

    static func >(lhs: CoreVersion, rhs: CoreVersion) -> Bool {
        lhs.compare(rhs).rawValue > 0
    }

    static func >=(lhs: CoreVersion, rhs: CoreVersion) -> Bool {
        lhs.compare(rhs).rawValue >= 0
    }
}

struct MetadataVersion: Comparable, CustomStringConvertible {

    let identifiers: [String]


    private static let EMPTY = MetadataVersion(identifiers: [])

    static func parse(_ value: String?) -> MetadataVersion {
        if let text = value {
            return MetadataVersion(identifiers: text.components(separatedBy: "."))
        } else {
            return EMPTY
        }
    }

    var isEmpty: Bool {
        get {
            identifiers.isEmpty
        }
    }

    var isNotEmpty: Bool {
        get {
            !isEmpty
        }
    }

    var description: String {
        identifiers.joined(separator: ".")
    }

    func compare(_ other: MetadataVersion) -> ComparisonResult {
        if isEmpty && other.isEmpty {
            return .orderedSame
        }

        if isEmpty && other.isNotEmpty {
            return .orderedDescending
        }

        if isNotEmpty && other.isEmpty {
            return .orderedAscending
        }

        return compareIdentifiers(other)
    }

    private func compareIdentifiers(_ other: MetadataVersion) -> ComparisonResult {
        for (selfIdentifier, otherIdentifier) in zip(identifiers, other.identifiers) {
            let result = compareIdentifiers(selfIdentifier, otherIdentifier)
            if result != .orderedSame {
                return result
            }
        }
        return compareValues(identifiers.count, other.identifiers.count)
    }

    private func compareIdentifiers(_ identifier1: String, _ identifier2: String) -> ComparisonResult {
        if let number1 = Int(identifier1),
           let number2 = Int(identifier2) {
            return compareValues(number1, number2)
        } else {
            return compareValues(identifier1, identifier2)
        }
    }

    static func ==(lhs: MetadataVersion, rhs: MetadataVersion) -> Bool {
        lhs.compare(rhs).rawValue == 0
    }

    static func >(lhs: MetadataVersion, rhs: MetadataVersion) -> Bool {
        lhs.compare(rhs).rawValue > 0
    }

    static func >=(lhs: MetadataVersion, rhs: MetadataVersion) -> Bool {
        lhs.compare(rhs).rawValue >= 0
    }

    static func <(lhs: MetadataVersion, rhs: MetadataVersion) -> Bool {
        lhs.compare(rhs).rawValue < 0
    }

    static func <=(lhs: MetadataVersion, rhs: MetadataVersion) -> Bool {
        lhs.compare(rhs).rawValue <= 0
    }
}

func compareValues<T: Comparable>(_ a: T, _ b: T) -> ComparisonResult {
    if a == b {
        return .orderedSame
    }

    if a < b {
        return .orderedAscending
    }

    return .orderedDescending
}

func compareValuesBy<T, C: Comparable>(_ a: T, _  b: T, _  selectors: (T) -> C...) -> ComparisonResult {
    for selector in selectors {
        let v1 = selector(a)
        let v2 = selector(b)
        let diff = compareValues(v1, v2)
        if diff != .orderedSame {
            return diff
        }
    }
    return .orderedSame
}

extension NSRegularExpression {

    fileprivate func match(_ string: String, options: NSRegularExpression.Options = []) -> [String?]? {
        let range = NSRange(string.startIndex..., in: string)
        guard let match = firstMatch(in: string, options: [], range: range) else {
            return nil
        }

        return (1...numberOfCaptureGroups).map {
            if let r = Range(match.range(at: $0), in: string) {
                return String(string[r])
            } else {
                return nil
            }
        }
    }
}
