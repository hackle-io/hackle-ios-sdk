//
//  HackleAbTestViewController.swift
//  Hackle
//
//  Created by yong on 2023/03/28.
//

import UIKit


class HackleAbTestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, OnOverrideSetListener, OnOverrideResetListener, HackleUserExplorerContainer {

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let resetAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset all", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let abTestTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorColor = UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var explorer: HackleUserExplorer!
    private var items: [HackleAbTestItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setUpTableView()
        fetchAndUpdate()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(headerView)
        view.addSubview(abTestTableView)
        headerView.addSubview(resetAllButton)
        
        // Setup button action
        resetAllButton.addTarget(self, action: #selector(resetAllButtonTapped), for: .touchUpInside)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Header view constraints
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),
            
            // Reset button constraints
            resetAllButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            resetAllButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            resetAllButton.widthAnchor.constraint(equalToConstant: 60),
            resetAllButton.heightAnchor.constraint(equalToConstant: 25),
            
            // Table view constraints
            abTestTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            abTestTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            abTestTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            abTestTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setUpTableView() {
        abTestTableView.delegate = self
        abTestTableView.dataSource = self
        abTestTableView.register(HackleAbTestTableViewCell.self, forCellReuseIdentifier: "HackleAbTestTableViewCell")
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

    @objc private func resetAllButtonTapped(_ sender: UIButton) {
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

