// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZLPhotoBrowser",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "ZLPhotoBrowser",
            targets: ["ZLPhotoBrowser"]
        ),
    ],
    targets: [
        .target(
            name: "ZLPhotoBrowser",
            exclude: [
                "Info.plist",
                "General/ZLWeakProxy.h",
                "General/ZLWeakProxy.m"
            ],
            resources: [
                .process("ZLPhotoBrowser.bundle"),
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "ZLPhotoBrowserTests",
            dependencies: ["ZLPhotoBrowser"]
        ),
    ]
)
