// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PainTrackerKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PainTrackerKit", targets: ["PainTrackerKit"]),
    ],
    targets: [
        .target(name: "PainTrackerKit"),
        .testTarget(name: "PainTrackerKitTests", dependencies: ["PainTrackerKit"]),
    ]
)
