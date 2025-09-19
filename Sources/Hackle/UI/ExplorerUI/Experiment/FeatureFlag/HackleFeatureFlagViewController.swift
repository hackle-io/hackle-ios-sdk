//
//  HackleFeatureFlagViewController.swift
//  Hackle
//
//  Created by yong on 2023/03/29.
//

import UIKit


class HackleFeatureFlagViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, OnOverrideSetListener, OnOverrideResetListener, HackleUserExplorerContainer {

    // iOS 10 compatibility - safe area layout guide alternatives
    private var safeAreaAnchors: SafeAreaAnchors!

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let resetAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset All", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorColor = UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var explorer: HackleUserExplorer!
    private var items: [HackleFeatureFlagItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        safeAreaAnchors = configureSafeAreaAnchors()
        setupUI()
        setUpTableView()
        fetchAndUpdate()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(headerView)
        view.addSubview(tableView)
        headerView.addSubview(resetAllButton)

        // Setup button action
        resetAllButton.addTarget(self, action: #selector(resetAllButtonTapped), for: .touchUpInside)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Header view constraints
            headerView.topAnchor.constraint(equalTo: safeAreaAnchors.top),
            headerView.leadingAnchor.constraint(equalTo: safeAreaAnchors.leading),
            headerView.trailingAnchor.constraint(equalTo: safeAreaAnchors.trailing),
            headerView.heightAnchor.constraint(equalToConstant: 40),
            
            // Reset button constraints
            resetAllButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            resetAllButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            resetAllButton.widthAnchor.constraint(equalToConstant: 60),
            resetAllButton.heightAnchor.constraint(equalToConstant: 25),
            
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeAreaAnchors.leading),
            tableView.trailingAnchor.constraint(equalTo: safeAreaAnchors.trailing),
            tableView.bottomAnchor.constraint(equalTo: safeAreaAnchors.bottom)
        ])
    }


    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HackleFeatureFlagTableViewCell.self, forCellReuseIdentifier: "HackleFeatureFlagTableViewCell")
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

    @objc private func resetAllButtonTapped(_ sender: UIButton) {
        explorer.resetAllFeatureFlagOverride()
        fetchAndUpdate()
    }

    func onOverrideSet(experiment: Experiment, variation: Variation) {
        explorer.setFeatureFlagOverride(experiment: experiment, variation: variation)
        fetchAndUpdate()
    }

    func onOverrideReset(experiment: Experiment, variation: Variation) {
        explorer.resetFeatureFlagOverride(experiment: experiment, variation: variation)
        fetchAndUpdate()
    }
    
    
    func setHackleUserExplorer(_ hackleUserExplorer: any HackleUserExplorer) {
        self.explorer = hackleUserExplorer
    }
}
