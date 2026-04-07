// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PetWidget",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "PetWidget",
            path: "Sources/PetWidget",
            resources: [
                .copy("Resources/sausage_dog_scenarios")
            ]
        )
    ]
)
