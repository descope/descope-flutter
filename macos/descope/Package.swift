// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "descope",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "descope", targets: ["descope"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "descope",
            path: "Sources/descope"
        )
    ]
)
