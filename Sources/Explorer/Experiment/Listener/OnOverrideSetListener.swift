//
//  OnOverrideSetListener.swift
//  Hackle
//
//  Created by yong on 2023/03/29.
//

import Foundation


protocol OnOverrideSetListnenr {
    func onOverrideSet(experiment: Experiment, variation: Variation)
}
