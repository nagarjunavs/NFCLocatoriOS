// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NFCLocatorCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        // Not a shipping target — declared only so `swift build`/`swift test` on this Mac
        // (which builds for the host platform) can resolve SwiftData's macOS 14 availability.
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "NFCLocatorCore",
            targets: ["NFCLocatorCore"]
        )
    ],
    targets: [
        .target(
            name: "NFCLocatorCore",
            path: "NFCLocatorCore/Sources/NFCLocatorCore",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "NFCLocatorCoreTests",
            dependencies: ["NFCLocatorCore"],
            path: "NFCLocatorCore/Tests/NFCLocatorCoreTests"
        )
    ]
)
