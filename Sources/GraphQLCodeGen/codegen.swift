import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import GraphQLParser

enum CodegenErrors: Error {
    case missingQueryTypeName
    case missingQueryType
    
    case invalidType(String)
    
    case missingField(String)
    case TODO
}

public class Context {
    let schema: __Schema
    let document: DocumentNode
    
    init(schema: __Schema, document: DocumentNode) {
        self.schema = schema
        self.document = document
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
    return try await generate(schema: schema, document: document)
}

public func generate(schema: __Schema, document: DocumentNode) async throws -> String {
    let ctx = Context(schema: schema, document: document)
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
    let schemaTypeDecls = try generateTypesInSchema(ctx: ctx)
    let operationModelDecls: [StructDeclSyntax] = try operations.flatMap {
        try generateModelsForOperation(ctx: ctx, operation: $0)
    }
    let source = SourceFileSyntax {
        for schemaTypeDecl in schemaTypeDecls { schemaTypeDecl }
        for operationModelDecl in operationModelDecls { operationModelDecl }
    }
    return source.formatted().description + "\n"
}
