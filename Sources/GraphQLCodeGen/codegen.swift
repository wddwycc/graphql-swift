//
//  File.swift
//  
//
//  Created by Wen Duan on 2024/04/27.
//

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

private func getQueryType(schema: __Schema) throws -> __Type {
    guard let queryTypeName = schema.queryType.name else {
        throw CodegenErrors.missingQueryTypeName
    }
    guard let queryType = schema.types.first(where: { $0.name == queryTypeName }) else {
        throw CodegenErrors.missingQueryType
    }
    return queryType
}

private func getSwiftType(ctx: Context, type: __Type, nonNull: Bool = false) throws -> TypeSyntaxProtocol {
    let tp: TypeSyntaxProtocol
    switch type.kind {
    case .SCALAR:
        // Ref: https://spec.graphql.org/October2021/#sec-Scalars
        switch type.name {
        // Built-in Scalars
        case "Int":
            tp = IdentifierTypeSyntax(name: TokenSyntax.identifier("Int64"))
        case "Float":
            tp = IdentifierTypeSyntax(name: TokenSyntax.identifier("Float64"))
        case "String", "ID":
            tp = IdentifierTypeSyntax(name: TokenSyntax.identifier("String"))
        case "Boolean":
            tp = IdentifierTypeSyntax(name: TokenSyntax.identifier("Bool"))
        default:
            // TODO: Support custom scalars
            // https://spec.graphql.org/October2021/#sec-Scalars.Custom-Scalars
            throw CodegenErrors.TODO
        }
    case .OBJECT:
        guard let name = type.name else { throw CodegenErrors.invalidType("Expect name for OBJECT type") }
        tp = IdentifierTypeSyntax(name: TokenSyntax.identifier(name))
    case .INTERFACE:
        throw CodegenErrors.TODO
    case .UNION:
        throw CodegenErrors.TODO
    case .ENUM:
        guard let name = type.name else { throw CodegenErrors.invalidType("Expect name for OBJECT type") }
        tp = IdentifierTypeSyntax(name: TokenSyntax.identifier(name))
    case .INPUT_OBJECT:
        throw CodegenErrors.TODO
    case .LIST:
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for LIST type") }
        tp = ArrayTypeSyntax(element: try getSwiftType(ctx: ctx, type: ofType))
    case .NON_NULL:
        if nonNull { throw CodegenErrors.invalidType("NON_NULL type cannot be nested") }
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for NON_NULL type") }
        return try getSwiftType(ctx: ctx, type: ofType, nonNull: true)
    }
    if (nonNull) {
        return tp
    }
    return OptionalTypeSyntax(wrappedType: tp)
}

private func getWrappedObjectType(ctx: Context, type: __Type) throws -> __Type {
    switch type.kind {
    case .SCALAR:
        throw CodegenErrors.TODO
    case .OBJECT:
        guard let name = type.name else { throw CodegenErrors.invalidType("Expect name for OBJECT type") }
        return ctx.schema.types.first(where: { $0.name == name })!
    case .INTERFACE:
        throw CodegenErrors.TODO
    case .UNION:
        throw CodegenErrors.TODO
    case .ENUM:
        throw CodegenErrors.TODO
    case .INPUT_OBJECT:
        throw CodegenErrors.TODO
    case .LIST:
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for LIST type") }
        return try getWrappedObjectType(ctx: ctx, type: ofType)
    case .NON_NULL:
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for NON_NULL type") }
        return try getWrappedObjectType(ctx: ctx, type: ofType)
    }

}

