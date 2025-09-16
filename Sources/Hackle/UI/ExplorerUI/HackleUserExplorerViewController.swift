//
//  HackleUserExplorerViewController.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import UIKit


class HackleUserExplorerViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, HackleUserExplorerContainer {

    // Header View
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let hackleLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "hackle_banner.png", in: HackleInternalResources.bundle, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let dismissButton: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "hackle_cancel.png", in: HackleInternalResources.bundle, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // Info Section
    private let infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let defaultIdTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "ID"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let defaultIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deviceIdTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "DEVICE ID"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deviceIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userIdTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "USER ID"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pushTokenTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "PUSH TOKEN"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pushTokenLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let defaultIdCopyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private let deviceIdCopyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private let userIdCopyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private let pushTokenCopyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private let copiedLabel: UILabel = {
        let label = UILabel()
        label.text = "Copied"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Tab Section
    private let tabView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let abTestButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("A/B Test", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let featureFlagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Feature Flag", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // Content Section
    private let experimentPageView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Separators - individual named variables for better maintainability
    private let headerSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let infoSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tabSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var experimentPageViewController: UIPageViewController!
    private var abTestViewController: HackleAbTestViewController!
    private var featureFlagViewController: HackleFeatureFlagViewController!

    internal var explorer: HackleUserExplorer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initDismissButton()
        initUser()
        initPageView()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add all subviews
        view.addSubview(headerView)
        view.addSubview(headerSeparator)
        view.addSubview(infoView)
        view.addSubview(infoSeparator)
        view.addSubview(tabView)
        view.addSubview(tabSeparator)
        view.addSubview(experimentPageView)
        
        // Header subviews
        headerView.addSubview(hackleLogoImageView)
        headerView.addSubview(dismissButton)
        
        // Info section subviews
        infoView.addSubview(defaultIdTitleLabel)
        infoView.addSubview(defaultIdLabel)
        infoView.addSubview(defaultIdCopyButton)
        
        infoView.addSubview(deviceIdTitleLabel)
        infoView.addSubview(deviceIdLabel)
        infoView.addSubview(deviceIdCopyButton)
        
        infoView.addSubview(userIdTitleLabel)
        infoView.addSubview(userIdLabel)
        infoView.addSubview(userIdCopyButton)
        
        infoView.addSubview(pushTokenTitleLabel)
        infoView.addSubview(pushTokenLabel)
        infoView.addSubview(pushTokenCopyButton)
        
        infoView.addSubview(copiedLabel)
        
        
        // Tab section subviews
        tabView.addSubview(abTestButton)
        tabView.addSubview(featureFlagButton)
        
        // Setup button actions
        defaultIdCopyButton.addTarget(self, action: #selector(defaultIdCopyTapped), for: .touchUpInside)
        deviceIdCopyButton.addTarget(self, action: #selector(deviceIdCopyTapped), for: .touchUpInside)
        userIdCopyButton.addTarget(self, action: #selector(userIdCopyTapped), for: .touchUpInside)
        pushTokenCopyButton.addTarget(self, action: #selector(pushTokenCopyTapped), for: .touchUpInside)
        
        abTestButton.addTarget(self, action: #selector(abTestButtonTapped), for: .touchUpInside)
        featureFlagButton.addTarget(self, action: #selector(featureFlagButtonTapped), for: .touchUpInside)
        
        // Set initial tab selection state - A/B Test selected with underline
        abTestButton.setTitleColor(.black, for: .normal)
        featureFlagButton.setTitleColor(.lightGray, for: .normal)
        
        // Add selection underline to initially selected A/B Test tab
        DispatchQueue.main.async {
            self.addInitialSelectionUnderline()
        }
        
        // Setup Auto Layout constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header View constraints
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 48),
            
            // Hackle Logo constraints
            hackleLogoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            hackleLogoImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            hackleLogoImageView.widthAnchor.constraint(equalToConstant: 153),
            hackleLogoImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Dismiss Button constraints
            dismissButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            dismissButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 20),
            dismissButton.heightAnchor.constraint(equalToConstant: 20),
            
            // Info View constraints - increased height to prevent push token cutoff
            infoView.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor, constant: 12),
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 220),
            
            // Default ID section - fixed positioning
            defaultIdTitleLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 8),
            defaultIdTitleLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            
            defaultIdLabel.topAnchor.constraint(equalTo: defaultIdTitleLabel.bottomAnchor, constant: 4),
            defaultIdLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            defaultIdLabel.trailingAnchor.constraint(equalTo: defaultIdCopyButton.leadingAnchor, constant: -8),
            defaultIdLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
            
            defaultIdCopyButton.centerYAnchor.constraint(equalTo: defaultIdTitleLabel.centerYAnchor),
            defaultIdCopyButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -12),
            defaultIdCopyButton.widthAnchor.constraint(equalToConstant: 60),
            defaultIdCopyButton.heightAnchor.constraint(equalToConstant: 25),
            
            // Device ID section - fixed positioning relative to infoView top
            deviceIdTitleLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 55),
            deviceIdTitleLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            
            deviceIdLabel.topAnchor.constraint(equalTo: deviceIdTitleLabel.bottomAnchor, constant: 4),
            deviceIdLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            deviceIdLabel.trailingAnchor.constraint(equalTo: deviceIdCopyButton.leadingAnchor, constant: -8),
            deviceIdLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
            
            deviceIdCopyButton.centerYAnchor.constraint(equalTo: deviceIdTitleLabel.centerYAnchor),
            deviceIdCopyButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -12),
            deviceIdCopyButton.widthAnchor.constraint(equalToConstant: 60),
            deviceIdCopyButton.heightAnchor.constraint(equalToConstant: 25),
            
