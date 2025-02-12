//
// Created by yong on 2020/12/23.
//

import Foundation

extension Array {

    init(count: Int, create: @autoclosure () -> Element) {
        self = (0..<count).map { _ in
            create()
        }
    }

    func associate<Key: Hashable, Value>(transform: (Element) -> (Key, Value)) -> [Key: Value] {
        associateTo(destination: [Key: Value](), transform: transform)
    }

    func associateBy<Key: Hashable>(keySelector: (Element) -> Key) -> [Key: Element] {
        associateTo(destination: [Key: Element]()) { it in
            (keySelector(it), it)
        }
    }

    func associateWith<Value>(valueSelector: (Element) -> Value) -> [Element: Value] {
        associateTo(destination: [Element: Value]()) { it in
            (it, valueSelector(it))
        }
    }

    func associateTo<Key: Hashable, Value>(destination: [Key: Value], transform: (Element) -> (Key, Value)) -> [Key: Value] {
        var dict = destination
        for element in self {
            let (key, value) = transform(element)
            dict[key] = value
        }
        return dict
    }

    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
    
    func sumOf(selector: (Element) -> Int) -> Int {
        var sum = 0
        for element in self {
            sum += selector(element)
        }
        return sum
    }

    func sumOf(selector: (Element) -> Int64) -> Int64 {
        var sum: Int64 = 0
        for element in self {
            sum += selector(element)
        }
        return sum
    }

    func sumOf(selector: (Element) -> Double) -> Double {
        var sum: Double = 0
        for element in self {
            sum += selector(element)
        }
        return sum
    }

    func mapOrNil<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult]? {
        var result = [ElementOfResult]()
        for element in self {
            guard let item = try transform(element) else {
                return nil
            }
            result.append(item)
        }
        return result
    }
}
