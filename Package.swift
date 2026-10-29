// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "QcSdkAnalysis", defaultLocalization: "en", platforms: [.iOS(.v17)],

    products: [
        .library(name: "QcSdkAnalysis", targets: ["QcSdkAnalysis", "QcSdkAnalysisSupport"])
    ],

    dependencies: [
        .package(url: "https://github.com/YuFengChen77/QcSdkCore.git", exact: "1.1.5"),
        .package(url: "https://github.com/adjust/ios_sdk", exact: "5.6.1"),
        .package(url: "https://github.com/ThinkingDataAnalytics/ios-sdk.git", exact: "3.6.2"),
        .package(url: "https://github.com/ThinkingDataAnalytics/thinkingdatacore-ios-sdk.git", exact: "1.3.8")
    ],

    targets: [
        .binaryTarget(name: "QcSdkAnalysis", url: "https://github.com/YuFengChen77/QcSdkAnalysis/releases/download/1.1.2/QcSdkAnalysis-1.1.2.xcframework.zip", checksum: "38e8cca27fd1d05ef2f0f5df1c6a97fbfbacce5f3524772a1c59f2f89993ec28"),

        .target(name: "QcSdkAnalysisSupport", dependencies: ["QcSdkAnalysis", .product(name: "QcSdkCore", package: "qcsdkcore"), .product(name: "AdjustSdk", package: "ios_sdk"), .product(name: "ThinkingDataCore", package: "thinkingdatacore-ios-sdk"), .product(name: "ThinkingSDK", package: "ios-sdk")], path: "QcSdkAnalysis", sources: ["Sources"], resources: [.process("Resources")], linkerSettings: [.linkedFramework("Security"), .linkedFramework("SystemConfiguration"), .linkedLibrary("z"), .linkedLibrary("sqlite3")])
    ]
)
