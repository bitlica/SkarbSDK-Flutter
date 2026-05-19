// swift-tools-version: 5.9
// Flutter Swift Package Manager manifest.
//
// Consumed by host apps with Flutter SPM mode enabled
// (`flutter config --enable-swift-package-manager`). The sibling podspec
// (`ios/skarb_plugin.podspec`) is retained only for Flutter's plugin
// discovery — dependencies live here.

import PackageDescription

let package = Package(
    name: "skarb_plugin",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "skarb-plugin",
            targets: ["skarb_plugin"]
        )
    ],
    dependencies: [
        // Native SkarbSDK iOS — SPM-native upstream, pulls grpc-swift /
        // swift-nio / swift-nio-ssl transitively. Pin to the same tag the
        // host Podfile previously used so the SPM and previous CocoaPods
        // paths stay version-aligned during migration.
        .package(
            url: "https://github.com/bitlica/SkarbSDK-iOS.git",
            from: "0.6.31"
        )
    ],
    targets: [
        .target(
            name: "skarb_plugin",
            dependencies: [
                .product(name: "SkarbSDK", package: "SkarbSDK-iOS")
            ]
        )
    ]
)
