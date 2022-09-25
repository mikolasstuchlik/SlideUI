// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SlideUI",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SlideUI", targets: ["SlideUI"]),
        .library(name: "SlideUIViews", targets: ["SlideUIViews"]),
        .library(name: "SlideUICommons", targets: ["SlideUICommons"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ZeeZide/CodeEditor.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(name: "DemoSlideUI", dependencies: []),
        .target(name: "SlideUIViews", dependencies: ["CodeEditor", "SlideUICommons", "SlideUI"]),
        .target(name: "SlideUI", dependencies: ["SlideUICommons"]),
        .target(name: "SlideUICommons")
    ]
)