            // User ID section - fixed positioning relative to infoView top
            userIdTitleLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 102),
            userIdTitleLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            
            userIdLabel.topAnchor.constraint(equalTo: userIdTitleLabel.bottomAnchor, constant: 4),
            userIdLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            userIdLabel.trailingAnchor.constraint(equalTo: userIdCopyButton.leadingAnchor, constant: -8),
            userIdLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
            
            userIdCopyButton.centerYAnchor.constraint(equalTo: userIdTitleLabel.centerYAnchor),
            userIdCopyButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -12),
            userIdCopyButton.widthAnchor.constraint(equalToConstant: 60),
            userIdCopyButton.heightAnchor.constraint(equalToConstant: 25),
            
            // Push Token section - fixed positioning relative to infoView top
            pushTokenTitleLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 149),
            pushTokenTitleLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            
            pushTokenLabel.topAnchor.constraint(equalTo: pushTokenTitleLabel.bottomAnchor, constant: 4),
            pushTokenLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 12),
            pushTokenLabel.trailingAnchor.constraint(equalTo: pushTokenCopyButton.leadingAnchor, constant: -8),
            pushTokenLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
            
            pushTokenCopyButton.centerYAnchor.constraint(equalTo: pushTokenTitleLabel.centerYAnchor),
            pushTokenCopyButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -12),
            pushTokenCopyButton.widthAnchor.constraint(equalToConstant: 60),
            pushTokenCopyButton.heightAnchor.constraint(equalToConstant: 25),
            
            // Copied Label
            copiedLabel.centerXAnchor.constraint(equalTo: infoView.centerXAnchor),
            copiedLabel.topAnchor.constraint(equalTo: infoView.topAnchor),
            copiedLabel.widthAnchor.constraint(equalToConstant: 80),
            copiedLabel.heightAnchor.constraint(equalToConstant: 25),
            
            // Tab View constraints - reduced height for more compact appearance
            tabView.topAnchor.constraint(equalTo: infoSeparator.bottomAnchor, constant: 12),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabView.heightAnchor.constraint(equalToConstant: 36),
            
            // Tab buttons
            abTestButton.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            abTestButton.topAnchor.constraint(equalTo: tabView.topAnchor),
            abTestButton.bottomAnchor.constraint(equalTo: tabView.bottomAnchor),
            abTestButton.widthAnchor.constraint(equalToConstant: 120),
            
            featureFlagButton.leadingAnchor.constraint(equalTo: abTestButton.trailingAnchor),
            featureFlagButton.topAnchor.constraint(equalTo: tabView.topAnchor),
            featureFlagButton.bottomAnchor.constraint(equalTo: tabView.bottomAnchor),
            featureFlagButton.widthAnchor.constraint(equalToConstant: 120),
            
            // Experiment Page View constraints
            experimentPageView.topAnchor.constraint(equalTo: tabSeparator.bottomAnchor),
            experimentPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            experimentPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            experimentPageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Main Separator constraints
            headerSeparator.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            infoSeparator.topAnchor.constraint(equalTo: infoView.bottomAnchor),
            infoSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            infoSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            infoSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            tabSeparator.topAnchor.constraint(equalTo: tabView.bottomAnchor),
            tabSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabSeparator.heightAnchor.constraint(equalToConstant: 1),
            
        ])
    }

    private func initDismissButton() {
        dismissButton.isUserInteractionEnabled = true
        dismissButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func initUser() {
        let user = explorer.currentUser()
        if let defaultId = user.id {
            defaultIdLabel.text = defaultId
            defaultIdCopyButton.isEnabled = true
        } else {
            defaultIdLabel.text = "N/A"
            defaultIdCopyButton.isEnabled = false
        }

        if let deviceId = user.deviceId {
            deviceIdLabel.text = deviceId
            deviceIdCopyButton.isEnabled = true
        } else {
            deviceIdLabel.text = "N/A"
            deviceIdCopyButton.isEnabled = false
        }

        if let userId = user.userId {
            userIdLabel.text = userId
            userIdCopyButton.isEnabled = true
        } else {
            userIdLabel.text = "N/A"
            userIdCopyButton.isEnabled = false
        }
        
        if let pushToken = explorer.registeredPushToken() {
            pushTokenLabel.text = pushToken
            pushTokenCopyButton.isEnabled = true
        } else {
            pushTokenLabel.text = "N/A"
            pushTokenCopyButton.isEnabled = false
        }

        copiedLabel.alpha = 0
    }

    @objc private func defaultIdCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = defaultIdLabel.text
        showCopiedLabel()
    }

    @objc private func deviceIdCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = deviceIdLabel.text
        showCopiedLabel()
    }

    @objc private func userIdCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = userIdLabel.text
        showCopiedLabel()
    }
    
    @objc private func pushTokenCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = pushTokenLabel.text
        showCopiedLabel()
    }

    private func showCopiedLabel() {
        copiedLabel.alpha = 1
        UIView.animate(withDuration: 1, delay: 0, options: .transitionCrossDissolve) {
            self.copiedLabel.alpha = 0
        }
        Metrics.counter(name: "user.explorer.identifier.copy").increment()
    }

    private func initPageView() {
        experimentPageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        experimentPageViewController.view.backgroundColor = UIColor.white
        experimentPageViewController.delegate = self
        experimentPageViewController.dataSource = self
        experimentPageViewController.view.frame = experimentPageView.bounds

        addChild(experimentPageViewController)
        experimentPageView.addSubview(experimentPageViewController.view)

        abTestViewController = createController()
        featureFlagViewController = createController()
        select(experimentType: .abTest)
    }

    private func createController<T: UIViewController & HackleUserExplorerContainer>() -> T {
        let controller = T.init()
        controller.setHackleUserExplorer(explorer)
        addChild(controller)
        controller.view.frame = experimentPageView.bounds
        return controller
    }
    
    private func addChildController(_ child: UIViewController) {
        addChild(child)
        child.view.frame = experimentPageView.bounds
    }

    @objc private func abTestButtonTapped(_ sender: UIButton) {
        select(experimentType: .abTest)
    }

    @objc private func featureFlagButtonTapped(_ sender: UIButton) {
        select(experimentType: .featureFlag)
    }

    private func select(experimentType: ExperimentType) {
        switch experimentType {
        case .abTest:
            experimentPageViewController.setViewControllers([abTestViewController], direction: .reverse, animated: true)
            select(button: abTestButton)
            unselect(button: featureFlagButton)
        case .featureFlag:
            experimentPageViewController.setViewControllers([featureFlagViewController], direction: .forward, animated: true)
            select(button: featureFlagButton)
            unselect(button: abTestButton)
        }
    }

    private func select(button: UIButton) {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: button.frame.height - 2, width: button.frame.width, height: 2)
        layer.backgroundColor = UIColor.black.cgColor
        layer.name = "io.hackle.experiment.button.selected"
        button.layer.addSublayer(layer)
        button.isEnabled = false
        button.setTitleColor(UIColor.black, for: .normal)
    }
    

    private func unselect(button: UIButton) {
        button.layer.sublayers?
            .filter { it in
                it.name == "io.hackle.experiment.button.selected"
            }
            .forEach { it in
                it.removeFromSuperlayer()
            }
        button.isEnabled = true
        button.setTitleColor(UIColor.lightGray, for: .normal)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController == featureFlagViewController {
            return abTestViewController
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController == abTestViewController {
            return featureFlagViewController
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentViewController = pageViewController.viewControllers?.first {
            if currentViewController == abTestViewController {
                select(experimentType: .abTest)
            } else {
                select(experimentType: .featureFlag)
            }
        }
    }
    
    func setHackleUserExplorer(_ hackleUserExplorer: any HackleUserExplorer) {
        explorer = hackleUserExplorer
    }
    
    private func addInitialSelectionUnderline() {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: abTestButton.frame.height - 2, width: abTestButton.frame.width, height: 2)
        layer.backgroundColor = UIColor.black.cgColor
        layer.name = "io.hackle.experiment.button.selected"
        abTestButton.layer.addSublayer(layer)
        abTestButton.isEnabled = false
    }
}
