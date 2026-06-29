// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchPrompter",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NotchPrompter", targets: ["NotchPrompter"]),
    ],
    targets: [
        .executableTarget(
            name: "NotchPrompter",
            path: "NotchPrompter",
            exclude: [
                "Info.plist",
                "NotchPrompter.entitlements",
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"]),
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AuthenticationServices"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("QuartzCore"),
            ]
        ),
    ]
)
