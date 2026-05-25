// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BrowserRouter",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "BrowserRouter",
            path: "BrowserRouter"
        )
    ]
)
