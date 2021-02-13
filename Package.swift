// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NotenikLib",
    platforms: [
        .macOS("10.12"),
        .iOS("9.0"),
        .tvOS("9.0")
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "NotenikLib",
            targets: ["NotenikLib"]),
    ],
    dependencies: [.package(url: "https://github.com/hbowie/NotenikUtils", from: "0.1.0"),
                   .package(url: "https://github.com/hbowie/NotenikMkdown", from: "0.1.0"),
                   .package(url: "https://github.com/hbowie/NotenikTextile", from: "0.1.0"),
                   .package(url: "https://github.com/johnxnguyen/Down", from: "0.9.0"),
                   .package(url: "https://github.com/JohnSundell/Ink", from: "0.3.0"),
                   .package(url: "https://github.com/CoreOffice/CoreXLSX.git", from: "0.13.0")
        ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "NotenikLib",
            dependencies: ["NotenikUtils", "NotenikMkdown", "NotenikTextile", "Down", "Ink", "CoreXLSX"]),
    ]
)
