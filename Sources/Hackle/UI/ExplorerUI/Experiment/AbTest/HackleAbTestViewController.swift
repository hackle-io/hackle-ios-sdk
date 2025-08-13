//
//  HackleAbTestViewController.swift
//  Hackle
//
//  Created by yong on 2023/03/28.
//

import UIKit


class HackleAbTestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, OnOverrideSetListener, OnOverrideResetListener, HackleUserExplorerContainer {

    @IBOutlet weak var abTestTableView: UITableView!

    private var explorer: HackleUserExplorer!
    private var items: [HackleAbTestItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        fetchAndUpdate()
    }

    private func setUpTableView() {
        abTestTableView.delegate = self
        abTestTableView.dataSource = self
        abTestTableView.register(UINib(nibName: "HackleAbTestTableViewCell", bundle: HackleInternalResources.bundle), forCellReuseIdentifier: "HackleAbTestTableViewCell")
    }

    private func fetchAndUpdate() {
        let decisions = explorer.getAbTestDecisions()
        let overrides = explorer.getAbTestOverrides()
        let items = HackleAbTestItem.of(decisions: decisions, overrides: overrides)
        update(items: items)
    }

    private func update(items: [HackleAbTestItem]) {
        self.items = items
        abTestTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HackleAbTestTableViewCell", for: indexPath) as! HackleAbTestTableViewCell
        let item = items[indexPath.row]
        cell.bind(item: item, superView: self, overrideSetListener: self, overrideResetListener: self)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }

    @IBAction func resetAllButtonTapped(_ sender: UIButton) {
        explorer.resetAllAbTestOverride()
        fetchAndUpdate()
    }

    func onOverrideSet(experiment: Experiment, variation: Variation) {
        explorer.setAbTestOverride(experiment: experiment, variation: variation)
        fetchAndUpdate()
    }

    func onOverrideReset(experiment: Experiment, variation: Variation) {
        explorer.resetAbTestOverride(experiment: experiment, variation: variation)
        fetchAndUpdate()
    }
    
    func setHackleUserExplorer(_ hackleUserExplorer: any HackleUserExplorer) {
        self.explorer = hackleUserExplorer
    }
}

