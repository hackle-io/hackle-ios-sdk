//
//  ContainerGroup.swift
//  Hackle
//
//  Created by yong on 2022/07/21.
//

import Foundation

protocol ContainerGroup {
    typealias Id = Int64

    var id: Id { get }
    var experiments: [Experiment.Id] { get }
}


class ContainerGroupEntity: ContainerGroup {

    let id: Id
    let experiments: [Experiment.Id]

    init(id: Id, experiments: [Experiment.Id]) {
        self.id = id
        self.experiments = experiments
    }
}
