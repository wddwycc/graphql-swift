//

import SwiftSyntax
import GraphQLParser

// TODO: Handle all Swift keywords
func safeFieldName(_ fieldName: String) -> String {
    if fieldName == "in" {
        return "`\(fieldName)`"
    }
    return fieldName
}

func getQueryType(schema: __Schema) throws -> __Type {
    guard let queryTypeName = schema.queryType.name else {
        throw CodegenErrors.missingQueryTypeName
    }
    guard let queryType = schema.types.first(where: { $0.name == queryTypeName }) else {
        throw CodegenErrors.missingQueryType
    }
    return queryType
}

func convertSchemaTypeToSwiftType(ctx: Context, type: __Type, nonNull: Bool = false) throws -> TypeSyntaxProtocol {
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
        guard let name = type.name else { throw CodegenErrors.invalidType("Expect name for OBJECT type") }
        tp = IdentifierTypeSyntax(name: TokenSyntax.identifier(name))
    case .LIST:
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for LIST type") }
        tp = ArrayTypeSyntax(element: try convertSchemaTypeToSwiftType(ctx: ctx, type: ofType))
    case .NON_NULL:
        if nonNull { throw CodegenErrors.invalidType("NON_NULL type cannot be nested") }
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for NON_NULL type") }
        return try convertSchemaTypeToSwiftType(ctx: ctx, type: ofType, nonNull: true)
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

private func getFields(ctx: Context, selectionSet: SelectionSetNode, schemaType: __Type) throws -> [(FieldNode, __Field)] {
    try selectionSet.selections.flatMap {
        switch $0 {
        case .field(let field):
            // NOTE: __schema doesn't exist in schema fields, but still queriable
            if field.name.value == "__schema" {
                let fieldInSchema = __Field(
                    name: "__schema", description: nil, args: [],
                    type: ctx.schema.types.first(where: { $0.name == "__Schema" })!, isDeprecated: false, deprecationReason: nil
                )
                return [(field, fieldInSchema)]
            }
            guard let fieldInSchema = schemaType.fields?.first(where: { $0.name == field.name.value }) else {
                throw CodegenErrors.missingField(field.name.value)
            }
            return [(field, fieldInSchema)]
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

func generateStructBody(ctx: Context, schemaType: __Type, selectionSet: SelectionSetNode) throws -> MemberBlockItemListSyntax {
    let fields = try getFields(ctx: ctx, selectionSet: selectionSet, schemaType: schemaType)

    var declaredProperties = Set<String>()
    var declaredStructs = Set<String>()
    var body: [MemberBlockItemSyntax] = []
    for (field, fieldInSchema) in fields {
        let swiftType = try convertSchemaTypeToSwiftType(ctx: ctx, type: fieldInSchema.type)
        if (!declaredProperties.contains(field.name.value)) {
            declaredProperties.insert(field.name.value)
            body.append(MemberBlockItemSyntax(
                leadingTrivia: fieldInSchema.description.map(generateCodeComment(description:)),
                decl: DeclSyntax("public let \(raw: field.name.value): \(swiftType)")
            ))
        }
        if let nestedSelectionSet = field.selectionSet {
            let wrappedObjectType = try getWrappedObjectType(ctx: ctx, type: fieldInSchema.type)
            if (!declaredStructs.contains(wrappedObjectType.name!)) {
                declaredStructs.insert(wrappedObjectType.name!)
                body.append(MemberBlockItemSyntax(decl: StructDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                    name: TokenSyntax.identifier(wrappedObjectType.name!),
                    inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: [
                        .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("Codable"))),
                    ]),
                    memberBlock: MemberBlockSyntax(members: try generateStructBody(ctx: ctx, schemaType: wrappedObjectType, selectionSet: nestedSelectionSet))
                )))
            }
        }
    }

    return MemberBlockItemListSyntax(body)
}

func generateCodeComment(description: String) -> Trivia {
    let content: [TriviaPiece] = description
        .split(separator: "\n", omittingEmptySubsequences: false)
        .flatMap { a -> [TriviaPiece] in
            if (a.isEmpty) {
                return [.newlines(1)]
            }
            return [.docLineComment("\(a)"), .newlines(1)]
        }
    let pieces: [TriviaPiece] = 
        [.docBlockComment("/**"), .newlines(1)] 
        +
        content 
        +
        [.docBlockComment("*/"), .newlines(1)]
    return Trivia(pieces: pieces)
}
