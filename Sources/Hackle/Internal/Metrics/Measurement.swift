//
//  Measurement.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation

class Measurement {

    let field: MetricField
    var value: Double {
        valueSupplier()
    }

    private let valueSupplier: () -> Double

    init(field: MetricField, valueSupplier: @escaping () -> Double) {
        self.field = field
        self.valueSupplier = valueSupplier
    }
}
