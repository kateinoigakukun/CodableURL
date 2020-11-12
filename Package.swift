// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CodableURL",
    products: [
        .library(name: "CodableURL", targets: ["CodableURL"]),
    ],
    targets: [
        .target(name: "CodableURL"),
        .testTarget(name: "CodableURLTests", dependencies: ["CodableURL"]),
    ]
)
