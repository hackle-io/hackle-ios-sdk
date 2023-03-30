// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Hackle",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(name: "Hackle", targets: ["Hackle"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0")),
        .package(url: "https://github.com/danielsaidi/Mockery.git", .upToNextMajor(from: "0.7.0")),
    ],
    targets: [
        .target(
            name: "Hackle",
            resources: [
                .process("Explorer/Resources/HackleAbTestTableViewCell.xib"),
                .process("Explorer/Resources/HackleAbTestViewController.xib"),
                .process("Explorer/Resources/HackleFeatureFlagTableViewCell.xib"),
                .process("Explorer/Resources/HackleFeatureFlagViewController.xib"),
                .process("Explorer/Resources/HackleUserExplorerButton.xib"),
                .process("Explorer/Resources/HackleUserExplorerBubbleView.xib"),
                .process("Explorer/Resources/Images/hackle_banner.png"),
                .process("Explorer/Resources/Images/hackle_banner@2x.png"),
                .process("Explorer/Resources/Images/hackle_banner@3x.png"),
                .process("Explorer/Resources/Images/hackle_cancel.png"),
                .process("Explorer/Resources/Images/hackle_cancel@2x.png"),
                .process("Explorer/Resources/Images/hackle_cancel@3x.png"),
                .process("Explorer/Resources/Images/hackle_logo.png"),
                .process("Explorer/Resources/Images/hackle_logo@2x.png"),
                .process("Explorer/Resources/Images/hackle_logo@3x.png"),
            ]
        ),
        .testTarget(
            name: "HackleTests",
            dependencies: ["Hackle", "Quick", "Nimble", "Mockery"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
