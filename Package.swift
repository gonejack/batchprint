// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BatchPrint",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BatchPrint", targets: ["BatchPrint"])
    ],
    targets: [
        .executableTarget(
            name: "BatchPrint",
            path: "Sources/BatchPrint"
        )
    ]
)