private func getFields(ctx: Context, selectionSet: SelectionSetNode, schemaType: __Type) throws -> [(FieldNode, __Type)] {
    try selectionSet.selections.flatMap {
        switch $0 {
        case .field(let field):
            if field.name.value == "__schema" {
                return [(field, ctx.schema.types.first(where: { $0.name == "__Schema" })!)]
            }
            guard let fieldInSchema = schemaType.fields?.first(where: { $0.name == field.name.value }) else {
                throw CodegenErrors.missingField(field.name.value)
            }
            return [(field, fieldInSchema.type)]
        case .fragmentSpread(let fragmentSpread):
            let fragmentName = fragmentSpread.name.value
            let fragmentNode = ctx.document.definitions
                .flatMap { a in
                    if case let .executable(e) = a {
                        return [e]
                    }
                    return []
                }
                .flatMap { a in
                    if case let .fragment(f) = a {
                        return [f]
                    }
                    return []
                }
                .first(where: { a in a.name.value == fragmentName })!
            let schemaType = ctx.schema.types.first(where: { $0.name == fragmentNode.typeCondition.name.value })!
            return try getFields(ctx: ctx, selectionSet: fragmentNode.selectionSet, schemaType: schemaType)
        case .inlineFragment(let inlineFragment):
            guard let fragmentName = inlineFragment.typeCondition?.name.value ?? schemaType.name else {
                throw CodegenErrors.missingQueryTypeName
            }
            let schemaType = ctx.schema.types.first(where: { $0.name == fragmentName })!
            return try getFields(ctx: ctx, selectionSet: inlineFragment.selectionSet, schemaType: schemaType)
        }
    }
}

private func generateStructBody(ctx: Context, selectionSet: SelectionSetNode, schemaType: __Type) throws -> MemberBlockItemListSyntax {
    let fields = try getFields(ctx: ctx, selectionSet: selectionSet, schemaType: schemaType)

    var declaredProperties = Set<String>()
    var declaredStructs = Set<String>()
    var body: [MemberBlockItemSyntax] = []
    for (field, fieldType) in fields {
        let swiftType = try getSwiftType(ctx: ctx, type: fieldType)
        if (!declaredProperties.contains(field.name.value)) {
            declaredProperties.insert(field.name.value)
            body.append(MemberBlockItemSyntax(decl: DeclSyntax("public let \(raw: field.name.value): \(swiftType)")))
        }
        if let nestedSelectionSet = field.selectionSet {
            let wrappedObjectType = try getWrappedObjectType(ctx: ctx, type: fieldType)
            if (!declaredStructs.contains(wrappedObjectType.name!)) {
                declaredStructs.insert(wrappedObjectType.name!)
                body.append(MemberBlockItemSyntax(decl: StructDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                    name: TokenSyntax.identifier(wrappedObjectType.name!),
                    memberBlock: MemberBlockSyntax(members: try generateStructBody(ctx: ctx, selectionSet: nestedSelectionSet, schemaType: wrappedObjectType))
                )))
            }
        }
    }

    return MemberBlockItemListSyntax(body)
}

public class Context {
    let schema: __Schema
    let document: DocumentNode
    
    init(schema: __Schema, document: DocumentNode) {
        self.schema = schema
        self.document = document
    }
}

private func generateEnumDecls(ctx: Context) -> [EnumDeclSyntax] {
    var enums: [EnumDeclSyntax] = []
    for tp in ctx.schema.types {
        if tp.kind != .ENUM { continue }
        enums.append(EnumDeclSyntax(modifiers: [DeclModifierSyntax(name: .keyword(.public))], name: TokenSyntax.identifier(tp.name!)) {
            for enumValue in tp.enumValues! {
                EnumCaseDeclSyntax(
                    leadingTrivia: enumValue.description.map { "/// \($0)\n" },
                    elements: [EnumCaseElementSyntax(name: TokenSyntax.identifier(enumValue.name))]
                )
            }
        })
    }
    return enums
}

public func generate(schema: __Schema, query: String) async throws -> String {
    let parser = try await GraphQLParser()
    let documentNode = try await parser.parse(source: query)
    return try await generate(schema: schema, query: documentNode)
}


public func generate(schema: __Schema, query: DocumentNode) async throws -> String {
    let ctx = Context(schema: schema, document: query)
    let operations = query.definitions
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
    let operation = operations[0]
    let structName = operation.name!.value + "Response"

    // TODO: Support query pamater
    // TODO: Support codable

    let queryType = try getQueryType(schema: schema)
    
    let enumDecls = generateEnumDecls(ctx: ctx)
    
    let source = try SourceFileSyntax {
        for enumDecl in enumDecls { enumDecl }
        StructDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: TokenSyntax.identifier(structName),
            memberBlock: MemberBlockSyntax(members: try generateStructBody(ctx: ctx, selectionSet: operation.selectionSet, schemaType: queryType))
        )
    }
    return source.formatted().description
}
