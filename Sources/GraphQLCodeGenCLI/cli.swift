import Foundation
import ArgumentParser
import GraphQLCodeGen
import GraphQLParser

@main
struct GraphQLCodeGenCommand: AsyncParsableCommand {

    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "graphql-codegen",
        abstract: "GraphQL code generator for Swift"
    )
    
    @Option(name: .long, help: "GraphQL server URL")
    var schema: String

    @Option(name: .long, help: "Folder for GraphQL documents, scan happens recursively", completion: .directory)
    var documents: String
    
    @Option(name: .long, help: "Folder for generated code outputs", completion: .directory)
    var output: String
    
    func run() async throws {
        // STEP1: Send introspection query
        let schema = try await sendIntrospectionRequest(url: schema)
        // STEP2: Scan documents with suffix graphql
        let fileManager = FileManager.default
        let currentPath = FileManager.default.currentDirectoryPath
        let documentsFolderURL = URL(fileURLWithPath: currentPath).appendingPathComponent(documents)
        let documents = try fileManager.contentsOfDirectory(at: documentsFolderURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "graphql" }
        // STEP3: Parse and generate code
        let parser = try await GraphQLParser()
        var nodes: [DocumentNode] = []
        for document in documents {
            let content = try String(contentsOf: document, encoding: .utf8)
            let documentNode = try await parser.parse(source: content)
            nodes.append(documentNode)
        }
        let mergedDocument = DocumentNode(loc: nil, definitions: nodes.flatMap { $0.definitions })
        let generatedCode = try await generate(schema: schema, document: mergedDocument)
        // STEP4: Write generated code to target folder
        let outputFolderURL = URL(fileURLWithPath: currentPath).appendingPathComponent(output)
        try generatedCode.write(to: outputFolderURL.appendingPathComponent("graphql.swift", isDirectory: false), atomically: true, encoding: .utf8)
    }
}

