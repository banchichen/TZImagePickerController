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
            exclude: ["TZImagePickerController/TZImagePickerController/TZImagePickerController.bundle"],
            sources: [
                "TZImagePickerController/TZImagePickerController",
                "TZImagePickerController/Location"
            ],
            resources: [
                .process("TZImagePickerController/TZImagePickerController/TZImagePickerController.bundle"),
                .process("TZImagePickerControllerFramework/PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("Photos"),
                .linkedFramework("PhotosUI")
            ]
        )
    ]
)
