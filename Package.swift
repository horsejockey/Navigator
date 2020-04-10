// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Navigator",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Navigator",
            targets: ["Navigator"]),
    ],
    dependencies: [
        .package(
             name: "Reactor",
             url: "https://github.com/horsejockey/Reactor-iOS",
             .branch("swift-package")
        ),
    ],
    targets: [
        .target(
            name: "Navigator",
            dependencies: ["Reactor"]),
        .testTarget(
            name: "NavigatorTests",
            dependencies: ["Navigator"]),
    ]
)
