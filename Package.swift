// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "URLCatcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "URLCatcher",
            path: "URLCatcher"
        )
    ]
)
