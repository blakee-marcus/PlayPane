// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PlayPane",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PlayPane", targets: ["PlayPane"])],
    targets: [.executableTarget(name: "PlayPane", path: "Sources/PlayPane")],
    swiftLanguageModes: [.v6]
)
