// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TZImagePickerController",
    defaultLocalization: "en",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "TZImagePickerController",
            targets: ["TZImagePickerController"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TZImagePickerController",
            path: ".",
            sources: [
                "TZImagePickerController/TZImagePickerController",
                "TZImagePickerController/Location"
            ],
            resources: [
                .process("TZImagePickerController/Resources/TZImagePickerController.bundle"),
                .process("TZImagePickerControllerFramework/PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "TZImagePickerController/TZImagePickerController",
            linkerSettings: [
                .linkedFramework("Photos"),
                .linkedFramework("PhotosUI")
            ]
        )
    ]
)
