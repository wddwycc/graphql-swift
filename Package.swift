// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "graphql-swift",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GraphQLParser",
            targets: ["GraphQLParser"]),
        .library(
            name: "GraphQLCodeGen",
            targets: ["GraphQLCodeGen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GraphQLParser",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(name: "GraphQLParserTests", dependencies: ["GraphQLParser"]),
        
        .target(name: "GraphQLCodeGen", dependencies: [
            "GraphQLParser",
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        ]),
        .testTarget(name: "GraphQLCodeGenTests", dependencies: [
            "GraphQLCodeGen",
        ]),
    ]
)
