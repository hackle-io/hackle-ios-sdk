//
// Created by yong on 2020/12/23.
//

import Foundation

extension Array {

    func associate<Key: Hashable, Value>(transform: (Element) -> (Key, Value)) -> [Key: Value] {
        associateTo(destination: [Key: Value](), transform: transform)
    }

    func associateBy<Key: Hashable>(keySelector: (Element) -> Key) -> [Key: Element] {
        associateTo(destination: [Key: Element]()) { it in
            (keySelector(it), it)
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
}
