import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import GraphQLParser

public enum CodegenErrors: Error {
    case missingQueryTypeName
    case missingQueryType
    
    case invalidType(String)
    
    case missingField(String)
    case missingLocationInfoInAST
    case TODO(String)
}

class Context {
    let serverUrl: String
    let schema: __Schema
    private let documents: [DocumentNode]
    private let rawDocuments: [String]

    init(serverUrl: String, schema: __Schema, documents: [DocumentNode], rawDocuments: [String]) {
        self.serverUrl = serverUrl
        self.schema = schema
        self.documents = documents
        self.rawDocuments = rawDocuments
    }
    
    var cur = 0
    var document: DocumentNode { self.documents[cur] }
    var rawDocument: String { self.rawDocuments[cur] }

    func next() -> Bool {
        if cur + 1 < documents.count {
            cur += 1
            return true
        }
        return false
    }
    
    var visitedTypes: Set<String> = Set()

    // data used for stdout
    var requiredCustomScalars: [String: (desc: String?, specifiedByURL: String?)] = [:]
}

func generateVisitedTypes(ctx: Context) throws -> [DeclSyntaxProtocol] {
    var decls: [DeclSyntaxProtocol] = []
    while let tpName = ctx.visitedTypes.popFirst() {
        guard let tp = ctx.schema.types.first(where: { $0.name == tpName }) else {
            throw CodegenErrors.invalidType(tpName)
        }
        switch tp.kind {
        case .SCALAR:
            if (isGraphQLBuiltInScalarType(str: tpName)) { continue }
            ctx.requiredCustomScalars[tpName] = (desc: tp.description, specifiedByURL: tp.specifiedByURL)
        case .INPUT_OBJECT:
            for field in tp.inputFields ?? [] {
                let innerTp = try getWrappedType(ctx: ctx, type: field.type)
                if let name = innerTp.name {
                    if (isGraphQLBuiltInScalarType(str: name)) { continue }
                    ctx.visitedTypes.insert(name)
                }
            }
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
                            leadingTrivia: field.description.map(generateCodeComment(description:)),
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
                            leadingTrivia: enumValue.description.map(generateCodeComment(description:)),
                            elements: [EnumCaseElementSyntax(name: TokenSyntax.identifier(safeFieldName(enumValue.name)))]
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

public func generate(serverUrl: String, schema: __Schema, query: String) async throws -> String {
    let parser = try await GraphQLParser()
    let document = try await parser.parse(source: query)
    return try await generate(serverUrl: serverUrl, schema: schema, documents: [document], rawDocuments: [query])
}

public func generate(serverUrl: String, schema: __Schema, documents: [DocumentNode], rawDocuments: [String]) async throws -> String {
    var operationModelDecls: [StructDeclSyntax] = []
    var clientClassFunDecls:[DeclSyntax] = []
    let ctx = Context(serverUrl: serverUrl, schema: schema, documents: documents, rawDocuments: rawDocuments)
    
    while true {
        let operations = ctx.document.definitions
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
        operationModelDecls.append(contentsOf: try operations.flatMap {
            try generateModelsForOperation(ctx: ctx, operation: $0)
        })
        clientClassFunDecls.append(contentsOf: try operations.map { try generateClientFuncForOperationDefinitionNode(ctx: ctx, operation: $0) })
        if (!ctx.next()) { break }
    }
    let schemaTypeDecls: [DeclSyntaxProtocol] = try generateVisitedTypes(ctx: ctx)
    
    let clientClassDecls = MemberBlockItemListSyntax(
        [
            .init(decl: DeclSyntax(
                """
                private let url: URL = URL(string: \(StringLiteralExprSyntax(content: ctx.serverUrl)))!
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
                private var requestInterceptor: ((inout URLRequest) -> Void)?
                """
            )),
            .init(decl: DeclSyntax(
                """
                /// Set custom request interceptor, the given closure would run before every request is sent. Most common use case is add authentication header
                public func setRequestInterceptor(_ interceptor: @escaping (inout URLRequest) -> Void) {
                    self.requestInterceptor = interceptor
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
            .init(decl: DeclSyntax(
                """
                private func sendRequest<RequestPayload: Codable, ResponsePayload: Codable>(payload: RequestPayload) async throws -> ResponsePayload {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(payload)
                    requestInterceptor?(&request)
                    let (data, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                    return try jsonDecoder.decode(GraphQLResponsePayload<ResponsePayload> .self, from: data).data
                }
                """
            )),
        ]
        +
        clientClassFunDecls.map { MemberBlockItemSyntax(decl: $0) }
    )
    var content = SourceFileSyntax {
        ImportDeclSyntax(
            path: [
                ImportPathComponentSyntax.init(name: TokenSyntax.identifier("Foundation"))
            ],
            trailingTrivia: .newlines(2)
        )
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
    
    let requiredCustomScalars = ctx.requiredCustomScalars.enumerated()
        .sorted(by: { $0.element.key < $1.element.key })
        .map { $0.element }
    if (requiredCustomScalars.count > 0) {
        print("Please implement custom scalars:")
        for (name, (desc, specifiedByURL)) in requiredCustomScalars {
            print("- \(name)")
            if let desc {
                print("  - description: \(desc)")
            }
            if let specifiedByURL {
                print("  - specifiedByURL: \(specifiedByURL)")
            }
        }
    }
    
    return content
}
