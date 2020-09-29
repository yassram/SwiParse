// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SwiParse",
    products: [
        .library(name: "SwiParse", targets: ["SwiParse"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yassram/SwiLex.git", .upToNextMinor(from: "1.1.0")),
    ],
    targets: [
        .target(name: "SwiParse", dependencies: ["SwiLex"]),
        .testTarget(name: "SwiParseTests", dependencies: ["SwiParse"]),
    ]
)
