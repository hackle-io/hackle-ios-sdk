//
//  PropertyOperator.swift
//  Hackle
//
//  Created by yong on 2023/05/12.
//

import Foundation


protocol PropertyOperator {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any]
}

class PropertySetOperator: PropertyOperator {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any] {
        if base.isEmpty {
            return properties
        }
        if properties.isEmpty {
            return base
        }
        return base.toBuilder().add(properties).build()
    }
}

class PropertySetOnceOperator: PropertyOperator {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any] {
        if base.isEmpty {
            return properties
        }
        if properties.isEmpty {
            return base
        }
        return base.toBuilder().add(properties, setOnce: true).build()
    }
}

class PropertyUnsetOperator: PropertyOperator {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any] {
        if base.isEmpty {
            return [:]
        }
        if properties.isEmpty {
            return base
        }
        return base.toBuilder().remove(properties).build()
    }
}

class PropertyIncrementOperator: PropertyOperator {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any] {
        if properties.isEmpty {
            return base
        }

        let builder = base.toBuilder()
        for (key, value) in properties {
            builder.compute(key) { it in
                operate(baseValue: it, valueToIncrement: value)
            }
        }
        return builder.build()
    }

    private func operate(baseValue: Any?, valueToIncrement: Any) -> Any? {

        guard let value = HackleValue(value: valueToIncrement).doubleOrNil else {
            return baseValue
        }

        guard let base = baseValue else {
            return value
        }

        guard let baseNumber = HackleValue(value: base).doubleOrNil else {
            return base
        }

        return baseNumber + value
    }
}

protocol ArrayPropertyOperator: PropertyOperator {
    func operate(base: [Any], values: [Any]) -> [Any]
}

extension ArrayPropertyOperator {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any] {
        if properties.isEmpty {
            return base
        }

        let builder = base.toBuilder()
        for (key, value) in properties {
            builder.compute(key) { baseValue in
                compute(baseValue: baseValue, valueToOperate: value)
            }
        }
        return builder.build()
    }

    private func compute(baseValue: Any?, valueToOperate: Any) -> [Any] {
        let base = toArray(value: baseValue)
        let values = toArray(value: valueToOperate)
        return operate(base: base, values: values)
    }

    private func toArray(value: Any?) -> [Any] {
        guard let value = value else {
            return []
        }
        if let value = value as? [Any] {
            return value
        }
        return [value]
    }

    func contains(base: [Any], value: Any) -> Bool {
        base.contains { it in
            PropertyOperators.equals(it, value)
        }
    }
}

class PropertyAppendOperator: ArrayPropertyOperator {
    func operate(base: [Any], values: [Any]) -> [Any] {
        base + values
    }
}

class PropertyAppendOnceOperator: ArrayPropertyOperator {
    func operate(base: [Any], values: [Any]) -> [Any] {
        var base = base
        for value in values {
            if !contains(base: base, value: value) {
                base.append(value)
            }
        }
        return base
    }
}

class PropertyPrependOperator: ArrayPropertyOperator {
    func operate(base: [Any], values: [Any]) -> [Any] {
        values + base
    }
}

class PropertyPrependOnceOperator: ArrayPropertyOperator {
    func operate(base: [Any], values: [Any]) -> [Any] {
        var array = [Any]()
        for value in values {
            if !contains(base: array, value: value) && !contains(base: base, value: value) {
                array.append(value)
            }
        }
        return array + base
    }
}

class PropertyRemoveOperator: ArrayPropertyOperator {
    func operate(base: [Any], values: [Any]) -> [Any] {
        var array = [Any]()
        for value in base {
            if !contains(base: values, value: value) {
                array.append(value)
            }
        }
        return array
    }
}

class PropertyClearAllOperator: PropertyOperator {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any] {
        [:]
    }
}


class PropertyOperators {

    private static let set = PropertySetOperator()
    private static let setOnce = PropertySetOnceOperator()
    private static let unset = PropertyUnsetOperator()
    private static let increment = PropertyIncrementOperator()
    private static let append = PropertyAppendOperator()
    private static let appendOnce = PropertyAppendOnceOperator()
    private static let prepend = PropertyPrependOperator()
    private static let prependOnce = PropertyPrependOnceOperator()
    private static let remove = PropertyRemoveOperator()
    private static let clearAll = PropertyClearAllOperator()

    static func get(operation: PropertyOperation) -> PropertyOperator {
        switch operation {
        case .set: return PropertyOperators.set
        case .setOnce: return PropertyOperators.setOnce
        case .unset: return PropertyOperators.unset
        case .increment: return PropertyOperators.increment
        case .append: return PropertyOperators.append
        case .appendOnce: return PropertyOperators.appendOnce
        case .prepend: return PropertyOperators.prepend
        case .prependOnce: return PropertyOperators.prependOnce
        case .remove: return PropertyOperators.remove
        case .clearAll: return PropertyOperators.clearAll
        }
    }

    static func equals(_ a: Any, _ b: Any) -> Bool {
        let a = HackleValue(value: a)
        let b = HackleValue(value: b)

        if let a = a.doubleOrNil, let b = b.doubleOrNil {
            return a == b
        }

        return a == b
    }
}

extension PropertyOperation {
    func operate(base: [String: Any], properties: [String: Any]) -> [String: Any] {
        let propertyOperator = PropertyOperators.get(operation: self)
        return propertyOperator.operate(base: base, properties: properties)
    }
}

extension PropertyOperations {
    func operate(base: [String: Any]) -> [String: Any] {
        var accumulator = base
        for (operation, properties) in asDictionary() {
            accumulator = operation.operate(base: accumulator, properties: properties)
        }
        return accumulator
    }
}
