import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import GraphQLParser

enum CodegenErrors: Error {
    case missingQueryTypeName
    case missingQueryType
    
    case invalidType(String)
    
    case missingField(String)
    case missingLocationInfoInAST
    case TODO
}

public class Context {
    let schema: __Schema
    let document: DocumentNode
    let rawDocument: String
    
    init(schema: __Schema, document: DocumentNode, rawDocument: String) {
        self.schema = schema
        self.document = document
        self.rawDocument = rawDocument
    }
}

private func generateTypesInSchema(ctx: Context) throws -> [DeclSyntaxProtocol] {
    var decls: [DeclSyntaxProtocol] = []
    for tp in ctx.schema.types {
        switch tp.kind {
        case .INPUT_OBJECT:
            decls.append(try StructDeclSyntax(
                modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                name: TokenSyntax.identifier(tp.name!),
                inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: [
                    .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("Codable"))),
                ]),
                memberBlockBuilder: {
                    for field in tp.inputFields ?? [] {
                        let swiftType = try convertSchemaTypeToSwiftType(ctx: ctx, type: field.type)
                        MemberBlockItemSyntax(
                            leadingTrivia: field.description.map { "/// \($0)\n" },
                            // NOTE: use var here to derive more flexibile initializer for the struct
                            decl: DeclSyntax("public var \(raw: safeFieldName(field.name)): \(swiftType)")
                        )
                    }
                }
            ))
        case .ENUM:
            decls.append(EnumDeclSyntax(
                modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                name: TokenSyntax.identifier(tp.name!),
                inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: [
                    .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("String")), trailingComma: TokenSyntax.commaToken()),
                    .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("Codable"))),
                ]),
                memberBlockBuilder: {
                    for enumValue in tp.enumValues! {
                        EnumCaseDeclSyntax(
                            leadingTrivia: enumValue.description.map { "/// \($0)\n" },
                            elements: [EnumCaseElementSyntax(name: TokenSyntax.identifier(enumValue.name))]
                        )
                    }
                }
            ))
        default:
            break
        }
    }
    return decls
}

public func generate(schema: __Schema, query: String) async throws -> String {
    let parser = try await GraphQLParser()
    let document = try await parser.parse(source: query)
    return try await generate(schema: schema, documents: [(document, query)])
}

public func generate(schema: __Schema, documents: [(DocumentNode, String)]) async throws -> String {
    var schemaTypeDecls: [DeclSyntaxProtocol] = []
    var operationModelDecls: [StructDeclSyntax] = []
    var clientClassFunDecls:[DeclSyntax] = []
    for (document, rawDocument) in documents {
        let ctx = Context(schema: schema, document: document, rawDocument: rawDocument)
        let operations = document.definitions
            .flatMap { a in
                if case let .executable(e) = a {
                    return [e]
                }
                return []
            }
            .flatMap { a in
                if case let .operation(o) = a {
                    return [o]
                }
                return []
            }
        schemaTypeDecls = try generateTypesInSchema(ctx: ctx)
        operationModelDecls.append(contentsOf: try operations.flatMap {
            try generateModelsForOperation(ctx: ctx, operation: $0)
        })
        clientClassFunDecls.append(contentsOf: try operations.map { try generateClientFuncForOperationDefinitionNode(ctx: ctx, operation: $0) })
    }
    
    let clientClassDecls = MemberBlockItemListSyntax(
        [
            .init(decl: DeclSyntax(
                """
                private let url: URL = URL(string: "https://countries.trevorblades.com")!
                """
            )),
            .init(decl: DeclSyntax(
                """
                private let session: URLSession
                """
            )),
            .init(decl: DeclSyntax(
                """
                private let jsonDecoder = JSONDecoder()
                """
            )),
            .init(decl: DeclSyntax(
                """
                private func sendRequest<RequestPayload: Codable, ResponsePayload: Codable>(payload: RequestPayload) async throws -> ResponsePayload {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(payload)
                    let (data, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                    return try jsonDecoder.decode(GraphQLResponsePayload<ResponsePayload> .self, from: data).data
                }
                """
            )),
            .init(decl: DeclSyntax(
                """
                public init() {
                    let config = URLSessionConfiguration.default
                    self.session = URLSession(configuration: config)
                }
                """
            )),
        ]
        +
        clientClassFunDecls.map { MemberBlockItemSyntax(decl: $0) }
    )
    var content = SourceFileSyntax {
        "import Foundation"
        for schemaTypeDecl in schemaTypeDecls { schemaTypeDecl }
        for operationModelDecl in operationModelDecls { operationModelDecl }
        """
        public struct GraphQLRequestSimplePayload: Codable {
            public let query: String
        }
        public struct GraphQLRequestPayload<T: Codable>: Codable {
            public let query: String
            public let variables: T
        }
        public struct GraphQLResponsePayload<T: Codable>: Codable {
            public let data: T
        }
        """
        ClassDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: "GraphQLClient",
            memberBlock: .init(members: clientClassDecls)
        )
    }.formatted().description
    content += "\n"
    return content
}
