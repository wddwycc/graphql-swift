// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "graphql-swift",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "GraphQLParser",
            targets: ["GraphQLParser"]),
        .library(
            name: "GraphQLCodeGen",
            targets: ["GraphQLCodeGen"]),
        .executable(
            name: "graphql-codegen",
            targets: ["GraphQLCodeGenCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.1"),
    ],
    targets: [
        // Core Libraries
        .target(
            name: "GraphQLParser",
            resources: [
                .process("Resources")
            ]
        ),
        .target(name: "GraphQLCodeGen", dependencies: [
            "GraphQLParser",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        ]),

        // graphql-codegen command line interface
        .executableTarget(name: "GraphQLCodeGenCLI", dependencies: [
            "GraphQLCodeGen",
        ]),
        
        // Examples
        .executableTarget(
            name: "codegen",
            dependencies: [],
            path: "Examples/codegen",
            exclude: [
                "README.md",
                "documents/",
            ]),
        
        // Tests
        .testTarget(name: "GraphQLParserTests", dependencies: ["GraphQLParser"]),
        .testTarget(name: "GraphQLCodeGenTests", dependencies: [
            "GraphQLCodeGen",
            "GraphQLParser",
        ]),
    ]
)
