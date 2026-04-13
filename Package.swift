// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProPDF",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ProPDF",
            path: "ProPDF",
            exclude: ["App/Info.plist", "ProPDF.entitlements", "Resources/Assets.xcassets", "Resources/DefaultStamps"],
            resources: [
                .copy("Resources/Assets.xcassets")
            ]
        )
    ]
)
