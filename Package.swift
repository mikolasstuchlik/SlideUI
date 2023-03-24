// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SlideUI",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SlideUI", targets: ["SlideUI"]),
        .library(name: "SlideUIViews", targets: ["SlideUIViews"]),
        .library(name: "SlideUICommons", targets: ["SlideUICommons"]),
        .library(name: "SlideVaporized", targets: ["SlideVaporized"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ZeeZide/CodeEditor.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/johnsundell/ink.git", from: "0.1.0")
    ],
    targets: [
        .target(name: "SlideUIViews", dependencies: ["CodeEditor", "SlideUICommons", "SlideUI"]),
        .target(
            name: "SlideUI",
            dependencies: ["SlideUICommons"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "SlideVaporized",
            dependencies: [
                "SlideUICommons",
                "SlideUI",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Ink", package: "Ink"),
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "SlideUICommons")
    ]
)
