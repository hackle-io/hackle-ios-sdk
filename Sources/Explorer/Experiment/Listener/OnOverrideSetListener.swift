//
//  OnOverrideSetListener.swift
//  Hackle
//
//  Created by yong on 2023/03/29.
//

import Foundation
import Hackle

protocol OnOverrideSetListener {
    func onOverrideSet(experiment: Experiment, variation: Variation)
}
