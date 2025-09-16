//
//  HackleFeatureFlagTableViewCell.swift
//  Hackle
//
//  Created by yong on 2023/03/29.
//

import UIKit


class HackleFeatureFlagTableViewCell: UITableViewCell {

    // UI Elements - Created programmatically
    private lazy var experimentKeyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var experimentDescLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(red: 0.627, green: 0.627, blue: 0.627, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var variationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Button", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(variationButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(resetButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    private var item: HackleFeatureFlagItem!
    private var overrideSetListener: OnOverrideSetListener!
    private var overrideResetListener: OnOverrideResetListener!
    private var superView: UIViewController!
    private var alertController: UIAlertController!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        // Add subviews
        contentView.addSubview(experimentKeyLabel)
        contentView.addSubview(experimentDescLabel)
        contentView.addSubview(variationButton)
        contentView.addSubview(resetButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // experimentKeyLabel constraints
            experimentKeyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            experimentKeyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            experimentKeyLabel.widthAnchor.constraint(equalToConstant: 160),
            
            // experimentDescLabel constraints
            experimentDescLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            experimentDescLabel.topAnchor.constraint(equalTo: experimentKeyLabel.bottomAnchor, constant: 4),
            
            // resetButton constraints (positioned first to establish right margin)
            resetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            resetButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 60),
            resetButton.heightAnchor.constraint(equalToConstant: 25),
            
            // variationButton constraints
            variationButton.trailingAnchor.constraint(equalTo: resetButton.leadingAnchor, constant: -4),
            variationButton.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor),
            variationButton.widthAnchor.constraint(equalToConstant: 60),
            variationButton.heightAnchor.constraint(equalToConstant: 25),
            
            // Ensure experimentKeyLabel doesn't overlap with buttons
            experimentKeyLabel.trailingAnchor.constraint(equalTo: variationButton.leadingAnchor, constant: -12)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }

    func bind(
        item: HackleFeatureFlagItem,
        superView: UIViewController,
        overrideSetListener: OnOverrideSetListener,
        overrideResetListener: OnOverrideResetListener
    ) {
        self.item = item
        self.superView = superView
        self.overrideSetListener = overrideSetListener
        self.overrideResetListener = overrideResetListener

        experimentKeyLabel.text = item.keyLabel
        experimentKeyLabel.lineBreakMode = .byTruncatingTail
        experimentDescLabel.text = item.descLabel
        resetButton.isEnabled = item.overriddenVariation != nil
        initVariationButton()
    }

    private func initVariationButton() {
        variationButton.setTitle(String(item.decision.isOn), for: .normal)
        variationButton.isEnabled = DecisionReasons.isOverridable(reason: item.decision.reason)
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        for variation in item.experiment.variations {
            alertController.addAction(
                UIAlertAction(title: String(variation.isOn), style: .default) { _ in
                    self.onOverrideSelected(variation: variation)
                }
            )
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    }

    @IBAction func variationButtonTapped(_ sender: UIButton) {
        superView.present(alertController, animated: true)
    }

    @IBAction func resetButtonTapped(_ sender: UIButton) {
        guard let text = variationButton.titleLabel?.text, let isOn = Bool(text) else {
            return
        }
        guard let variation = item.experiment.variations.first(where: { it in it.isOn == isOn }) else {
            return
        }
        overrideResetListener.onOverrideReset(experiment: item.experiment, variation: variation)
    }

    private func onOverrideSelected(variation: Variation) {
        guard let variation = item.experiment.getVariationOrNil(variationId: variation.id) else {
            return
        }
        overrideSetListener.onOverrideSet(experiment: item.experiment, variation: variation)
        variationButton.setTitle(String(variation.isOn), for: .normal)
    }
}

private extension HackleFeatureFlagItem {
    var keyLabel: String {
        "[\(experiment.key)] \(experiment.name ?? "")"
    }

    var descLabel: String {
        "\(experiment.status.rawValue) | \(experiment.identifierType)"
    }
}

private extension Variation {
    var isOn: Bool {
        key != "A"
    }
}
