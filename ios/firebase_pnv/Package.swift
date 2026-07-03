// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "firebase_pnv",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "firebase_pnv",
            targets: ["firebase_pnv"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "firebase_pnv",
            dependencies: [],
            path: "Sources/firebase_pnv"
        )
    ]
)
