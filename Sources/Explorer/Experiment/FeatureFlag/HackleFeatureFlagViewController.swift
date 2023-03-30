//
//  HackleFeatureFlagViewController.swift
//  Hackle
//
//  Created by yong on 2023/03/29.
//

import UIKit


class HackleFeatureFlagViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, OnOverrideSetListener, OnOverrideResetListener {

    @IBOutlet weak var tableView: UITableView!

    private var explorer: HackleUserExplorer!
    private var items: [HackleFeatureFlagItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        explorer = Hackle.app()?.userExplorer
        setUpTableView()
        fetchAndUpdate()
    }

    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "HackleFeatureFlagTableViewCell", bundle: Bundle(for: HackleFeatureFlagTableViewCell.self)), forCellReuseIdentifier: "HackleFeatureFlagTableViewCell")
    }

    private func fetchAndUpdate() {
        let decisions = explorer.getFeatureFlagDecisions()
        let overrides = explorer.getFeatureFlagOverrides()
        let items = HackleFeatureFlagItem.of(decisions: decisions, overrides: overrides)
        update(items: items)
    }

    private func update(items: [HackleFeatureFlagItem]) {
        self.items = items
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HackleFeatureFlagTableViewCell", for: indexPath) as! HackleFeatureFlagTableViewCell
        let item = items[indexPath.row]
        cell.bind(item: item, superView: self, overrideSetListener: self, overrideResetListener: self)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }

    @IBAction func resetAllButtonTapped(_ sender: UIButton) {
        explorer.resetAllFeatureFlagOverride()
        fetchAndUpdate()
    }

    func onOverrideSet(experiment: Experiment, variation: Variation) {
        explorer.setFeatureFlagOverride(experiment: experiment, variationId: variation.id)
        fetchAndUpdate()
    }

    func onOverrideReset(experiment: Experiment) {
        explorer.resetFeatureFlagOverride(experiment: experiment)
        fetchAndUpdate()
    }
}
