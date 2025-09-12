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
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMinor(from: "3.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMinor(from: "9.0.0")),
        .package(url: "https://github.com/danielsaidi/Mockery.git", from: "0.7.0"),
    ],
    targets: [
        .target(
            name: "Hackle",
            exclude: [
                "Hackle.h",
                "HackleNotification.h",
                "HackleNotification.m"
            ],
            resources: [
                .process("Resources/HackleAbTestTableViewCell.xib"),
                .process("Resources/HackleAbTestViewController.xib"),
                .process("Resources/HackleFeatureFlagTableViewCell.xib"),
                .process("Resources/HackleFeatureFlagViewController.xib"),
                .process("Resources/HackleUserExplorerViewController.xib"),
                .process("Resources/Images/hackle_banner.png"),
                .process("Resources/Images/hackle_banner@2x.png"),
                .process("Resources/Images/hackle_banner@3x.png"),
                .process("Resources/Images/hackle_cancel.png"),
                .process("Resources/Images/hackle_cancel@2x.png"),
                .process("Resources/Images/hackle_cancel@3x.png"),
                .process("Resources/Images/hackle_logo.png"),
                .process("Resources/Images/hackle_logo@2x.png"),
                .process("Resources/Images/hackle_logo@3x.png"),
                .copy("PrivacyInfo.xcprivacy")
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
