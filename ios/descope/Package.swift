// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "descope",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "descope", targets: ["descope"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "descope",
            path: "Sources/descope",
            exclude: [
                "descope-swift-sdk/sdk/Callbacks.stencil"
            ]
        )
    ]
)
